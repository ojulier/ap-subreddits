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

# Filter the dataframe for scores > 99 or < -39 (for reducing the data frame in size)
df_filtered <- df %>%
  filter(score > 219 | score < -59)

# Create a new dataframe based on df_filtered and add new columns for classifications
df_categorized <- df_filtered %>%
  mutate(classification1 = NA_real_,
         classification2 = NA_real_)

# Define prompt template
prompt_template <- "You are an expert in comparative politics, especially in the field of polarization, and are
well-versed in UK politics and European politics in general as well as the issues that were salient in the year 2016. You have 2 tasks involving the classification of posts and replies in the Subreddit ukpolitics in October 2016. 
Important: before printing your answer, double check to make sure that you provide the most accurate classification possible.

# TASK 1 – Affective Polarization in Subreddits
Assess the extent to which a post expresses affective polarization—i.e., emotional, moral, or identity-based division toward political or social groups. This includes expressions of in-group favoritism, out-group hostility, dehumanization, ridicule, or moral condemnation. Posts can reflect polarization explicitly (e.g., attacks on opposing groups) or implicitly (e.g., sarcasm, moral disgust, or tribal language). Classify posts based on the dominant tone and emotional stance toward political or social groups.
 
## List of Categories (Use only the code in the final classification)
 
1: **Extreme Out-Group Hate / Dehumanization** – Expresses contempt, disgust, or hatred toward opposing political or social groups. May include moral condemnation, demonization, or calls for exclusion, violence, or punishment.
 
2: **High Affective Polarization / Strong Negative Partisanship** – Displays strong emotional dislike or distrust toward opposing groups or ideologies. Includes intense sarcasm, ridicule, name-calling, or claims of existential threat posed by the out-group.
 
3: **Moderate Affective Polarization / Negative Stereotyping** – Conveys emotional distance or negative generalizations about other groups. May involve blame, mild insults, or expressions of superiority without extreme hostility.
 
4: **In-Group Praise / Tribal Solidarity** – Highlights emotional connection, loyalty, or moral superiority of one’s own group without necessarily attacking others. Focuses on group pride, shared identity, or virtue signaling.
 
5: **Mixed / Ambivalent Sentiment** – Expresses both in-group and out-group sentiments, or shifts tone across the post. May include both criticism and praise, or present a nuanced emotional stance.
 
6: **Depolarizing / Bridge-Building Content** – Promotes empathy, mutual understanding, or respectful disagreement. Rejects tribalism or calls for cooperation, tolerance, or shared humanity.
 
7: **Neutral / Non-Polarized Political Content** – Engages with politics but without emotional language, hostility, or group-based framing. May involve policy discussion, information sharing, or procedural commentary.
 
8: **Non-Political Content** – The post does not address political, ideological, or group-based topics. Includes entertainment, memes, or everyday conversation.
 
## Example 
Post: “The other side doesn’t want compromise—they want to destroy everything decent. You can’t reason with that.” 
Response: 2

# TASK 2 – Emotional Tone (Affect) in Social Media Posts 
Assess the dominant emotional tone conveyed in the post, based on the author's language, framing, and affective cues. Consider explicit emotional expressions (e.g., “I’m angry,” “this is wonderful”) and implicit indicators (e.g., sarcasm, exclamation marks, emotionally loaded adjectives). Classify posts according to their **primary emotional tone**, even if multiple emotions are present. If no clear emotional tone is detectable, choose the neutral category.
 
## List of Categories (Use only the code in the final classification)
 
1: **Anger / Frustration** – Expresses irritation, outrage, resentment, or moral indignation. May include rants, blame, sarcasm, or emotionally charged critique.
 
2: **Fear / Anxiety** – Reflects worry, dread, panic, or concern about future events. Often uses uncertain or alarming language, especially about threats or instability.
 
3: **Sadness / Grief** – Conveys sorrow, loss, disappointment, or hopelessness. May include personal stories of pain, social critique with a mournful tone, or empathetic reflections.
 
4: **Joy / Enthusiasm** – Expresses happiness, excitement, inspiration, or celebration. Often includes praise, humor, success stories, or emotional uplift.
 
5: **Compassion / Empathy** – Shows care, sympathy, or emotional support toward others. May involve solidarity, kindness, or appeals to shared humanity.
 
6: **Sarcasm / Cynicism** – Uses ironic tone, mockery, or skeptical humor to distance the author from the topic. May mask underlying emotions such as anger or disappointment.
 
7: **Disgust / Contempt** – Communicates revulsion, moral rejection, or condescension. May include moralistic language, ridicule, or expressions of being offended.
 
8: **Neutral / Factual** – The post maintains a neutral tone without affective charge. It presents information, asks questions, or reflects without emotional expression.
 
9: **Mixed / Ambiguous Affect** – Multiple emotions are equally present, or the tone is unclear. May include contrastive elements, vague tone, or emotionally confusing content.
 
## Example 
Post: “I can’t believe people are STILL defending this nonsense. It’s infuriating.” 
Response: 1

## Coding format
Do both tasks and then print only the two codes of the classifications separated by a comma. Example: 2, 1"

# Authentication
APIkey <- readLines("../openai_key.txt")   # place your API key in a .txt file
bearer <- stringr::str_c("Authorization: Bearer ", APIkey)

# Define a function to call the API and extract the two classification numbers
get_classification <- function(comment_text, prompt_template) {
  # Build the messages list for the ChatGPT API
  messages <- list(
    list(
      role = "system",
      content = "You are a text classifier that analyzes comments for affective polarization. Output only two numbers separated by a comma."
    ),
    list(
      role = "user",
      content = paste(prompt_template, "\n\nComment:", comment_text)
    )
  )
  
  # Make the API request
  response <- httr::POST(
    url = "https://api.openai.com/v1/chat/completions",
    content_type("application/json"),
    add_headers(Authorization = paste("Bearer", APIkey)),
    body = list(
      model = "gpt-4o",
      messages = messages
    ),
    encode = "json"
  )
  
  # Parse the response
  res_content <- content(response)
  output_text <- res_content$choices[[1]]$message$content
  
  # Extract numbers using regex (assuming output like "6, 7")
  numbers <- as.numeric(unlist(regmatches(output_text, gregexpr("[0-9]+", output_text))))
  
  if (length(numbers) < 2) {
    warning("Less than 2 numbers found in API response for comment: ", comment_text)
    return(c(NA, NA))
  }
  
  return(numbers[1:2])
}

# Testing of the function get_classification
sample_comment <- df_categorized$body[8]
get_classification(sample_comment, prompt_template)


# Loop through each comment in df_categorized using the "body" column
for (i in seq_len(nrow(df_categorized))) {
  comment_text <- df_categorized$body[i]
  
  # Get the classification numbers from the API
  classification_numbers <- get_classification(comment_text, prompt_template)
  
  # Update the dataframe with the returned classification numbers
  df_categorized$classification1[i] <- classification_numbers[1]
  df_categorized$classification2[i] <- classification_numbers[2]
}

# Export the updated dataframe to a CSV file
write.csv(df_categorized, "df_categorized.csv", row.names = FALSE)
