# Post-processing for the entity linking results
# Gather up all detected entities from different fields and put them all together

library(data.table)
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)

# Paths
# In
path_detected_entities <- "facebook/data/entity_linking_results_fb22.csv.gz"
path_var1 <- "../data_post_production/fb_2022_adid_var1.csv.gz"
path_ent <- "../datasets/wmp_entity_files/Facebook/2022/wmp_fb_2022_entities_v082324.csv"
# Out
path_finished_enties <- "facebook/data/detected_entities_fb22.csv.gz"
path_finished_enties_for_ad_tone <- "facebook/data/detected_entities_fb22_for_ad_tone.csv.gz"

# Read in Spacy's detected entities
el <- fread(path_detected_entities)

# Transform the Python-based detected entities field into an R list
transform_pylist <- function(x){
  x <- str_remove_all(x, "\\[|\\]|\\'")
  x <- str_remove_all(x, " ")
  return(x)
}
el$text_detected_entities <- transform_pylist(el$text_detected_entities)
# Remove all ads with no detected entities
el <- el %>% 
  filter(text_detected_entities != "")

el2 <- el %>%
  select(!text)

## AD TONE
# For ad tone, remove disclaimer and page_name
el_at <- el %>% filter(!field %in% c("page_name", "disclaimer")) 
# For candidate ads, check asr ocr fields
# if candidate id is detected right after PFB line, drop that detected entity

# load entities and var 1 to get the wmpid for the sponspor of the ad
var1 <- fread(path_var1) %>%
  select(ad_id, pd_id)

ent <- fread(path_ent) %>%
  select(pd_id, wmpid, wmp_spontype)

ent2 <- merge(var1, ent, by = "pd_id")

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
         end_pfb = str_locate(text, "paid for by")[,2] - 1)

el_at_pfb2_cand2 <- el_at_pfb2_cand %>%
  mutate(
    text_start = str_remove_all(text_start, "[\\[\\]]"),  # Remove brackets if present
    text_end = str_remove_all(text_end, "[\\[\\]]")       # Remove brackets if present
  ) %>%
  separate_rows(text_detected_entities, text_start, text_end, sep = ",") %>%
  mutate(
    text_start = as.integer(text_start),
    text_end = as.integer(text_end)
  )

# MERGE LATER el_at_pfb2_cand_match_nodrop AND el_at_pfb2_cand_nomatch
el_at_pfb2_cand_nomatch <- el_at_pfb2_cand2 %>%
  filter(end_pfb != text_start - 2 | is.na(end_pfb))

el_at_pfb2_cand_match <- el_at_pfb2_cand2 %>%
  filter(end_pfb == text_start - 2)


# DO NOT MERGE LATER, el_at_pfb2_cand_match_drop WILL BE DROPPED
el_at_pfb2_cand_match_nodrop <- el_at_pfb2_cand_match %>%
  filter(wmpid != text_detected_entities)

el_at_pfb2_cand_match_drop <- el_at_pfb2_cand_match %>%
  filter(wmpid == text_detected_entities)


# There are 8420 cases where this is the case so we drop those detections
# Put everything back together
el_at_pfb2_cand3 <- bind_rows(el_at_pfb2_cand_match_nodrop, el_at_pfb2_cand_nomatch)

el_at_pfb2_cand4 <- el_at_pfb2_cand3 %>%
  group_by(across(-c(text_detected_entities, text_start, text_end))) %>%  # Group by unchanged columns
  summarise(
    text_detected_entities = paste(text_detected_entities, collapse = ","),
    text_start = paste(text_start, collapse = ", "),
    text_end = paste(text_end, collapse = ", "),
    .groups = "drop"
  )


el_at_pfb2_cand5 <- el_at_pfb2_cand4 %>%
  mutate(text_start = paste0("[", text_start, "]"),
         text_end = paste0("[", text_end, "]"))


el_at_pfb3 <- bind_rows(el_at_pfb2_nocand, el_at_pfb2_cand5)

el_at2 <- bind_rows(el_at_nopfb, el_at_pfb3) %>%
  select(text_detected_entities, text_start, text_end, ad_id, field)


# Aggregate over fields, then clean up and put things back into a list
el2 <- aggregate(el2$text_detected_entities, by = list(el2$ad_id), c)
el2$x <- lapply(el2$x, paste, collapse = ",")
el2$x <- str_split(el2$x, ",")
names(el2) <- c("ad_id", "detected_entities")
# Same for ad tone
el_at2 <- aggregate(el_at2$text_detected_entities, by = list(el_at2$ad_id), c)
el_at2$x <- lapply(el_at2$x, paste, collapse = ",")
el_at2$x <- str_split(el_at2$x, ",")
names(el_at2) <- c("ad_id", "detected_entities")

# Save version with combined fields
fwrite(el2, path_finished_enties)
fwrite(el_at2, path_finished_enties_for_ad_tone)
