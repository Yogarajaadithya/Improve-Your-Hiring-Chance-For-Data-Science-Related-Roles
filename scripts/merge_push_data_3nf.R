library(tidyverse)
library(jsonlite)
library(dbplyr)
library(DBI)

# merge industry column to main table
df <- read.csv('../data/data_jobs_cleaned.csv')
df$industry <- NA
df$job_work_from_home <- ifelse(df$job_work_from_home == "True", TRUE, FALSE)
df$job_no_degree_mention <- ifelse(df$job_no_degree_mention == "True", TRUE, FALSE)
df$job_health_insurance <- ifelse(df$job_health_insurance == "True", TRUE, FALSE)

domain <- read.csv('../data/company_domain.csv')
colnames(domain) <- c('company_name', 'industry')

df <- dplyr::left_join(df,domain, by = 'company_name')
df$industry.x <- NULL
colnames(df)[15] <- 'industry'


# normalize to 3NF form
df <- df %>%
  mutate(skill_type_json = gsub("'", '"', job_type_skills))

df$jobid <- 1:nrow(df)

# Create skill types table
skill_type_table <- df %>%
  select(jobid, skill_type_json) %>%
  rowwise() %>%
  mutate(skill_type_parsed = list(fromJSON(skill_type_json))) %>%
  select(jobid, skill_type_parsed) %>%
  unnest_wider(skill_type_parsed) %>%
  pivot_longer(-jobid, names_to = "skill_category", values_to = "skills") %>%
  filter(!is.na(skills)) %>%
  unnest(skills)

multiE <- c("mongodb", "sas", "ruby", "firebase")

# handle mongo
skill_type_table <- skill_type_table %>%
  filter(!(skill_category == "programming" & (skills == "mongodb" | skills == "mongo")))

# ruby
skill_type_table[skill_type_table$skill_category == "webframeworks" & skill_type_table$skills == "ruby",]$skills <- "ruby on rails"

# sas
skill_type_table[skill_type_table$skill_category == "analyst_tools" & skill_type_table$skills == "sas",]$skills <- "sas tool"

# firebase
skill_type_table[skill_type_table$skill_category == "cloud" & skill_type_table$skills == "firebase",]$skills <- "firebase cloud"

# remove duplicated ruby on rails
skill_type_table <- skill_type_table[!duplicated(skill_type_table), ]

# Create unique skills table
skills_table <- skill_type_table %>%
  distinct(skills) %>%
  rename(skill = skills) %>%
  mutate(skill_id = row_number())

# Create unique category table
skill_categories <- skill_type_table %>%
  inner_join(skills_table, by = c("skills" = "skill")) %>%
  select(skill_id, skill_category) %>%
  distinct()

# Map skills to jobid via skill categories
job_skill_mapping <- skill_type_table %>%
  inner_join(skills_table, by = c("skills" = "skill")) %>%
  select(jobid, skill_id)



# Final Normalized Tables in 3NF
# jobs table
jobs_table <- df %>% select(-c(job_skills, job_type_skills, skill_type_json, jobid))

# skills_table
#skills_table

# skill_categories
#skill_categories

# job_skill_mapping
#job_skill_mapping

# dupes <- job_skill_mapping[duplicated(job_skill_mapping) | duplicated(job_skill_mapping, fromLast = TRUE), ] 
# 
# for(i in unique(dupes$skill_id)){
#   print(skills_table[skills_table$skill_id == i,]$skill)
# }

# Connect to Postgres Database
pw <- "muix7pcj"

con <- dbConnect(
  RPostgres::Postgres(), 
  dbname = "ds_jobs",
  port = 5432, 
  user = "postgres", 
  password = pw
)

#Check if table exists
query <- sprintf("SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = '%s');", 'jobpostings')
exists <- dbGetQuery(con, query)$exists

if (exists) {
  print("Table jobpostings already exists in the database.\n")
} else {
dbExecute(con, "
  CREATE TABLE jobpostings (
    jobid SERIAL PRIMARY KEY,
    job_title_short VARCHAR(100),
    job_location VARCHAR(1000),
    job_via VARCHAR(500),
    job_schedule_type VARCHAR(500),
    job_work_from_home BOOLEAN,
    search_location VARCHAR(1000),
    job_posted_date TIMESTAMP,
    job_no_degree_mention BOOLEAN,
    job_health_insurance BOOLEAN,
    job_country VARCHAR(300),
    salary_year_avg INT,
    company_name VARCHAR(1000),
    industry VARCHAR(1000)
  );
")
}
# append data 
dbWriteTable(
  con,
  name = "jobpostings",    
  value = jobs_table,
  append = TRUE,    
  row.names = FALSE
)

query <- sprintf("SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = '%s');", 'skills_table')
exists <- dbGetQuery(con, query)$exists

if (exists) {
  print("Table skills_table already exists in the database.\n")
} else {
dbExecute(con, "
  CREATE TABLE skills_table (
    skill VARCHAR(1000),
    skill_id INT PRIMARY KEY
  );
")
}

# append data 
dbWriteTable(
  con,
  name = "skills_table",    
  value = skills_table,
  append = TRUE,    
  row.names = FALSE
)

query <- sprintf("SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = '%s');", 'skill_categories')
exists <- dbGetQuery(con, query)$exists

if (exists) {
  print("Table skill_categories already exists in the database.\n")
} else {
dbExecute(con, "
  CREATE TABLE skill_categories (
    skill_id INT PRIMARY KEY,
    skill_category VARCHAR(500)
  );
")
}
# append data 
dbWriteTable(
  con,
  name = "skill_categories",    
  value = skill_categories,
  append = TRUE,    
  row.names = FALSE
)

query <- sprintf("SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = '%s');", 'job_skill_mapping')
exists <- dbGetQuery(con, query)$exists

if (exists) {
  print("Table job_skill_mapping already exists in the database.\n")
} else {
dbExecute(con, "
  CREATE TABLE job_skill_mapping (
    jobid INT NOT NULL,
    skill_id INT NOT NULL,
    PRIMARY KEY (jobid, skill_id)
  );
")
}
# append data 
dbWriteTable(
  con,
  name = "job_skill_mapping",    
  value = job_skill_mapping,
  append = TRUE,    
  row.names = FALSE
)

dbDisconnect(con)
