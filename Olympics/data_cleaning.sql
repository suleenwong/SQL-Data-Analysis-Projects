-- Pull column_name & data_type from the columns table
SELECT 
	column_name,
    data_type
FROM information_schema.columns
-- Filter for the table 'country_stats'
WHERE table_name = 'country_stats';

-- Fix the error by making both columns integers
SELECT 
	s.country_id, 
    COUNT(DISTINCT s.athlete_id) AS summer_athletes, 
    COUNT(DISTINCT w.athlete_id) AS winter_athletes
FROM summer_games AS s
JOIN winter_games_str AS w
ON s.country_id ::INT = w.country_id :: INT
GROUP BY s.country_id;

-- Pull decade, decade_truncate, and the world's gdp
SELECT 
	year,
    DATE_PART('decade', year :: DATE) AS decade,
    DATE_TRUNC('decade', year :: DATE) AS decade_truncated,
    SUM(gdp) AS world_gdp
FROM country_stats
-- Group and order by year in descending order
GROUP BY year
ORDER BY year DESC;


-- DATA CLEANING
-- Pull event and unique athletes from summer_games_messy 
SELECT 
    -- Remove dashes from all event values
    REPLACE(TRIM(event),'-','') AS event_fixed, 
    COUNT(DISTINCT athlete_id) AS athletes
FROM summer_games_messy
-- Update the group by accordingly
GROUP BY event_fixed;

-- Show total gold_medals by country
SELECT 
	country, 
    SUM(gold) AS gold_medals
FROM winter_games AS w
JOIN countries AS c
ON w.country_id = c.id
GROUP BY country
HAVING SUM(gold) IS NOT NULL
-- Order by gold_medals in descending order
ORDER BY gold_medals DESC;

-- Pull events and golds by athlete_id for summer events
SELECT 
    athlete_id, 
    -- Replace all null gold values with 0
    AVG(COALESCE(gold,0)) AS avg_golds,
    COUNT(event) AS total_events, 
    SUM(gold) AS gold_medals
FROM summer_games
GROUP BY athlete_id
-- Order by total_events descending and athlete_id ascending
ORDER BY total_events DESC, athlete_id;

-- Calculate the total gold_medals 
SELECT SUM(gold_medals) AS gold_medals
FROM
	(SELECT 
     	w.country_id, 
     	SUM(gold) AS gold_medals, 
     	AVG(gdp) AS avg_gdp
    FROM winter_games AS w
    JOIN country_stats AS c
    -- Update the subquery to join on a second field
    ON c.country_id = w.country_id AND w.year :: DATE = c.year :: DATE
    GROUP BY w.country_id) AS subquery;


-- Countries with high medal rates
SELECT 
	c.country, 
    -- Add the three medal fields using one sum function
	SUM(COALESCE(gold,0)+COALESCE(silver,0)+COALESCE(bronze,0)) AS medals
FROM summer_games AS s
JOIN countries AS c
ON s.country_id = c.id
GROUP BY c.country
ORDER BY medals DESC;

-- Medals per population in millions
SELECT 
	-- Clean the country field to only show country_code
    LEFT(REPLACE(upper(LTRIM(c.country)),'.',''),3) AS country_code,
    -- Pull in pop_in_millions and medals_per_million 
	pop_in_millions,
    -- Add the three medal fields using one sum function
	SUM(COALESCE(bronze,0) + COALESCE(silver,0) + COALESCE(gold,0)) AS medals,
	SUM(COALESCE(bronze,0) + COALESCE(silver,0) + COALESCE(gold,0)) / CAST(cs.pop_in_millions AS float) AS medals_per_million
FROM summer_games AS s
INNER JOIN countries AS c 
ON s.country_id = c.id
-- Update the newest join statement to remove duplication
INNER JOIN country_stats AS cs 
ON s.country_id = cs.country_id AND s.year = CAST(cs.year AS date)
-- Filter out null populations
WHERE pop_in_millions IS NOT NULL
GROUP BY c.country, pop_in_millions
-- Keep only the top 25 medals_per_million rows
ORDER BY medals_per_million DESC
LIMIT 25;


-- Pull in avg_total_golds by region
SELECT 
	region,
    AVG(total_golds) AS avg_total_golds
FROM
  (SELECT 
      region, 
      country_id, 
      SUM(gold) AS total_golds
  FROM summer_games_clean AS s
  INNER JOIN countries AS c
  ON s.country_id = c.id
  -- Alias the subquery
  GROUP BY region, country_id) AS subquery
GROUP BY region
-- Order by avg_total_golds in descending order
ORDER BY avg_total_golds DESC;


-- Most decorated athlete per region
-- Query region, athlete name, and total_golds
SELECT 
	region,
    athlete_name,
    total_golds
