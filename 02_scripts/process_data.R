knitr::opts_chunk$set(echo = TRUE)
library(tidyverse)
library(jsonlite)
library(httr)
library(dplyr)

# Open a connection to the file
con <- file("00_large-files/comments_extracted_2016-06.json", open = "r")

# Stream in the JSON data
ukpolitics_2016_06 <- stream_in(con)

# Close the connection
close(con)

# Create an initial dataframe with needed columns
df <- data.frame(
  author = ukpolitics_2016_06$author,
  body = ukpolitics_2016_06$body,
  body_cleaned = ukpolitics_2016_06$body_cleaned,
  created_utc = ukpolitics_2016_06$created_utc,
  subreddit = ukpolitics_2016_06$subreddit,
  score = ukpolitics_2016_06$score,
  parent_id = ukpolitics_2016_06$parent_id,
  link_id = ukpolitics_2016_06$link_id,
  stringsAsFactors = FALSE
)

# Convert the UNIX timestamp (created_utc) to POSIXct
df$created_datetime <- as.POSIXct(df$created_utc, origin = "1970-01-01", tz = "UTC")

# Define the event time.
# The Brexit results were announced on Friday 24 June 2016 at 07:20 BST.
# Since BST is UTC+1, the equivalent time in UTC is 06:20.
event_time_utc <- as.POSIXct("2016-06-24 06:20:00", tz = "UTC")

# Define the time windows:
# Five days before the event: from 5 days before event_time to event_time
start_pre <- event_time_utc - 5 * 24 * 60 * 60  # 5 days before event_time
end_pre   <- event_time_utc

# Five days after the event: from event_time to 5 days after event_time
start_post <- event_time_utc
end_post   <- event_time_utc + 5 * 24 * 60 * 60  # 5 days after event_time

# Data frame for five days before the event (up to event_time)
df_before <- df %>%
  filter(created_datetime >= start_pre & created_datetime < end_pre & (score >= 20 | score <= -10))

# Data frame for five days after the event (from event_time to end_post)
df_after <- df %>%
  filter(created_datetime >= start_post & created_datetime < end_post & (score >= 20 | score <= -10))


          # Count number of comments per user, excluding "[deleted]"
          top_users <- df %>%
            filter(author != "[deleted]") %>%  # Remove deleted users
            count(author, sort = TRUE)  # Count comments per user and sort in descending order

          # Filter the dataframe for scores > 99 or < -39 (for reducing the data frame in size)
          df_filtered <- df %>%
            filter(score > 219 | score < -59)

# Create a new dataframe based on df_after & df_before and add new columns for classifications
df_after_cat <- df_after %>%
  mutate(classification1 = NA_real_,
         classification2 = NA_real_)

df_before_cat <- df_before %>%
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
 
99: **Non-Political Content** – The post does not address political, ideological, or group-based topics. Includes entertainment, memes, or everyday conversation.
 
## Example 1
Post: “The other side doesn’t want compromise—they want to destroy everything decent. You can’t reason with that.” 
Response: 2

## Example 2
Post: “It doesn't make sense to discuss about the past. We have to look for solutions together now.” 
Response: 6

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

99: **Invalid** – Could not be assigned to any of the categories.
 
## Example 1
Post: “I can’t believe people are STILL defending this nonsense. It’s infuriating.” 
Response: 1

## Example 2
Post: “Finally, some good news.” 
Response: 4

# Coding format
Do both tasks and then print only the two codes of the classifications separated by a comma.
Use code 99 for Task 1 and code 99 for Task 2 as a last resort if you cannot assign any category.

Only use the output format presented in the following two examples:
Example 1 of final output: 2, 1
Example 2 of final output: 6, 5"

# Authentication
APIkey <- readLines("../openai_key.txt")   # place your API key in a .txt file
bearer <- stringr::str_c("Authorization: Bearer ", APIkey)

# Define a function to call the API and extract the two classification numbers
get_classification <- function(comment_text, prompt_template, model = "gpt-4o", APIkey) {
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
  
  # Make API call with error handling
  response <- tryCatch({
    httr::POST(
      url = "https://api.openai.com/v1/chat/completions",
      httr::content_type("application/json"),
      httr::add_headers(Authorization = paste("Bearer", APIkey)),
      body = list(model = model, messages = messages),
      encode = "json"
    )
  }, error = function(e) {
    warning("API request failed: ", e$message)
    return(NULL)
  })
  
  if (is.null(response)) {
    return(list(score1 = NA, score2 = NA, raw_output = NA))
  }
  
  # Parse API content safely
  res_content <- tryCatch({
    httr::content(response, as = "parsed")
  }, error = function(e) {
    warning("Failed to parse API response: ", e$message)
    return(NULL)
  })
  
  # Check for error or malformed content
  if (is.null(res_content) || is.null(res_content$choices) || length(res_content$choices) == 0) {
    warning("Empty or malformed API response.")
    return(list(score1 = NA, score2 = NA, raw_output = NA))
  }
  
  output_text <- res_content$choices[[1]]$message$content
  
  # Use improved regex: capture exactly two 1- or 2-digit numbers
  numbers <- as.numeric(unlist(regmatches(output_text, gregexpr("\\b\\d{1,2}\\b", output_text))))
  
  if (length(numbers) < 2) {
    warning("Less than 2 numbers found in API response for comment: ", comment_text)
    return(list(score1 = NA, score2 = NA, raw_output = output_text))
  }
  
  return(list(score1 = numbers[1], score2 = numbers[2], raw_output = output_text))
}

# Testing of the function get_classification
sample_comment <- df_before_cat$body[30]
get_classification(sample_comment, prompt_template, APIkey = APIkey)


# Loop through each comment in data frame using the "body" column
df_before_cat <- df_before_cat %>%
  rowwise() %>%
  mutate(
    out = {
      # Pause for a short time on each row
      Sys.sleep(2)
      list(get_classification(body, prompt_template, APIkey = APIkey))
    },
    classification1 = out$score1,
    classification2 = out$score2,
    raw_output = out$raw_output
  ) %>%
  select(-out) %>%
  ungroup()

# Export the updated dataframe to a CSV file
write.csv(df_before_cat, "01_data/df_before_cat.csv", row.names = FALSE)
write.csv(df_after_cat, "01_data/df_after_cat.csv", row.names = FALSE)

