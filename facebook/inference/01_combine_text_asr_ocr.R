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
# This is an output from data-post-production/01-merge-results/01_merge_preprocessed_results.
# After downloading this file from figshare (https://figshare.wesleyan.edu/account/articles/26124295),
# you should move it into the same directory that the entity_linking_2022 folder is located
path_ads <- "../fb_2022_adid_text.csv.gz"
# Output files
path_prepared_ads <- "facebook/data/inference_all_fb22_ads.csv.gz"

# Ads
df <- fread(path_ads, encoding = "UTF-8")

# Subset to clean text dataframe
df2 <- df %>%
  select(
    ad_id, google_asr_text, page_name, disclaimer, ad_creative_body,
    ad_creative_link_title, ad_creative_link_description,
    aws_ocr_text_img, aws_ocr_text_vid, ad_creative_link_caption
  )

# Aggregate
df3 <- df2 %>%
  pivot_longer(-ad_id) %>%
  filter(value != "") %>%
  mutate(id = paste(ad_id, name, sep = "__")) %>%
  select(-c(ad_id, name))

df3 <- aggregate(df3$id, by = list(df3$value), c)
names(df3) <- c("text", "id")

# Save
fwrite(df3, path_prepared_ads)
