/*
Project: Analyzing American Baby Name Trends 

Skills used: Joins, Case statments, CTE's, Windows Functions, 
Aggregate Functions, Converting Data Types
*/

-- Looking for baby names that have been used for all 101 years 
-- in the data set and the total number of babies with that name
SELECT first_name, SUM(num) AS total_num
FROM baby_names
GROUP BY first_name
HAVING COUNT(first_name) = 101
ORDER BY SUM(num) DESC;


-- Classify first names as 'Classic', 'Semi-classic', 'Semi-trendy', or 'Trendy'
-- and the total number of babies with that name
SELECT first_name, SUM(num) AS total_num, 
CASE WHEN COUNT(first_name) > 80 THEN 'Classic'
     WHEN COUNT(first_name) > 50 THEN 'Semi-classic'
     WHEN COUNT(first_name) > 20 THEN 'Semi-trendy'
     ELSE 'Trendy' END AS popularity_type 
FROM baby_names
GROUP BY first_name
ORDER BY first_name;


-- RANK top 10 female names by the total number of babies with that name
SELECT first_name, SUM(num) AS total_num,
RANK() OVER (ORDER BY SUM(num) DESC) AS name_rank
FROM baby_names
WHERE sex = 'F'
GROUP BY first_name
LIMIT 10;


-- A friend would like help choosing a name for her baby girl. 
-- She doesn't like any of the top-ranked names in the previous query.
-- She wants traditionally female name ending in the letter 'a' and she
-- is also looking for a name that has been popular in the years since 2015.
SELECT first_name
FROM baby_names
WHERE sex = 'F'
    AND year > 2015
    AND first_name LIKE '%a'
GROUP BY first_name
ORDER BY SUM(num) DESC;


-- Based on the previous query, we can see that Olivia is the most popular 
-- female name ending in 'A' since 2015. When did the name Olivia become so popular?
-- Select year, first_name, num of Olivias in that year, and cumulative_olivias
-- Sum the cumulative babies who have been named Olivia up to that year; alias as cumulative_olivias
-- Filter so that only data for the name Olivia is returned.
-- Order by year from the earliest year to most recent
SELECT year, first_name, num,
SUM (num) OVER (ORDER BY year) AS cumulative_olivias
FROM baby_names
WHERE first_name = 'Olivia'
ORDER BY year;


-- Select year and maximum number of babies given any one male name in that year
-- Filter the data to include only results where sex equals 'M'
SELECT year, MAX(num) AS max_num
FROM baby_names
WHERE sex = 'M'
GROUP BY year, sex;


-- Find out what the top male name is for each year
-- Select year, first_name given to the largest number of male babies, 
-- and num of babies given that name
-- Join baby_names to the previous code as a subquery
-- Order results by year descending
SELECT m.year, b.first_name, b.num
FROM (
SELECT year, MAX(num) AS max_num
FROM baby_names
WHERE sex = 'M'
GROUP BY year, sex) AS m
INNER JOIN baby_names AS b
ON m.year = b.year AND m.max_num = b.num
ORDER BY m.year DESC;


-- Which male name has been number one for the most number of years?
-- Select first_name and a count of years it was the top name in the previous query
WITH top_male_names AS (
SELECT m.year, b.first_name, b.num
FROM (
SELECT year, MAX(num) AS max_num
FROM baby_names
WHERE sex = 'M'
GROUP BY year, sex) AS m
INNER JOIN baby_names AS b
ON m.year = b.year AND m.max_num = b.num
ORDER BY m.year DESC
)
SELECT first_name, COUNT(first_name) AS count_top_name
FROM top_male_names
GROUP BY first_name
ORDER BY COUNT(first_name) DESC;


