# Wesleyan Media Project - Entity Linking 2022

Welcome! This repo contains scripts for identifying and linking election candidates and other political entities in political ads on Google and Facebook. The scripts provided here are intended to help journalists, academic researchers, and others interested in the democratic process to understand which political entities are connected and how.

This repo is a part of the [Cross-platform Election Advertising Transparency Initiative (CREATIVE)](https://www.creativewmp.com/). CREATIVE is an academic research project that has the goal of providing the public with analysis tools for more transparency of political ads across online platforms. In particular, CREATIVE provides cross-platform integration and standardization of political ads collected from Google and Facebook. CREATIVE is a joint project of the [Wesleyan Media Project (WMP)](https://mediaproject.wesleyan.edu/) and the [privacy-tech-lab](https://privacytechlab.org/) at [Wesleyan University](https://www.wesleyan.edu).

To analyze the different dimensions of political ad transparency we have developed an analysis pipeline. The scripts in this repo are part of the Data Classification Step in our pipeline.

![A picture of the repo pipeline with this repo highlighted](Creative_Pipelines.png)

## Table of Contents

[1. Video Tutorial](#1-video-tutorial)  
[2. Overview](#2-overview)  
[3. Setup](#3-setup)  
[4. Results Storage](#4-results-storage)  
[5. Results Analysis](#5-results-analysis)  
[6. Thank You](#6-thank-you)

## 1. Video Tutorial

<video src="https://github.com/Wesleyan-Media-Project/entity_linking_2022/assets/104949958/2a7f456f-d2d9-439f-8e64-f9abb589069e" alt="If you are unable to see the video on Firefox with the error: No video with supported format and MIME type found, please try it on Chrome.">
</video>

If you are unable to see the video above (e.g., you are getting the error "No video with supported format and MIME type found"), try a different browser. The video works on Google Chrome.

Or, you can also watch this tutorial through [YouTube](https://youtu.be/-C29ZL3snxM).

## 2. Overview

This repo contains an entity linker for 2022 election data. The entity linker is a machine learning classifier and was trained on data that contains descriptions of people and their names, along with their aliases. Data are sourced from the 2022 WMP [person_2022.csv](https://github.com/Wesleyan-Media-Project/datasets/blob/main/people/person_2022.csv) and [wmpcand_120223_wmpid.csv](https://github.com/Wesleyan-Media-Project/datasets/blob/main/candidates/wmpcand_120223_wmpid.csv) --- two comprehensive files with names of candidates and other people in the political process. Data are restricted to general election candidates and other non-candidate people of interest (sitting senators, cabinet members, international leaders, etc.).

While this repo applies the trained entity linker to the 2022 US elections ads, you can also apply our entity linker to analyze your own political ad text datasets to identify which people of interest are mentioned in ads. The entity linker is especially useful if you have a large amount of ad text data and you do not want to waste time counting how many times a political figure is mentioned within these ads. You can follow the setup instructions below to apply the entity linker to your own data.

There are separate folders for running the entity linker depending on whether you want to run it on Facebook or Google data. For both Facebook and Google, the scripts need to be run in the order of three tasks: (1) constructing a knowledge base of political entities, (2) training the entity linking model, and (3) making inferences with the trained model. The repo provides reusable code for these three tasks. For your overview, we describe the three tasks in the following. Note that we provide a knowledge base and pre-trained models that are ready for your use on Google and Facebook 2022 data. For this data you can start right away making inferences and skip steps 1 and 2. However, if you want to apply our inference scripts to a different time period (for example, another election cycle) or in a different context (for example, a non-U.S. election), then you would need to create your own knowledge base and train your own models.

1. **Constructing a Knowledge Base of Political Entities**

   The first task is to construct a knowledge base of political entities (people) of interest.

   The knowledge base of people of interest is constructed from [facebook/knowledge_base/01_construct_kb.R](https://github.com/Wesleyan-Media-Project/entity_linking_2022/blob/main/facebook/knowledge_base/01_construct_kb.R). The input to the file is the data sourced from the 2022 WMP persons file [person_2022.csv](https://github.com/Wesleyan-Media-Project/datasets/blob/main/people/person_2022.csv). The script constructs one sentence for each person with a basic description. Districts and party are sourced from the 2022 WMP candidates file [wmpcand_120223_wmpid.csv](https://github.com/Wesleyan-Media-Project/datasets/blob/main/candidates/wmpcand_120223_wmpid.csv), a comprehensive file with names of candidates.

   The knowledge base has four columns that include entities' `id`, `name`, `descr` (for description), and `aliases`. Examples of aliases include Joseph R. Biden being referred to as Joe or Robert Francis O’Rourke generally being known as Beto O’Rourke. Here is an example of one row in the knowledge base:

   | id        | name      | descr                                                                    | aliases                                                             |
   | --------- | --------- | ------------------------------------------------------------------------ | ------------------------------------------------------------------- |
   | WMPID1770 | Adam Gray | Adam Gray is a Democratic candidate for the 13rd District of California. | Adam Gray,Gray,Adam Gray's,Gray's,ADAM GRAY,GRAY,ADAM GRAY'S,GRAY'S |

   **Note**: The knowledge base construction is optional for running the scripts in this repo. You can run the inference scripts with our [existing knowledge base (for both Google and Facebook)](https://github.com/Wesleyan-Media-Project/entity_linking_2022/blob/main/facebook/data/entity_kb.csv). If you want to construct your own knowledge base, you would need to run the [knowledge base creation scripts](https://github.com/Wesleyan-Media-Project/entity_linking_2022/tree/main/facebook/knowledge_base). You would also need the scripts from the [datasets](https://github.com/Wesleyan-Media-Project/datasets) and [data-post-production](https://github.com/Wesleyan-Media-Project/data-post-production) repos. See those repos for further instructions.

2. **Training the Entity Linking Model**

   The second task is to train an entity linking model using the knowledge base.

   Once the knowledge base of people of interest is constructed, the entity linker can be initialized with [spaCy](https://spacy.io/), a natural language processing library we use, in [facebook/train/02_train_entity_linking.py](https://github.com/Wesleyan-Media-Project/entity_linking_2022/blob/main/facebook/train/02_train_entity_linking.py).

   **Note**: The training of the entity linking models is optional for running the scripts in this repo. You can run the inference scripts with our pre-trained model by downloading it [here](https://figshare.wesleyan.edu/articles/model/Trained_Entity_Linker_Model/25773600/2)) or by using our bash script that automatically downloads it. To use this script, make sure that you are in the entity_linking_2022 directory as your working directory and run the following commands in terminal:
   ```bash
   chmod +x download_files.sh
   ./download_files.sh
   ```
  
    Once you have done this, the pre-trained model will download. This will take some time, as it takes up 1.44 GB. Once it has finished downloading, run the following command in terminal to unzip the model.
    ```bash
    unzip trained_entity_linker.zip
    ```
   
   If you want to train your own models, you can follow the same instructions for the [inference set up](#3-setup) to set up your Python virtual environment and R working directory. After that, run the training scripts in this repo according to their numbering. For example, if you want to run the training pipeline, you can run the scripts in the following order:

   1. [facebook/train/01_create_EL_training_data.R](https://github.com/Wesleyan-Media-Project/entity_linking_2022/blob/main/facebook/train/01_create_EL_training_data.R)
   2. [facebook/train/02_train_entity_linking.py](https://github.com/Wesleyan-Media-Project/entity_linking_2022/blob/main/facebook/train/02_train_entity_linking.py)

   To do so, run the following commands in your terminal:

   ```bash
   Rscript facebook/train/01_create_EL_training_data.R
   python3 facebook/train/02_train_entity_linking.py
   ```

   After successfully running the above scripts in the training folder, you should see the following trained model in the `models` folder:

   - `intermediate_kb`
   - `trained_entity_linker`

3. **Making Inferences with the Trained Model**

   The third task is to make inferences with the trained model to automatically identify and link entities mentioned in new political ad text.

   To perform this task you can use the scripts in the inferences folders, [facebook/inference](https://github.com/Wesleyan-Media-Project/entity_linking_2022/tree/main/facebook/inference) and [google/inference](https://github.com/Wesleyan-Media-Project/entity_linking_2022/tree/main/google/inference). The folders incluced variations of scripts to disambiguate people, for example, multiple "Harrises" (e.g., Kamala Harris and Andy Harris).

## 3. Setup

The following setup instructions are for the default terminal on macOS/Linux. For Windows the steps are the same but the commands may be slightly different.

**Note**: The following instructions are for setting up the inference scripts only as we provide a [knowledge base](https://github.com/Wesleyan-Media-Project/entity_linking_2022/blob/main/facebook/data/entity_kb.csv) and [pre-trained models](https://figshare.wesleyan.edu/account/projects/185302/articles/25773600) that are ready for you to use on Google and Facebook 2022 data. To create your own knowledge base and train your own models, you can format your knowledge base according to our [existing knowledge base (for both Google and Facebook)](https://github.com/Wesleyan-Media-Project/entity_linking_2022/blob/main/facebook/data/entity_kb.csv). In such case, please note that the entity linking model training scripts require datasets from the [datasets](https://github.com/Wesleyan-Media-Project/datasets) repo and tables from the [data-post-production](https://github.com/Wesleyan-Media-Project/data-post-production) repo. These dependencies must be cloned into the same local top-level folder as this repo. The training may take multiple hours or even days, depending on your hardware.

1. To start setting up the inference scripts based on our existing knowledge base and pre-trained models, first clone this repo to your local directory:

   ```bash
   git clone https://github.com/Wesleyan-Media-Project/entity_linking_2022.git
   ```

2. The scripts in this repo are in [Python](https://www.python.org/) and [R](https://www.r-project.org/). Make sure you have both installed and set up before continuing. To install and set up Python you can follow the [Beginner's Guide to Python](https://wiki.python.org/moin/BeginnersGuide). The scripts in this repo were tested on Python 3.10. To install and set up R you can follow the [CRAN website](https://cran.r-project.org/). We also recommend using R Studio as an interface of R. Here is the [R Studio website](https://posit.co/download/rstudio-desktop/).

3. To run the Python scripts we recommend that you create a Python virtual environment. Create the virtual environment using python v3.10, as it supports the installation of spaCy v3.2.4, which some scripts in this repo require:

   ```bash
   python3.10 -m venv venv
   ```

4. Start your Python virtual environment:

   ```bash
   source venv/bin/activate
   ```

   You can stop your virtual environment with:

   ```bash
   deactivate
   ```

5. Some scripts in this repo require [spaCy](https://spacy.io/) v3.2.4, particularly, spaCy's `en_core_web_lg`. To install
   `en_core_web_lg`, run:

   ```bash
   pip install spacy==3.2.4
   python3 -m spacy download en_core_web_lg
   ```

- Note: We require this version of [spaCy](https://spacy.io/) because this repo used the [KnowledgeBase](https://spacy.io/api/kb) class in spacy.kb implemented up to spaCy v3.5. Since v3.5, the KnowledgeBase class became abstract ([reference here](https://spacy.io/api/kb)). If you install a later version of spaCy, in particular spaCy v3.5 and above, you will need to import the [InMemoryLookupKB](https://spacy.io/api/inmemorylookupkb) class instead. Relevant comments have been made in scripts.

6. Additionally, some scripts in this repository require pandas 2.1.1. To install it, run:

   ```bash
   pip install pandas==2.1.1
   ```

7. In order to successfully run each R script, you must first set your working directory. You can achieve this by adding the line `setwd("your/working/directory")` to the top of the R scripts, replacing `"your/working/directory"` with whatever directory you are running from. Additionally, make sure that the locations to which you are retrieving input files and/or sending output files are accurate.

8. (Jump to step 10 if you want to use the [pre-trained model](https://figshare.wesleyan.edu/account/projects/185302/articles/25773600) we provided.) Now, you can create the [knowledge base](https://github.com/Wesleyan-Media-Project/entity_linking_2022/blob/main/facebook/data/entity_kb.csv) by running the [R script](https://github.com/Wesleyan-Media-Project/entity_linking_2022/blob/main/facebook/knowledge_base/01_construct_kb.R) in the `facebook/knowledge_base` folder (See above for more details).

9. Next, you will train the entity linking model using spaCy library. The scripts are in the `facebook/train` [folder](https://github.com/Wesleyan-Media-Project/entity_linking_2022/tree/main/facebook/train) (See above for more details).

10. Finally, run the inferences scripts in this repo according to their numbering. For example, if you want to run the inference pipeline, you can run the scripts in the following order:

    1. [facebook/inference/01_combine_text_asr_ocr.R](https://github.com/Wesleyan-Media-Project/entity_linking_2022/blob/main/facebook/inference/01_combine_text_asr_ocr.R)
    2. [facebook/inference/02_entity_linking_inference.py](https://github.com/Wesleyan-Media-Project/entity_linking_2022/blob/main/facebook/inference/02_entity_linking_inference.py)
    3. [facebook/inference/03_combine_results.R](https://github.com/Wesleyan-Media-Project/entity_linking_2022/blob/main/facebook/inference/03_combine_results.R)

To do so, run the following commands in your terminal:

```bash
Rscript facebook/inference/01_combine_text_asr_ocr.R
python3 facebook/inference/02_entity_linking_inference.py
Rscript facebook/inference/03_combine_results.R
```

Note that only the Python script will run in the virtual environment that we initially created. However, all commands can be executed from the virtual environment command prompt.

After successfully running the above scripts in the inference folder, you should see the following entity linking results in the `data` folder:

- `entity_linking_results_fb22.csv.gz`
- `entity_linking_results_fb22_notext.csv.gz`
- `detected_entities_fb22.csv.gz`
- `detected_entities_fb22_for_ad_tone.csv.gz`

**Note**: The scripts in this repo are numbered in the order in which they should be run. Scripts that directly depend on one another are ordered sequentially. Scripts with the same number are alternatives. Usually, they are the same scripts on different data or with minor variations. For example, [facebook/train/02_train_entity_linking.py](https://github.com/Wesleyan-Media-Project/entity_linking_2022/blob/main/facebook/train/02_train_entity_linking.py) and [facebook/train/02_untrained_model.py](https://github.com/Wesleyan-Media-Project/entity_linking_2022/blob/main/facebook/train/02_untrained_model.py) are both scripts for training an entity linking model, but they differ slightly as to their training datasets.

## 4. Results Storage

When you run the inference scripts, the entity linking results are stored in the `data` folder. The data will be in `csv.gz` and `csv` format. Here is an example of the entity linking results [facebook/data/entity_linking_results_fb22.csv.gz](https://github.com/Wesleyan-Media-Project/entity_linking_2022/blob/main/facebook/data/entity_linking_results_fb22.csv.gz):

| text                                                  | text_detected_entities | text_start | text_end | ad_id  | field            |
| ----------------------------------------------------- | ---------------------- | ---------- | -------- | ------ | ---------------- |
| Senator John Smith is fighting hard for Californians. | WMPID1234              | [8]        | [18]     | x_1234 | ad_creative_body |

In this example,

- The `text` field contains the raw ad text where entities were detected.
- The `text_detected_entities` field contains the detected entities in the ad text. They are listed by their WMPID. WMPID is the unique id that Wesleyan Media Project assigns to each candidate in the knowledge base(e.g. Adam Gray: WMPID1770). The WMPID is used to link the detected entities to the knowledge base.
- The `text_start` and `text_end` fields indicate the character offsets where the entity mention appears in the text.
- The `ad_id` field contains the unique identifier for the ad.
- The `field` field contains the field in the ad where the entity was detected. This could be, for example, the `page_name`, `ad_creative_body`, or `google_asr_text` (texts that we extract from video ads through Google Automatic Speech Recognition).

## 5. Results Analysis

The `csv.gz` files produced in this repo are usually large and may contain millions of rows. To make it easier to read and analyze the data we have provided two scripts, [readcsv.py](https://github.com/Wesleyan-Media-Project/entity_linking_2022/blob/main/readcsv.py) and [readcsvGUI](https://github.com/Wesleyan-Media-Project/entity_linking_2022/blob/main/readcsvGUI.py), in the root folder of this repo.

### Script `readcsv.py`

The script `readcsv.py` is a Python script that reads and filters the `csv.gz` files and saves the filtered data in an Excel file. It has the following features:

- Load a specified number of rows from a CSV file.
- Skip a specified number of initial rows to read the data.
- Filter rows based on the presence of a specified text (case-insensitive).

#### Usage

To run the script, you need to first install the required packages:

```bash
pip install pandas
```

After installing the required packages, you can run the script with the command line arguments.

For example, to run the script with the default arguments (start from row 0, read 10000 rows, no text filter), you can enter the following command in your terminal:

```bash
python3 readcsv.py --file facebook/data/entity_linking_results_fb22.csv.gz
```

You can customize the behavior of the script by providing additional command-line arguments:

- `--file`: Path to the csv file (required).
- `--skiprows`: Number of rows to skip at the start of the file (default: 0).
- `--nrows`: Number of rows to read from the file (default: Read 10000 rows in the data).
- `--filter_text`: Text to filter the rows (case-insensitive). If empty, no filtering is applied (default: No filter).

For example, to filter rows containing the text "Biden", starting from row 0 and reading 100000 rows:

```bash
python3 readcsv.py --file facebook/data/entity_linking_results_fb22.csv.gz --nrows 100000 --filter_text Biden
```

To see a help message with the description of all available arguments, you can run the following command:

```bash
python3 readcsv.py --h
```

Please note that this script may take a while (>10 min) to run depending on the size of the data and the number of rows you requested. If you request the script to read more than 1048570 rows, the output would be saved in multiple Excel files due to the maximum number of rows Excel can handle.

### Script `readcsvGUI.py`

In addition to the `readcsv.py` script, we also provide a GUI version of the script that displays the data in a graphical user interface via [PandasGui](https://pypi.org/project/pandasgui/).

To run the `readcsvGUI.py` script, you need to first install the required packages:

```bash
pip install pandas pandasgui
```

If you are working on a non-Windows computer, you will need to go into the file `.../site-packages/pandasgui/constants.py`, which is located wherever the package pandasgui is installed in your computer and will likely be outside of the entity_linking_2022 repository file structure, and change the line of code

```bash
SHORTCUT_PATH = os.path.join(os.getenv('APPDATA'), 'Microsoft/Windows/Start Menu/Programs/PandasGUI.lnk')
```

to instead be

```bash
if sys.platform == 'win32':
    SHORTCUT_PATH = os.path.join(os.getenv('APPDATA'), 'Microsoft/Windows/Start Menu/Programs/PandasGUI.lnk')
else:
    SHORTCUT_PATH = NonePY_INTERPRETTER_PATH = os.path.join(os.path.dirname(sys.executable), 'python.exe')
```

After installing the required packages and potentially changing the SHORTCUT_PATH, you can run the script with the following command:

```bash
python3 readcsvGUI.py --file facebook/data/entity_linking_results_fb22.csv.gz
```

You can change the file to read by replacing the path `facebook/data/entity_linking_results_fb22.csv.gz` to other file paths.

Here is an example of the GUI interface:
![A picture of the PandasGui interface](PandasGUI_example.png)
For more information on how to use the GUI interface, please refer to the [PandasGui documentation](https://pypi.org/project/pandasgui/).

## 6. Thank You

<p align="center"><strong>We would like to thank our supporters!</strong></p><br>

<p align="center">This material is based upon work supported by the National Science Foundation under Grant Numbers 2235006, 2235007, and 2235008.</p>

<p align="center" style="display: flex; justify-content: center; align-items: center;">
  <a href="https://www.nsf.gov/awardsearch/showAward?AWD_ID=2235006">
    <img class="img-fluid" src="nsf.png" height="150px" alt="National Science Foundation Logo">
  </a>
</p>

<p align="center">The Cross-Platform Election Advertising Transparency Initiative (CREATIVE) is a joint infrastructure project of the Wesleyan Media Project and privacy-tech-lab at Wesleyan University in Connecticut.

<p align="center" style="display: flex; justify-content: center; align-items: center;">
  <a href="https://www.creativewmp.com/">
    <img class="img-fluid" src="CREATIVE_logo.png"  width="220px" alt="CREATIVE Logo">
  </a>
</p>

<p align="center" style="display: flex; justify-content: center; align-items: center;">
  <a href="https://mediaproject.wesleyan.edu/">
    <img src="wmp-logo.png" width="218px" height="100px" alt="Wesleyan Media Project logo">
  </a>
</p>

<p align="center" style="display: flex; justify-content: center; align-items: center;">
  <a href="https://privacytechlab.org/" style="margin-right: 20px;">
    <img src="./plt_logo.png" width="200px" alt="privacy-tech-lab logo">
  </a>
</p>
