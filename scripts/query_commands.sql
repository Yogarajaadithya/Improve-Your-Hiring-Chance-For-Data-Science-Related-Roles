select * from jobs;

select * from jobpostings;

select * from skill_categories;

select * from skills_table;

select * from job_skill_mapping;

-- sql queries

-- q1. DONE

WITH SkillCount AS (
    SELECT st.skill,
    COUNT(jsm.jobid) AS job_count
    FROM job_skill_mapping jsm
    JOIN skills_table st ON jsm.skill_id = st.skill_id
    GROUP BY st.skill
)
SELECT skill, job_count
FROM SkillCount
ORDER BY job_count DESC
LIMIT 20;


WITH SkillCount AS (
    SELECT sc.skill_category, st.skill,
    COUNT(jsm.jobid) AS job_count
    FROM job_skill_mapping jsm
    JOIN skills_table st ON jsm.skill_id = st.skill_id
    JOIN skill_categories sc ON st.skill_id = sc.skill_id
    GROUP BY sc.skill_category, st.skill
),
RankedSkills AS (
    SELECT skill_category, skill, job_count,
        RANK() OVER (PARTITION BY skill_category ORDER BY job_count DESC) AS rank
    FROM SkillCount
)
SELECT skill_category, skill, job_count
FROM RankedSkills
WHERE rank <= 10
ORDER BY skill_category, rank;

-- q2. DONE

SELECT job_title_short, salary_year_avg FROM jobpostings;

SELECT sc.skill_category, st.skill, jp.salary_year_avg
FROM job_skill_mapping jsm
JOIN skills_table st ON jsm.skill_id = st.skill_id
JOIN skill_categories sc ON st.skill_id = sc.skill_id
JOIN jobpostings jp ON jsm.jobid = jp.jobid;


WITH SkillSalaries AS (
	SELECT sc.skill_category, s.skill, jp.salary_year_avg
	FROM job_skill_mapping jsm
	JOIN skills_table s ON jsm.skill_id = s.skill_id
	JOIN skill_categories sc ON s.skill_id = sc.skill_id
	JOIN jobpostings jp ON jsm.jobid = jp.jobid
),
MedianSalaries AS (
    SELECT skill_category, skill,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary_year_avg) AS median_salary
    FROM SkillSalaries
    GROUP BY skill_category, skill
),
RankedSkills AS (
    SELECT skill_category,skill,median_salary,
        RANK() OVER (PARTITION BY skill_category ORDER BY median_salary DESC) AS rank
    FROM MedianSalaries
)
SELECT skill_category, skill, median_salary
FROM RankedSkills
WHERE rank <= 20
ORDER BY skill_category, rank;


-- q3. DONE

SELECT industry FROM jobpostings;

-- q4. DONE

SELECT job_location, salary_year_avg FROM jobpostings
WHERE job_country = 'United States' AND job_title_short = 'Data Scientist';

-- q5. DONE

SELECT job_title_short, job_location, search_location, salary_year_avg FROM jobpostings
WHERE job_work_from_home = FALSE AND job_country = 'United States' AND job_schedule_type = 'Full-time';
