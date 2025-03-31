knitr::opts_chunk$set(echo = TRUE)
library(tidyverse)
library(jsonlite)
library(httr)
library(dplyr)

# Open a connection to the file
con <- file("00_large-files/comments_extracted_2016-10.json", open = "r")

# Stream in the JSON data
ukpolitics_2016_10 <- stream_in(con)

# Close the connection
close(con)

# View the first few rows to confirm
head(ukpolitics_2016_10)

# Create an initial dataframe with needed columns
df <- data.frame(
  author = ukpolitics_2016_10$author,
  body = ukpolitics_2016_10$body,
  body_cleaned = ukpolitics_2016_10$body_cleaned,
  created_utc = ukpolitics_2016_10$created_utc,
  subreddit = ukpolitics_2016_10$subreddit,
  score = ukpolitics_2016_10$score,
  parent_id = ukpolitics_2016_10$parent_id,
  link_id = ukpolitics_2016_10$link_id,
  stringsAsFactors = FALSE
)

# Count number of comments per user, excluding "[deleted]"
top_users <- df %>%
  filter(author != "[deleted]") %>%  # Remove deleted users
  count(author, sort = TRUE)  # Count comments per user and sort in descending order

# Define the selected users
selected_users <- c("UdXYx", "aTPqT", "waoX6", "KLy8w")

# Create individual dataframes for each user
df_1400 <- df %>% filter(author == "UdXYx")  # 1436 comments
df_500  <- df %>% filter(author == "aTPqT")  # 509 comments
df_100  <- df %>% filter(author == "waoX6")  # 100 comments
df_20   <- df %>% filter(author == "KLy8w")  # 20 comments

# Create .csv files for testing dataframes
write.csv(df_1400, "01_data/user_1400_comments.csv", row.names = FALSE)
write.csv(df_500, "01_data/user_500_comments.csv", row.names = FALSE)
write.csv(df_100, "01_data/user_100_comments.csv", row.names = FALSE)
write.csv(df_20, "01_data/user_20_comments.csv", row.names = FALSE)

# Authentication
APIkey <- readLines("../openai_key.txt")   # place your API key in a .txt file
bearer <- stringr::str_c("Authorization: Bearer ", APIkey)

