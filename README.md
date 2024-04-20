# Wesleyan Media Project - Entity Linking 2022

Welcome! This repo contains scripts for identifying and linking election candidates and other political entities in political ads on Google and Facebook. The scripts provided here are intended to help journalists, academic researchers, and others interested in the democratic process to understand which political entities are connected and how.

This repo is a part of the [Cross-platform Election Advertising Transparency Initiative (CREATIVE)](https://www.creativewmp.com/). CREATIVE has the goal of providing the public with analysis tools for more transparency of political ads across online platforms. In particular, CREATIVE provides cross-platform integration and standardization of political ads collected from Google and Facebook. CREATIVE is a joint project of the [Wesleyan Media Project (WMP)](https://mediaproject.wesleyan.edu/) and the [privacy-tech-lab](https://privacytechlab.org/) at Wesleyan University.

To tackle the different dimensions of political ad transparency we have developed an analysis pipeline. The scripts in this repo are part of the Data Classification Step in our pipeline.

![A picture of the repo pipeline with this repo highlighted](Creative_Pipelines.png)

## Table of Contents

[1. Video Tutorial](#1-video-tutorial)  
[2. Overview](#2-overview)  
[3. Data](#3-data)  
[4. Setup](#4-setup)
[5. Thank You!](#5-thank-you)

## 1. Video Tutorial

<https://github.com/Wesleyan-Media-Project/entity_linking_2022/assets/104949958/f7a8a98d-e779-4b77-827d-2d84f02530be>

## 2. Overview

This repo contains an entity linker for 2022 election data. The entity linker is a machine learning classifier and was trained on data that contains descriptions of people and their names, along with their aliases. Data are sourced from the 2022 WMP [person_2022.csv](https://github.com/Wesleyan-Media-Project/datasets/blob/main/people/person_2022.csv) and [wmpcand_120223_wmpid.csv](https://github.com/Wesleyan-Media-Project/datasets/blob/main/candidates/wmpcand_120223_wmpid.csv) --- two comprehensive files with names of candidates and other people in the political process. Data are restricted to general election candidates and other non-candidate people of interest (sitting senators, cabinet members, international leaders, etc.).

The repo provides reusable code for the following three tasks:

1. Construct Knowledge Base of Political Entities

   The first task is to construct a knowledge base of political entities (people) of interest.

   The knowledge base of people of interest is constructed in `facebook/train/01_construct_kb.R`. The input to the file is the data sourced from the 2022 WMP persons file [person_2022.csv](https://github.com/Wesleyan-Media-Project/datasets/blob/main/people/person_2022.csv). The script constructs one sentence for each person with a basic description. Districts and party are sourced from the 2022 WMP candidates file [wmpcand_120223_wmpid.csv](https://github.com/Wesleyan-Media-Project/datasets/blob/main/candidates/wmpcand_120223_wmpid.csv), a comprehensive file with names of candidates.

   The knowledge base has four columns that include entities' "id", "name", "description" and "aliases". Examples of aliases include Joseph R. Biden being referred to as Joe or Robert Francis O’Rourke generally being known as Beto O’Rourke. Here is an example of one row in the knowledge base:

   | id        | name      | descr                                                                    | aliases                                                             |
   | --------- | --------- | ------------------------------------------------------------------------ | ------------------------------------------------------------------- |
   | WMPID1770 | Adam Gray | Adam Gray is a Democratic candidate for the 13rd District of California. | Adam Gray,Gray,Adam Gray's,Gray's,ADAM GRAY,GRAY,ADAM GRAY'S,GRAY'S |

2. Train Entity Linking Model

   The second task is to train an entity linking model using the knowledge base. Once the knowledge base of people of interest is constructed, the entity linker can be initialized with [spaCy](https://spacy.io/), a natural language processing library we use, in `facebook/train/02_train_entity_linking.py`.

3. Apply the Trained Model

   The third task is to apply the trained model to automatically identify and link entities mentioned in new political ad text. We have included some additional modifications to address disambiguating people, for example, multiple "Harrises."

   While this repo applies the trained entity linker to the 2022 US elections ads, you can also apply our entity linker to analyze your own political ad text datasets to identify which people of interest are mentioned in ads. This entity linker is especially helpful if you have a large amount of ad text data and you do not want to waste time counting how many times a political figure is mentioned within these ads. You can follow the setup instructions below to apply the entity linker to your own data.

## 3. Data

When you run the entity linker, the entity linking results are stored in the `data` folder. The data will be in `csv.gz` and `csv` format. Here is an example of the entity linking results `entity_linking_results_fb22.csv.gz`:

| text                                                  | text_detected_entities | text_start | text_end | ad_id  | field            |
| ----------------------------------------------------- | ---------------------- | ---------- | -------- | ------ | ---------------- |
| Senator John Smith is fighting hard for Californians. | WMPID1234              | [8]        | [18]     | x_1234 | ad_creative_body |

In this example,

- The `text` column contains the raw ad text where entities were detected.
- The `text_detected_entities` column contains the detected entities in the ad text. They are listed by their WMPID. WMPID is the unique id that Wesleyan Media Project assigns to each candidate in the knowledge base(e.g. Adam Gray: WMPID1770). The WMPID is used to link the detected entities to the knowledge base.
- `text_start` and `text_end` indicate the character offsets where the entity mention appears in the text.
- The `ad_id` column contains the unique identifier for the ad.
- The `field` column contains the field in the ad where the entity was detected. This could be, for example, the `page_name`, `ad_creative_body`, or `google_asr_text`(texts that we extract from video ads through Google Automatic Speech Recognition).

## 4. Setup

The following setup instructions are for macOS/Linux. For Windows the steps are the same but the commands may be different.

1. First, clone this repo to your local directory:

   ```bash
   git clone https://github.com/Wesleyan-Media-Project/entity_linking_2022.git
   ```

2. The scripts in this repo are in [Python](https://www.python.org/) and [R](https://www.r-project.org/). Make sure you have installed both before continuing. To install and set up R, you can follow the [CRAN website](https://cran.r-project.org/).

3. To run the scripts in Python, we recommend that you install a Python virtual environment:

   ```bash
   python3 -m venv venv
   ```

4. Start your Python virtual environment:

   ```bash
   source venv/bin/activate
   ```

   You can stop your virtual environment with:

   ```bash
   deactivate
   ```

5. Run the scripts in this repo according to their numbering. For example, if you want to run the inference pipeline folder, you can run the script follow the order of `facebook/inference/01_combine_text_asr_ocr.R`, `facebook/inference/02_entity_linking_inference.py`, `facebook/inference/03_combine_results.R`. Or use the following command in your terminal:

   For Mac/Linux/Windows Command Prompt (cmd.exe):

   ```bash
   Rscript facebook/inference/01_combine_text_asr_ocr.R
   &&
   python facebook/inference/02_entity_linking_inference.py
   &&
   Rscript facebook/inference/03_combine_results.R
   ```

   For Windows PowerShell:

   ```bash
   Rscript facebook/inference/01_combine_text_asr_ocr.R;
   if ($?) { python facebook/inference/02_entity_linking_inference.py };
   if ($?) { Rscript facebook/inference/03_combine_results.R }
   ```

   After successfully running the above scripts in the inference folder, you should be able to see the following entity linking results in the `data` folder:

   - `entity_linking_results_fb22.csv.gz`
   - `entity_linking_results_fb22_notext.csv.gz`
   - `detected_entities_fb22.csv.gz`
   - `detected_entities_fb22_for_ad_tone.csv.gz`

**Note**: The scripts in this repo are numbered in the order in which they should be run. Scripts that directly depend on one another are ordered sequentially. Scripts with the same number are alternatives, usually they are the same scripts on different data or with minor variations. For example, `02_train_entity_linking.py` and `02_untrained_model.py` are both scripts for training an entity linking model. But they differ slightly as to their training datasets. The outputs of each script are saved. Thus, it is possible to only run the inference script, since the model files are already present.

There are separate folders for running the entity linker on Facebook and Google data. For Facebook and Google, the scripts need to be run in the order of (1) knowledge base, (2) training, and (3) inference.

The knowledge base construction is optional for the script in the repo to work since the knowledge base construction result `entity_kb.csv`is stored in `/data` folder. If you want to run the [knowledge base creation script](https://github.com/Wesleyan-Media-Project/entity_linking_2022/tree/main/facebook/knowledge_base) from this repo, you will also need the scripts from the [datasets](https://github.com/Wesleyan-Media-Project/datasets) and [data-post-production](https://github.com/Wesleyan-Media-Project/data-post-production) repos.

The entity linking model training scripts in this repo require datasets from the [datasets](https://github.com/Wesleyan-Media-Project/datasets) repo (which contains datasets that are not created in any of the other CREATIVE repos and intended to be used in more than one repo) and tables from the [data-post-production](https://github.com/Wesleyan-Media-Project/data-post-production) repo.

Any depending repos are assumed to be cloned into the same top-level folder as this repo. For detailed setup instructions for additional repos, please refer to the readmes of the respective repos.

Some scripts operate in a Python 3 environment and need the following packages: `spacy` version 3.2.4 and `en_core_web_lg` from `spacy`. The scripts in this repo were tested on Python 3.10. For better package version control, we recommend creating a Python virtual environment by using Anaconda to run the scripts in this repo. To install the
`en_core_web_lg` package, you can run the following command in the terminal; The command below works for both macOS/Linux and Windows:

```bash
pip install spacy==3.2.4
python -m spacy download en_core_web_lg
```

## 5. Thank You

<p align="center"><strong>We would like to thank our financial supporters!</strong></p><br>

<p align="center">This material is based upon work supported by the National Science Foundation under Grant Numbers 2235006, 2235007, and 2235008.</p>

<p align="center">
  <a href="https://www.nsf.gov/awardsearch/showAward?AWD_ID=2235006">
    <img class="img-fluid" src="nsf.png" height="100px" alt="National Science Foundation Logo">
  </a>
</p>

<p align="center">The Cross-Platform Election Advertising Transparency Initiative (CREATIVE) is a joint infrastructure project of the Wesleyan Media Project and Privacy Tech Lab at Wesleyan University in Connecticut.

<div align="center" style="display: flex; justify-content: center; align-items: center;">
  <a href="https://privacytechlab.org/" style="margin-right: 20px;">
    <img src="./plt_logo.png" width="200px" height="200px" alt="privacy-tech-lab logo">
  </a>
  <a href="https://mediaproject.wesleyan.edu/">
    <img src="wmp-logo.png" width="218px" height="100px" alt="Wesleyan Media Project logo">
  </a>
</div>
<p align="center">
  <a href="https://www.creativewmp.com/">
    <img class="img-fluid" src="CREATIVE_logo.png" height="90px" alt="CREATIVE Logo">
  </a>
</p>
