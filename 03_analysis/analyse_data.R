library(ggplot2)
library(dplyr)
library(readr)
library(gridExtra)
library(tidyr)
library(scales)

# Read the CSV files
df_before_brexit <- read_csv("01_data/df_before_cat.csv")
df_after_brexit  <- read_csv("01_data/df_after_cat.csv")

# Add a column to denote the period
df_before_brexit <- df_before_brexit %>% mutate(period = "before")
df_after_brexit  <- df_after_brexit  %>% mutate(period = "after")

# Combine the datasets
df_all <- bind_rows(df_before_brexit, df_after_brexit) %>%
  mutate(period = factor(period, levels = c("before", "after")))

# Ensure that the classification columns are factors
df_all <- df_all %>%
  mutate(classification1 = factor(classification1, levels = c("1","2","3","4","5","6","7","99")),
         classification2 = factor(classification2, levels = c("1","2","3","4","5","6","7","8","9","99")))



# --- Affective Polarization Category ("classification1") ---

# Filter out NA values for classification1
df_class1 <- df_all %>% filter(!is.na(classification1))

# Calculate relative frequencies for classification1 by period
df_summary_class1 <- df_class1 %>%
  group_by(period, classification1) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(period) %>%
  mutate(percentage = count / sum(count)) %>%
  ungroup()

# Create a grouped bar chart for classification1
p_class1 <- ggplot(df_summary_class1, aes(x = classification1, y = percentage, fill = period)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
  scale_y_continuous(labels = scales::percent_format(), limits = c(0, 0.5)) +
  labs(x = "Affective Polarization Category",
       y = "Percentage of Total Coded Categories",
       title = "Relative Distribution of Affective Polarization Categories",
       fill = "Period") +
  theme_minimal()


# --- Emotional Tone Category ("classification2") ---

# Filter out NA values for classification2
df_class2 <- df_all %>% filter(!is.na(classification2))

# Calculate relative frequencies for classification2 by period
df_summary_class2 <- df_class2 %>%
  group_by(period, classification2) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(period) %>%
  mutate(percentage = count / sum(count)) %>%
  ungroup()

# Create a grouped bar chart for classification2
p_class2 <- ggplot(df_summary_class2, aes(x = classification2, y = percentage, fill = period)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
  scale_y_continuous(labels = scales::percent_format(), limits = c(0, 0.5)) +
  labs(x = "Emotional Tone Category",
       y = "Percentage of Total Coded Categories",
       title = "Relative Distribution of Emotional Tone Categories",
       fill = "Period") +
  theme_minimal()

# Display both plots
grid.arrange(p_class1, p_class2, ncol = 2)

# Compute counts and relative frequencies (percentages) for each pairing by period
df_summary <- df_all %>%
  group_by(period, classification1, classification2) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(period) %>%
  mutate(percentage = count / sum(count)) %>%
  ungroup()

# Create a heatmap that shows the relative frequency of the (classification1, classification2) pairings, faceted by Period
ggplot(df_summary, aes(x = factor(classification1), y = factor(classification2), fill = percentage)) +
  geom_tile(color = "white") +
  geom_text(aes(label = scales::percent(percentage, accuracy = 0.1)), color = "white", size = 2) +
  facet_wrap(~ period) +
  scale_fill_gradient(low = "cornflowerblue", high = "coral1", labels = percent_format(accuracy = 1)) +
  labs(x = "Affective polarization category (classification1)",
       y = "Emotional tone category (classification2)",
       fill = "Percentage",
       title = "Relative frequency of category pairings before and after Brexit referendum") +
  theme_minimal()
