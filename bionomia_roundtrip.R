library(tidyverse)
library(magrittr)

#take datasetguid as argument for cl execution
#only needed if data files not already present in data folder
datasetguid = commandArgs(trailingOnly = T)

#uncomment next line to set a fixed dataset guid
#datasetguid = "b740eaa0-0679-41dc-acb7-990d562dfa37"

#download data files for provided dataset from bionomia
if (length(datasetguid) > 0) {
  if (!file.exists("data/attributions.csv")) {
    download.file(paste0("https://bionomia.net/dataset/",
                         datasetguid,
                         "/attributions.csv.zip"),
                  "data/temp/attributions.csv.zip",
                  mode = "wb")
    unzip("data/temp/attributions.csv.zip",
          exdir = "data")
    file.remove("data/temp/attributions.csv.zip")
  }
  if (!file.exists("data/occurrences.csv")) {
    download.file(paste0("https://bionomia.net/dataset/",
                         datasetguid,
                         "/occurrences.csv.zip"),
                  "data/temp/occurrences.csv.zip",
                  mode = "wb")
    unzip("data/temp/occurrences.csv.zip",
          exdir = "data")
    file.remove("data/temp/occurrences.csv.zip")
  }
  if (!file.exists("data/users.csv")) {
    download.file(paste0("https://bionomia.net/dataset/",
                         datasetguid,
                         "/users.csv.zip"),
                  "data/temp/users.csv.zip",
                  mode = "wb")
    unzip("data/temp/users.csv.zip",
          exdir = "data")
    file.remove("data/temp/users.csv.zip")
  }
}

#read all attributions, exclude those sourced from GBIF
attributions = read_csv("data/attributions.csv",
                        col_types = cols(.default = "c")) %>%
  filter(createdBy!="GBIF Sourced") %>%
  select(occurrence_id,
         identifiedBy,
         recordedBy) 

#read the provided occurrence metadata
occurrences = read_csv("data/occurrences.csv",
               col_types = cols(.default = "c")) %>%
  select(gbifID,
         occurrenceID,
         recordedBy,
         identifiedBy,
         eventDate,
         dateIdentified)

#read the names parsed from wikidata/orcid
users = read_csv("data/users.csv",
                 col_types = cols(.default = "c")) %>%
  select(name,
         sameAs)

#subset the identifying agents from the collecting ones
attributions_id = attributions %>%
  filter(!is.na(identifiedBy)) %>%
  select(-recordedBy) %>%
  rename(identifier = identifiedBy,
         gbifID = occurrence_id) %>%
  mutate(action = "identified")

#bind the identifying agents to the collecting ones
attributions %<>%
  filter(!is.na(recordedBy)) %>%
  select(-identifiedBy) %>%
  rename(identifier = recordedBy,
         gbifID = occurrence_id) %>%
  mutate(action = "collected") %>%
  bind_rows(attributions_id) %>%
  mutate(agentType = "Person",
         agentIdentifierType = ifelse(grepl("wikidata",
                                            identifier),
                                      "wikidata",
                                      "orcid"))

#add occurrence metadata, reformat dates
attributions %<>%
  left_join(occurrences,
            by=c("gbifID"="gbifID")) %>%
  mutate(date = ifelse(action == "collected",
                       eventDate,
                       dateIdentified),
         startedAtTime = gsub("/.*","",date),
         endedAtTime = ifelse(is.na(date)|
                                date == startedAtTime,
                              date,
                              gsub(".*/","",date)),
         verbatimName = ifelse(action == "collected",
                               recordedBy,
                               identifiedBy)) %>%
  select(-date,
         -eventDate,
         -dateIdentified,
         -recordedBy,
         -identifiedBy)

#add names from wikidata/orcid: name for individual, not whole team
attributions %<>%
  left_join(users,by = c("identifier" = "sameAs"))
#not all names in users.csv!!

#write to file
file_name = paste0("output/Agents ",
                 datasetguid,
                 " ",
                 format(Sys.time(), "%Y-%m-%d %I.%M%p"),
                 ".csv")

write_csv(attributions,file_name,na="")