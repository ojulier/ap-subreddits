knitr::opts_chunk$set(echo = TRUE)
library(tidyverse)
library(jsonlite)
library(httr)

# Open a connection to the file
con <- file("00_large-files/comments_extracted_2016-10.json", open = "r")

# Stream in the JSON data
ukpolitics_2016_10 <- stream_in(con)

# Close the connection
close(con)

# View the first few rows to confirm
head(ukpolitics_2016_10)

# Create a dataframe with needed columns
df <- data.frame(
  author = ukpolitics_2016_10$author,
  body = ukpolitics_2016_10$body_cleaned,
  created_utc = ukpolitics_2016_10$created_utc,
  subreddit = ukpolitics_2016_10$subreddit,
  score = ukpolitics_2016_10$score,
  parent_id = ukpolitics_2016_10$parent_id,
  link_id = ukpolitics_2016_10$link_id,
  stringsAsFactors = FALSE
)

# Authentication
APIkey <- readLines("../openai_key.txt")   # place your API key in a .txt file
bearer <- stringr::str_c("Authorization: Bearer ", APIkey)

