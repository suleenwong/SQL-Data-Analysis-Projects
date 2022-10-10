-- Query the sport and distinct number of athletes
SELECT sport, 
       COUNT(DISTINCT athlete_id) AS athletes
FROM summer_games
GROUP BY sport
-- Include the 3 sports with the most athletes
ORDER BY athletes DESC
LIMIT 3;


-- Athletes vs events by sport
-- Query sport, events, and athletes from summer_games
SELECT 
	sport, 
    COUNT(DISTINCT event) AS events, 
    COUNT(DISTINCT athlete_id) AS athletes
FROM summer_games
GROUP BY sport;


-- Select the age of the oldest athlete for each region
SELECT region, 
       MAX(age) AS age_of_oldest_athlete
FROM athletes AS a
INNER JOIN summer_games AS s
    ON a.id = s.athlete_id
INNER JOIN countries AS c
    ON s.country_id = c.id
GROUP BY c.region;


-- Number of events for each sport
-- Select sport and events for summer sports
SELECT 
	sport, 
    COUNT(DISTINCT event) AS events
FROM summer_games
GROUP BY sport
UNION
-- Select sport and events for winter sports
SELECT 
	sport, 
    COUNT(DISTINCT event)
FROM winter_games
GROUP BY sport
-- Show the most events at the top of the report
ORDER BY events DESC;


-- Query that shows gold medals by country
SELECT 
	country, 
    SUM(gold) AS gold_medals
FROM summer_games AS s
JOIN countries AS c
ON s.country_id = c.id
GROUP BY country;


-- Pull athlete_name and gold_medals for summer games
SELECT 
	name AS athlete_name, 
    SUM(gold) AS gold_medals
FROM summer_games AS s
INNER JOIN athletes AS a
ON s.athlete_id = a.id
GROUP BY athlete_name
-- Filter for only athletes with 3 gold medals or more
HAVING gold_medals >= 3
-- Sort to show the most gold medals at the top
ORDER BY gold_medals DESC;

-- Show number of events by season and country
-- Query season, country, and events for all summer events
SELECT 
	'summer' AS season, 
    country, 
    COUNT(DISTINCT event) AS events
FROM summer_games AS s
INNER JOIN countries AS c
ON s.country_id = c.id
GROUP BY country, season
-- Combine the queries
UNION ALL
-- Query season, country, and events for all winter events
SELECT 
	'winter' AS season, 
    country, 
    COUNT(DISTINCT event) AS events
FROM winter_games AS w
INNER JOIN countries AS c
ON w.country_id = c.id
GROUP BY country, season
-- Sort the results to show most events at the top
ORDER BY events DESC;


-- Same query as above but the UNION as a subquery
-- Add outer layer to pull season, country and unique events
SELECT 
	season, 
    country, 
    COUNT(DISTINCT event) AS events
FROM
    -- Pull season, country_id, and event for both seasons
    (SELECT 
     	'summer' AS season, 
     	country_id, 
     	event
    FROM summer_games
    UNION ALL
    SELECT 
     	'winter' AS season, 
     	country_id, 
     	event
    FROM winter_games) AS subquery
INNER JOIN countries AS c
ON subquery.country_id = c.id
-- Group by any unaggregated fields
GROUP BY country, season
-- Order to show most events at the top
ORDER BY events DESC;


-- Categorize athletes by height and gender
SELECT 
	name,
    -- Output 'Tall Female', 'Tall Male', or 'Other'
	CASE WHEN height >= 175 AND gender = 'F' THEN 'Tall Female'
    WHEN height >= 190 AND gender = 'M' THEN 'Tall Male'
    ELSE 'Other' END AS segment
FROM athletes;


-- Pull in sport, bmi_bucket, and athletes
SELECT 
	sport,
    CASE WHEN weight/height^2*100 <.25 THEN '<.25'
    WHEN weight/height^2*100 <=.30 THEN '.25-.30'
    WHEN weight/height^2*100 >.30 THEN '>.30'
    ELSE 'no weight recorded' END AS bmi_bucket,
    COUNT(DISTINCT athlete_id) AS athletes
FROM summer_games AS s
INNER JOIN athletes AS a
ON s.athlete_id = a.id
GROUP BY sport, bmi_bucket
ORDER BY sport, athletes DESC;


-- Pull summer bronze_medals, silver_medals, and gold_medals
SELECT 
	SUM(bronze) AS bronze_medals, 
    SUM(silver) AS silver_medals, 
    SUM(gold) AS gold_medals
FROM summer_games
-- Add the WHERE statement below
WHERE athlete_id IN
    -- Create subquery list for athlete_ids age 16 or below    
    (SELECT id
     FROM athletes
     WHERE age <= 16);


-- Pull event and unique athletes from summer_games 
SELECT 
    event,
    -- Add the gender field below
    CASE WHEN event LIKE '%Women%' THEN 'female' 
    ELSE 'male' END AS gender,
    COUNT(DISTINCT athlete_id) AS athletes
FROM summer_games
-- Only include countries that won a nobel prize
WHERE country_id IN 
	(SELECT country_id 
    FROM country_stats 
    WHERE nobel_prize_winners > 0)
GROUP BY event
-- Add the second query below and combine with a UNION
UNION ALL
SELECT 
	event,
    CASE WHEN event LIKE '%Women%' THEN 'female' 
    ELSE 'male' END AS gender,
    COUNT(DISTINCT athlete_id) AS athletes
FROM winter_games
WHERE country_id IN 
	(SELECT country_id 
    FROM country_stats 
    WHERE nobel_prize_winners > 0)
GROUP BY event
-- Order and limit the final output
ORDER BY athletes DESC
LIMIT 10;     