# Wesleyan Media Project - Entity Linking 2022

Welcome! This repo contains scripts for identifying and linking election candidates and other political entities in political ads on Google and Facebook. The scripts provided here are intended to help journalists, academic researchers, and others interested in the democratic process to understand which political entities are connected and how. It is our goal to provide political ad transparency across online platforms.

This repo is a part of the [Cross-platform Election Advertising Transparency Initiative (CREATIVE)](https://www.creativewmp.com/). CREATIVE has the goal of providing the public with analysis tools for more transparency of political ads across online platforms. In particular, CREATIVE provides cross-platform integration and standardization of political ads collected from Google and Facebook. CREATIVE is a joint effort of the [Wesleyan Media Project (WMP)](https://mediaproject.wesleyan.edu/) and the [privacy-tech-lab](https://privacytechlab.org/) at Wesleyan University.

To tackle the different dimensions of political ad transparency we have developed an analysis pipeline. The scripts in this repo are part of the Data Classification Step in our pipeline.

![A picture of the repo pipeline with this repo highlighted](Creative_Pipelines.png)

## Table of Contents

[1. Introduction](#1-overview)  
[2. Data](#2-data)  
[3. Setup](#3-setup)

## 1. Overview

This repo contains an entity linker for 2022 election data. The entity linker is a machine learning classifier and was trained on data that contains descriptions of people and their names, along with their aliases. Data are sourced from the 2022 WMP persons file, a comprehensive file with names of candidates and others in the political process. Data are restricted to general election candidates and other non-candidate persons of interest (sitting senators, cabinet members, international leaders, etc.).

First, the knowledge base of persons of interest is constructed in `facebook/train/01_construct_kb.R`. The input to the file is the data sourced from the 2022 WMP persons file. The script constructs one sentence for each person with a basic description. Districts and party are sourced from the 2022 WMP candidates file, a comprehensive file with names of candidates.

Once the knowledge base of persons of interest is constructed, the entity linker can be initialized with spaCy in `facebook/train/02_train_entity_linking.py`.

Finally, the entity linker can be applied to the inference data. We have included some additional modifications to address disambiguating multiple "Harrises" and similar edge cases.

## 2. Data

When you run the entity linker, the entity linking results are stored in the `data` folder. The data will be in `csv.gz` and `csv` format.

## 3. Setup

The scripts are numbered in the order in which they should be run. Scripts that directly depend on one another are ordered sequentially. Scripts with the same number are alternatives, usually they are the same scripts on different data or with minor variations. The outputs of each script are saved, so it is possible to, for example, only run the inference script, since the model files are already present.

There are separate folders for running the entity linker on Facebook and Google data. For Facebook, the scripts need to be run in the order of (1) knowledge base, (2) training, and (3) inference.

If you want to run the [knowledge base creation script](https://github.com/Wesleyan-Media-Project/entity_linking_2022/tree/main/facebook/knowledge_base) from this repo, you will also need the scripts from the [datasets](https://github.com/Wesleyan-Media-Project/datasets) and [data-post-production](https://github.com/Wesleyan-Media-Project/data-post-production) repos.

Some scripts in this repo require datasets from the [datasets](https://github.com/Wesleyan-Media-Project/datasets) repo (which contains datasets that are not created in any of the other CREATIVE repos and intended to be used in more than one repo) and tables from the [data-post-production](https://github.com/Wesleyan-Media-Project/data-post-production) repo.

Any depending repos are assumed to be cloned into the same top-level folder as this repo. For detailed setup instructions for additional repos, please refer to the readmes of the respective repos.

Some scripts operate in a Python environment and need the following packages: `spacy` version 3.2.4 and `en_core_web_lg` from `spacy`. The scripts in this repo were tested on Python 3.10. We recommend creating a Python virtual environment by using Anaconda to run the scripts in this repo.

`en_core_web_lg` requires manual installation, which can be done by running the following command in the terminal:
`python -m spacy download en_core_web_lg`
