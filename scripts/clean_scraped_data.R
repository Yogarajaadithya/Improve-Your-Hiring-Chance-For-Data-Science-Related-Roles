df <- read.csv('../data/data_jobs.csv')

df[df == ""] <- NA

df <- df[!is.na(df$salary_year_avg),]

df[,c('salary_rate', 'salary_hour_avg', 'job_title')] <- NULL

df <- df[complete.cases(df),]

df$job_via <- tolower(trimws(gsub("via", "", df$job_via)))
df$salary_year_avg <- round(df$salary_year_avg, 0)

write.csv(df, '../data/data_jobs_cleaned.csv', row.names = FALSE)


df <- head(df[!is.na(df$salary_year_avg),], 5)

write.csv(df, './firstfive.csv', row.names = FALSE)
