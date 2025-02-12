# Improve-Your-Hiring-Chance-For-Data-Science-Related-Roles

## Overview
This project is designed to help data science job aspirants improve their hiring chances by analyzing job postings, salary trends, and in-demand skills. It leverages SQL queries to extract insights from a PostgreSQL database and uses R scripts for data cleaning, merging, and normalization workflows.

## Project Structure
- **scripts/**
  - **query_commands.sql**: Contains SQL queries for data insights and reporting.
  - **clean_scraped_data.R**: Cleans raw scraped job data.
  - **merge_push_data.R**: Merges cleaned data and pushes it to the "jobs" table.
  - **merge_push_data_3nf.R**: Normalizes data into Third Normal Form (3NF) and updates related tables.
- **data/**: Stores raw and cleaned CSV data.
- **README.md**: Provides project documentation and usage instructions.

## Usage
1. Run `clean_scraped_data.R` to preprocess and clean the raw data.
2. Execute `merge_push_data.R` to import the cleaned data into the PostgreSQL database.
3. Run `merge_push_data_3nf.R` to normalize the data into job postings, skills, skill categories, and job-skill mapping tables.
4. Use `query_commands.sql` to run SQL queries that analyze industry trends, skill demand, and salary statistics.

## Requirements
- PostgreSQL Database ("ds_jobs")
- R (with packages: dplyr, DBI, RPostgres, jsonlite, tidyverse, etc.)
- CSV data files in the **data/** folder

## Contributing
Contributions are welcome! Please follow standard Git practices and add clear comments to help maintain the project.