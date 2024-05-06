library(data.table)
library(dplyr)
library(tidyr)

# Input files
# This is an output from data-post-production/01-merge-results/01_merge_preprocessed_results
path_ads <- "fb_2022_adid_text_clean.csv.gz"

# This is the output table from `data-post-production/01-merge-results/01_merge_preprocessed_results`
path_adid_to_pageid <- "fb_2022_adid_var1.csv.gz"

path_entities_kb <- "../data/entity_kb.csv"
path_wmpent_file <- "../../../datasets/wmp_entity_files/Facebook/2022/wmp_fb_2022_entities_v120122.csv"
# Output files
path_output <- "../data/ads_with_aliases.csv.gz"


# Pdid to wmpid
wmpents <- fread(path_wmpent_file) %>%
  select(pd_id, wmpid)
wmpents <- wmpents[wmpents$wmpid != "", ]

# Ads
df <- fread(path_ads, encoding = "UTF-8")

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