FROM
    (SELECT 
		region, 
        name AS athlete_name, 
        SUM(gold) AS total_golds,
        -- Assign a regional rank to each athlete
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY SUM(gold) DESC) AS row_num
    FROM summer_games_clean AS s
    INNER JOIN athletes AS a
        ON a.id = s.athlete_id
    INNER JOIN countries AS c
        ON s.country_id = c.id
    -- Alias as subquery
    GROUP BY region, athlete_name) AS subquery
-- Filter for only the top athlete per region
WHERE row_num = 1;


-- Percent of gdp per country
-- Pull country_gdp by region and country
SELECT 
	region,
    country,
	SUM(gdp) AS country_gdp,
    -- Calculate the global gdp
    SUM(SUM(gdp)) OVER () AS global_gdp,
    -- Calculate percent of global gdp
    SUM(gdp) / SUM(SUM(gdp)) OVER () AS perc_global_gdp,
    -- Calculate percent of gdp relative to its region
    SUM(gdp) / SUM(SUM(gdp)) OVER (PARTITION BY region) AS perc_region_gdp
FROM country_stats AS cs
JOIN countries AS c
ON cs.country_id = c.id
-- Filter out null gdp values
WHERE gdp IS NOT NULL
GROUP BY region, country
-- Show the highest country_gdp at the top
ORDER BY country_gdp DESC;


-- GDP per capita performance index
SELECT 
    region,
    country,
    SUM(gdp) / SUM(pop_in_millions) AS gdp_per_million,
    -- Output the worlds gdp_per_million
    SUM(SUM(gdp)) OVER () / SUM(SUM(pop_in_millions)) OVER () AS gdp_per_million_total,
    -- Build the performance_index in the 3 lines below
    (SUM(gdp) / SUM(pop_in_millions))
    /
    (SUM(SUM(gdp)) OVER () / SUM(SUM(pop_in_millions)) OVER ()) AS performance_index
-- Pull from country_stats_clean
FROM country_stats_clean AS cs
JOIN countries AS c 
ON cs.country_id = c.id
-- Filter for 2016 and remove null gdp values
WHERE year = '2016-01-01' AND gdp IS NOT NULL
GROUP BY region, country
-- Show highest gdp_per_million at the top
ORDER BY gdp_per_million DESC;


-- Month-over-month comparison
SELECT
	-- Pull month and country_id
	DATE_PART('month',date) AS month,
	country_id,
    -- Pull in current month views
    SUM(views) AS month_views,
    -- Pull in last month views
    LAG(SUM(views),1) OVER (PARTITION BY country_id ORDER BY DATE_PART('month', date)) AS previous_month_views,
    -- Calculate the percent change
    SUM(views)/LAG(SUM(views)) OVER (PARTITION BY country_id ORDER BY DATE_PART('month', date))-1 AS perc_change
FROM web_data
WHERE date <= '2018-05-31'
GROUP BY month, country_id;


-- Week-over-week comparison
SELECT 
	-- Pull in date and weekly_avg
	date,
    weekly_avg,
    -- Output the value of weekly_avg from 7 days prior
    LAG(weekly_avg,7) OVER (ORDER BY date) AS weekly_avg_previous,
    -- Calculate percent change vs previous period
    weekly_avg/LAG(weekly_avg,7) OVER (ORDER BY date)-1 AS perc_change
FROM
  (SELECT
      -- Pull in date and daily_views
      date,
      SUM(views) AS daily_views,
      -- Calculate the rolling 7 day average
      AVG(SUM(views)) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS weekly_avg
  FROM web_data
  -- Alias as subquery
  GROUP BY date) AS subquery
-- Order by date in descending order
ORDER BY date DESC;


-- Tallest athletes and % GDP by region
SELECT
	-- Pull in region and calculate avg tallest height
    region,
    AVG(height) AS avg_tallest,
    -- Calculate region's percent of world gdp
    SUM(gdp)/SUM(SUM(gdp)) OVER () AS perc_world_gdp    
FROM countries AS c
JOIN
    (SELECT 
     	-- Pull in country_id and height
        country_id, 
        height, 
        -- Number the height of each country's athletes
        ROW_NUMBER() OVER (PARTITION BY country_id ORDER BY height DESC) AS row_num
    FROM winter_games AS w 
    JOIN athletes AS a ON w.athlete_id = a.id
    GROUP BY country_id, height
    -- Alias as subquery
    ORDER BY country_id, height DESC) AS subquery
ON c.id = subquery.country_id
-- Join to country_stats
JOIN country_stats AS cs
ON c.id = cs.country_id
-- Only include the tallest height for each country
WHERE row_num = 1
GROUP BY region;