library(data.table)
library(dplyr)
library(tidyr)

# The working directory below assumes that you are running scripts
# from the entity_linking_2022 directory. If you are running from
# anywhere else, it may need to be adjusted.

setwd("./")

# NOTE: The paths below are written with the assumption that you are running
# from the entity_linking_2022 directory. If you are running from elsewhere,
# they may need to be adjusted.

# Input files
# This is an output from data-post-production/01-merge-results/01_merge_preprocessed_results
# Select fields of 'ad_id', 'page_name', 'disclaimer', 'ad_creative_body',
#        'ad_creative_link_caption', 'ad_creative_link_title',
#        'ad_creative_link_description', 'aws_ocr_text_img',
#        'google_asr_text', 'aws_ocr_text_vid'
#############################################################################################
# GET FIGSHARE LINK
# Make sure you place the file in the same directory as entity_linking_2022
path_ads <- "../fb_2022_adid_text.csv.gz"

# This is the output table from `data-post-production/01-merge-results/01_merge_preprocessed_results`
# GET FIGSHARE LINK
# Make sure you place the file in the same directory as entity_linking_2022
path_adid_to_pageid <- "../fb_2022_adid_var1.csv.gz"

path_entities_kb <- "facebook/data/entity_kb.csv"

# This file is located in our datasets repository (https://github.com/Wesleyan-Media-Project/datasets)
# Make sure the datasets folder is located in the same directory as entity_linking_2022
path_wmpent_file <- "../datasets/wmp_entity_files/Facebook/wmp_fb_2022_entities_v082324.csv" # nolint: line_length_linter.
# Output files
path_output <- "facebook/data/ads_with_aliases.csv.gz"

# Pdid to wmpid
wmpents <- fread(path_wmpent_file) %>%
  select(pd_id, wmpid)
wmpents <- wmpents[wmpents$wmpid != "", ]

# Ads
df <- fread(path_ads, encoding = "UTF-8")

cols <- c(
  "ad_id", "page_name", "disclaimer", "ad_creative_body", "ad_creative_link_caption", "ad_creative_link_title",
  "ad_creative_link_description", "aws_ocr_text_img", "google_asr_text", "aws_ocr_text_vid"
) # nolint
# Select only the specified columns
df <- df[, ..cols]

# Adid to pdid
adid_to_pageid <-
  fread(path_adid_to_pageid, colClasses = "character") %>%
  select(ad_id, pd_id)

# Combine
df <- inner_join(df, adid_to_pageid, by = "ad_id")
df <- left_join(df, wmpents, by = "pd_id")

# Aliases, then merge in pd_id
aliases <- fread(path_entities_kb, encoding = "UTF-8", data.table = F)
aliases <- select(aliases, c(id, aliases))

# Keep only ads that have a wmpid
# Shape to long format
# Remove empty rows
# Keep only distinct rows based on pd_id and value
df <- df %>%
  filter(wmpid != "") %>%
  pivot_longer(-c(ad_id, pd_id, wmpid)) %>%
  filter(value != "") %>%
  distinct_at(vars(pd_id, value), .keep_all = T)

# Merge in aliases
df <- left_join(df, aliases, by = c("wmpid" = "id"))

# Get rid of ads that have no aliases
df <- df[is.na(df$aliases) == F, ]

fwrite(df, path_output)
