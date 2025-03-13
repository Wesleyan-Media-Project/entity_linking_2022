# Post-processing for the entity linking results
library(tidyverse)
library(data.table)
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)

df <- fread("google/data/entity_linking_results_google_2022.csv.gz")
path_var1 <- "../data_post_production/g2022_adid_var1.csv.gz"
path_ent <- "../datasets/wmp_entity_files/Google/wmp_google_2022_entities_v112822.csv"

#----
# Combine fields
df2 <- df %>%
  select(ad_id, ends_with('detected_entities'), field, text, text_start, text_end) %>% 
  mutate(across(ends_with('detected_entities'), function(x){str_remove_all(x, "\\[|\\]|\\'")}))

df2[df2 == ""] <- NA

df3 <- df2 %>% 
  unite(col = detected_entities, ends_with('detected_entities'), sep = ", ", na.rm = T)

# Remove all ads with no detected entities
df4 <- df3 %>% filter(detected_entities != "")

# For ad tone, remove advertiser_name
el_at <- df4 %>% filter(!field %in% c("advertiser_name"))

# load entities and var 1 to get the wmpid for the sponspor of the ad
var1 <- fread(path_var1) %>%
  select(ad_id, advertiser_id)

ent <- fread(path_ent) %>%
  select(advertiser_id, wmpid, wmp_spontype)

ent2 <- merge(var1, ent, by = "advertiser_id")

# divide el_at into two: one for asr/ocr, one for other fields, MERGE el_at_nopfb AND el_at_pfb3 LATER
el_at_nopfb <- el_at %>%
  filter(!field %in% c("aws_ocr_text_img", "aws_ocr_text_vid", "google_asr_text"))

el_at_pfb <- el_at %>%
  filter(field %in% c("aws_ocr_text_img", "aws_ocr_text_vid", "google_asr_text"))

# check if el_at_pfb has any detected entities after the PFB line that is same as the sponsor of the ad
el_at_pfb2 <- merge(el_at_pfb, ent2, by = "ad_id", all.x = TRUE)

# MERGE el_at_pfb2_nocand AND el_at_pfb2_cand5 LATER, convert el_at_pfb2_cand5 back to original format first
el_at_pfb2_nocand <- el_at_pfb2 %>%
  filter(wmp_spontype != "campaign" | is.na(wmp_spontype))

el_at_pfb2_cand <- el_at_pfb2 %>%
  filter(wmp_spontype == "campaign") %>%
  mutate(text = tolower(text),
         end_pfb = str_locate(text, "paid for by")[,2] - 1,
         start_pfb = str_locate(text, "approve this message")[,1] - 1)

el_at_pfb2_cand2 <- el_at_pfb2_cand %>%
  mutate(
    text_start = str_remove_all(text_start, "[\\[\\]]"),  # Remove brackets if present
    text_end = str_remove_all(text_end, "[\\[\\]]")       # Remove brackets if present
  ) %>%
  separate_rows(detected_entities, text_start, text_end, sep = ",") %>%
  mutate(
    text_start = as.integer(text_start),
    text_end = as.integer(text_end),
    detected_entities = str_trim(detected_entities)
  )

# MERGE LATER el_at_pfb2_cand_match_nodrop AND el_at_pfb2_cand_nomatch
el_at_pfb2_cand_nomatch <- el_at_pfb2_cand2 %>%
  filter(((end_pfb < text_start - 6 | end_pfb > text_start - 1 | is.na(end_pfb)) & 
            (start_pfb < text_end + 5 | start_pfb > text_end + 10 | is.na(start_pfb))))

el_at_pfb2_cand_match <- el_at_pfb2_cand2 %>%
  filter(((end_pfb >= text_start - 6 & end_pfb <= text_start - 1) | 
            (start_pfb >= text_end + 5  & start_pfb <= text_end + 10)))

# Ensure no rows are lost (Should return True)
nrow(el_at_pfb2_cand_match) + nrow(el_at_pfb2_cand_nomatch) == nrow(el_at_pfb2_cand2)


# DO NOT MERGE LATER, el_at_pfb2_cand_match_drop WILL BE DROPPED
el_at_pfb2_cand_match_nodrop <- el_at_pfb2_cand_match %>%
  filter(wmpid != detected_entities)

el_at_pfb2_cand_match_drop <- el_at_pfb2_cand_match %>%
  filter(wmpid == detected_entities)


# There are 378 cases where this is the case so we drop those detections
# Put everything back together
el_at_pfb2_cand3 <- bind_rows(el_at_pfb2_cand_match_nodrop, el_at_pfb2_cand_nomatch)

el_at_pfb2_cand4 <- el_at_pfb2_cand3 %>%
  group_by(across(-c(detected_entities, text_start, text_end))) %>%  # Group by unchanged columns
  summarise(
    detected_entities = paste(detected_entities, collapse = ", "),
    text_start = paste(text_start, collapse = ", "),
    text_end = paste(text_end, collapse = ", "),
    .groups = "drop"
  )


el_at_pfb2_cand5 <- el_at_pfb2_cand4 %>%
  mutate(text_start = paste0("[", text_start, "]"),
         text_end = paste0("[", text_end, "]"))


el_at_pfb3 <- bind_rows(el_at_pfb2_nocand, el_at_pfb2_cand5)

el_at2 <- bind_rows(el_at_nopfb, el_at_pfb3) %>%
  select(detected_entities, text_start, text_end, ad_id, field)

# Aggregate based on ad_id
df5 <- df4 %>%
  select(ad_id, detected_entities, field) %>%
  group_by(ad_id) %>%
  summarize(
    detected_entities = paste(unique(detected_entities), collapse = ", "),
    field = paste(unique(field), collapse = ", ")
  )


df5_at <- el_at2 %>%
  select(ad_id, detected_entities, field) %>%
  group_by(ad_id) %>%
  summarize(
    detected_entities = paste(unique(detected_entities), collapse = ", "),
    field = paste(unique(field), collapse = ", ")
  )


# Save version with combined fields
fwrite(df5, "google/data/entity_linking_results_google_2022_notext_combined.csv.gz")
fwrite(df5_at, "google/data/entity_linking_results_google_2022_notext_combined_for_ad_tone.csv.gz")
