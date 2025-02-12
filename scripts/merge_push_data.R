library(dplyr)
library(dbplyr)
library(DBI)

df <- read.csv('../data/data_jobs_cleaned.csv')
df$industry <- NA
df$job_work_from_home <- ifelse(df$job_work_from_home == "True", TRUE, FALSE)
df$job_no_degree_mention <- ifelse(df$job_no_degree_mention == "True", TRUE, FALSE)
df$job_health_insurance <- ifelse(df$job_health_insurance == "True", TRUE, FALSE)

domain <- read.csv('../data/company_domain.csv')
colnames(domain) <- c('company_name', 'industry')

df <- dplyr::left_join(df, domain, by = 'company_name')
df$industry.x <- NULL
colnames(df)[15] <- 'industry'


pw <- "muix7pcj"

con_try <- dbCanConnect(
  RPostgres::Postgres(), 
  dbname="ds_jobs", 
  port = 5432,
  user = "postgres", 
  password = pw
  )

if(con_try){
  print("Database Connection Succesful")
} 

con <- dbConnect(
  RPostgres::Postgres(), 
  dbname = "ds_jobs",
  port = 5432, 
  user = "postgres", 
  password = pw
  )

#if table exists
query <- sprintf("SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = '%s');", 'jobs')
exists <- dbGetQuery(con, query)$exists

if (exists) {
  cat(sprintf("Table jobs already exists in the database.\n",))
} else {
dbExecute(con, "
  CREATE TABLE jobs (
    id SERIAL PRIMARY KEY,
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
    job_skills VARCHAR(3000),
    job_type_skills VARCHAR(5000),
    industry VARCHAR(1000)
  );
")
}

# append data into the existing table
dbWriteTable(
  con,
  name = "jobs",    
  value = df,
  append = TRUE,        #Add to existing table
  row.names = FALSE
)


df_postgres <- dbGetQuery(con, "SELECT * FROM jobs;")

# You can also disconnect from a database using:
dbDisconnect(con)

