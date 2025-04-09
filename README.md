# Affective polarization in the Subreddit r/ukpolitics
Data Mining capstone project - Oliver Julier

## Milestones

### 1 Which data am I using?

This project investigates the impact of political shocks on online political discourse by analyzing Reddit comments from the ukpolitics subreddit. Specifically, the project examines user comments made during the five days preceding and the five days following the announcement of the Brexit referendum results. The primary research question guiding this analysis is: **How does a political shock influence the affective polarization present in online political discussions?** By comparing extreme positive and negative comments (with scores of 20 or higher and -10 or lower, respectively), this study seeks to uncover shifts in emotional tone and political sentiment that may signal changes in affective polarization over this critical period.

Based on data availability and the extent of the shock, the announcement of the Brexit referendum result emerged as an operationalized political shock.

### 2 Data acquisition

The data for this analysis was sourced from the politosphere data set. Using provided scripts, comments from the ukpolitics subreddit were extracted for two distinct periods: five days before and five days after the Brexit referendum results were announced. The dataset was further refined to include only those comments that exhibited extreme sentiment, with scores of 20 or higher (positive sentiment) and -10 or lower (negative sentiment). This approach serves as an initial experimental step to gauge changes in affective polarization as a response to the political shock of the Brexit announcement.

- Script for gathering the needed data from the politosphere dataset: ```02_scripts/load_comments.py```

### 3 Data processing

For the analytical phase, I employed the ChatGPT API using the 4o model to categorize the comments based on affective polarization and emotional tone. The prompt used for this categorization instructed the model to assess political posts in terms of in-group favoritism, out-group hostility, and overall emotional tone, classifying each comment into pre-defined categories.

- Script for preparing the needed data and for interacting with the OpenAI API: ```02_scripts/process_data.R```

Prompt for categorization by OpenAI API: 
```
You are an expert in comparative politics, especially in the field of polarization, and are
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
Example 2 of final output: 6, 5
```

### 4 Data analysis

