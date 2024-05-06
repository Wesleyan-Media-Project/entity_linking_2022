import csv
from pathlib import Path
import os
import random
import json
import pandas as pd
import spacy
nlp = spacy.load("en_core_web_lg")
from spacy.kb import KnowledgeBase #vscode pylinter complains, actually loads fine
from spacy.util import minibatch, compounding
from tqdm import tqdm
import numpy as np
from spacy.training import Example
from spacy.ml.models import load_kb

# Input files
path_candidates = "../data/entity_kb.csv"
path_training_samples = "../data/ads_with_aliases.csv.gz"
# Output files
path_intermediate_kb = "../models/intermediate_kb"
path_output_nlp = "../models/trained_entity_linker"
path_output_kb = "../models/trained_entity_linker"
path_output_kb_vocab = "../models/trained_entity_linker"


#----
# Load the dataset on the candidates
# This contains their id, their name, a description, and aliases for their name

def load_entities():
    entities_loc = Path(path_candidates)

    names = dict()
    descriptions = dict()
    aliases = dict()
    with entities_loc.open("r", encoding="utf8") as csvfile:
        csvreader = csv.reader(csvfile, delimiter=",")
        next(csvreader) # Skip header row
        for row in csvreader:
            qid = row[0]
            name = row[1]
            desc = row[2]
            alias = row[3]
            names[qid] = name
            descriptions[qid] = desc
            aliases[qid] = alias
    return names, descriptions, aliases

# Create 3 dictionaries:
# name_dict - ID -> name
# desc_dict - ID -> description
# aliases_dict - ID -> aliases
name_dict, desc_dict, aliases_dict = load_entities()

# Example content for Biden:
print(f"{'WMPID1289'}, name={name_dict['WMPID1289']}, \
    desc={desc_dict['WMPID1289']}, alias={aliases_dict['WMPID1289']}")

#----
# Create a knowledge base
# So far, information on these people sits in a set of dictionaries
# Now we create a spacy knowledge base and populate it with the data above

# Instantiate a knowledge base with 300-dimensional entity embedding
kb = KnowledgeBase(vocab=nlp.vocab, entity_vector_length=300)

# Populate the knowledge base from the csv file
# Starting with the id and description
for qid, desc in desc_dict.items():
    desc_doc = nlp(desc)
    desc_enc = desc_doc.vector
    kb.add_entity(entity=qid, entity_vector=desc_enc, freq=342) # 342 is an arbitrary value

# Create a dictionary, with each unique alias as a key
# and the value being the fecids of all the people with that alias as a list
alias_to_fecids = dict()
for qid, alias in aliases_dict.items():
    for alias_specific in alias.split("|"):
        alias_to_fecids[alias_specific] = alias_to_fecids.get(alias_specific, []) + [qid]

# Now, start adding aliases to the kb
# The probabiltiy is 1/number of people with that alias
for alias, fecids in alias_to_fecids.items():
    kb.add_alias(alias=alias, entities=fecids, probabilities=[1/len(fecids) for fecid in fecids])

# Create a list of entity ids (i.e. fec ids in our case) that is looped over later
qids = name_dict.keys()
kb.to_disk(path_intermediate_kb)


#----
df = pd.read_csv(path_training_samples, encoding = 'UTF-8')
aliases = list(df['aliases'].str.split("|"))

# Apply NER to all training samples
TRAIN_DOCS = []
for text in tqdm(df['value']):
    doc = nlp(text)
    TRAIN_DOCS.append(doc)

# Put the character indices in the data frame
df['entity_start'] = np.nan
df['entity_end'] = np.nan
# Loop over the documents
# and record the indices from the NER results in the df
for d in range(len(TRAIN_DOCS)):
    for entity in TRAIN_DOCS[d].ents:
        if str(entity) in aliases[d]:
            print([entity, entity.start_char, entity.end_char])
            df.at[d, 'entity_start'] = entity.start_char
            df.at[d, 'entity_end'] = entity.end_char
            break


# Get the indices of the rows of the data frame where an entity match was detected
detected_entities_indices = np.where(df['entity_start'].isnull().to_numpy()==False)[0]
detected_entities_indices = list(detected_entities_indices)

# Make a new TRAIN_DOCS list with only those
TRAIN_DOCS2 = [TRAIN_DOCS[i] for i in detected_entities_indices]
print("Training on", len(TRAIN_DOCS2), "samples.") #currently about 14k (out of 60k)

# Create the annotations like this
# {'links': {(39, 48): {'H8MO01143': 1.0}}}
starts = [int(df['entity_start'][i]) for i in detected_entities_indices]
ends = [int(df['entity_end'][i]) for i in detected_entities_indices]
fecs = [df['wmpid'][i] for i in detected_entities_indices]
# print(starts, ends, fecs)

annotations = []
for i in range(len(starts)):
    annotations.append({'links': {(starts[i], ends[i]): {fecs[i]: 1.0}}, 'entities': [(starts[i], ends[i], 'PERSON')]})

# Make another version of TRAIN_DOCS, this time making it the correct tuple again,
#  with annotations as the second element
TRAIN_DOCS3 = []
for i in range(len(starts)):
    TRAIN_DOCS3.append((TRAIN_DOCS2[i], annotations[i]))

# Create gold-standard sentences
if "sentencizer" not in nlp.pipe_names:
    nlp.add_pipe("sentencizer")
sentencizer = nlp.get_pipe("sentencizer")
TRAIN_EXAMPLES = []
for i in range(len(starts)):
    example = Example.from_dict(nlp.make_doc(str(TRAIN_DOCS3[i][0])), annotations[i])
    example.reference = sentencizer(example.reference)
    TRAIN_EXAMPLES.append(example)

# Initialize the entity linker component
entity_linker = nlp.add_pipe("entity_linker", config={"incl_prior": False}, last=True)
entity_linker.initialize(get_examples=lambda: TRAIN_EXAMPLES, kb_loader=load_kb(path_intermediate_kb))

# At this point, the untrained component already works
test_doc = nlp("Donald Trump is a former president.")
for ent in test_doc.ents:
    if ent.kb_id_ != 'NIL':
        print(ent.kb_id_)


# Training loop
loss_list = []
with nlp.select_pipes(enable=["entity_linker"]):   # train only the entity_linker
    optimizer = nlp.resume_training() # This used to be begin_training, in spacy3 it seems it's resume because the component has already been initialized
    optimizer.learn_rate = 0.001
    for itn in range(500):   # one itn is one full pass over TRAIN_EXAMPLES
        random.shuffle(TRAIN_EXAMPLES)
        batches = minibatch(TRAIN_EXAMPLES, size=128)#size=compounding(4.0, 32.0, 1.001))  # increasing batch sizes -- seems to train WAY faster with a larger batch size (i.e. 128 rather than 32)
        losses = {} #at the end of the epoch, this will contain the cumulative loss of all of its batches (and as far as I can tell, the loss for one batch is the mean loss of all the samples in it)
        for batch in batches:
            nlp.update(
                batch,   
                drop=0.2,      # prevent overfitting
                losses=losses,
                sgd=optimizer,
            )
        #if itn % 50 == 0:
        print(itn, "Losses", losses)   # print the training loss
        loss_list.append(losses['entity_linker'])

print(itn, "Losses", losses)

# Save the nlp object to file
nlp.to_disk(path_output_nlp)
kb.to_disk(path_output_kb)
kb.vocab.to_disk(path_output_kb_vocab)
