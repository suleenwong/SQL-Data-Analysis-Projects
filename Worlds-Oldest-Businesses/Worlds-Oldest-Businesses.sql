-- Select the oldest and newest founding years from the businesses table
SELECT MIN(year_founded), MAX(year_founded)
FROM businesses;

-- Get the count of rows in businesses where the founding year was before 1000
SELECT COUNT(*)
FROM businesses
WHERE year_founded < 1000;

-- Select all columns from businesses where the founding year was before 1000
-- Arrange the results from oldest to newest
SELECT *
FROM businesses
WHERE year_founded < 1000
ORDER BY year_founded;

-- Select business name, founding year, and country code from businesses; and category from categories
-- where the founding year was before 1000, arranged from oldest to newest
SELECT b.business, b.year_founded, b.country_code, c.category
FROM businesses AS b
INNER JOIN categories AS c
ON b.category_code = c.category_code
WHERE b.year_founded < 1000
ORDER BY b.year_founded;

-- Select the category and count of category (as "n")
-- arranged by descending count, limited to 10 most common categories
SELECT c.category, COUNT(c.category) AS n
FROM businesses AS b
INNER JOIN categories AS c
ON b.category_code = c.category_code
GROUP BY c.category
ORDER BY n DESC
LIMIT 10;

-- Select the oldest founding year (as "oldest") from businesses, 
-- and continent from countries
-- for each continent, ordered from oldest to newest 
SELECT MIN(year_founded) AS oldest, continent
FROM businesses AS b
INNER JOIN countries AS c
ON b.country_code = c.country_code
GROUP BY continent
ORDER BY oldest;

-- Select the business, founding year, category, country, and continent
SELECT b.business, b.year_founded, c1.category, c2.country, c2.continent
FROM businesses AS b
INNER JOIN categories AS c1
ON b.category_code = c1.category_code
INNER JOIN countries AS c2
ON b.country_code = c2.country_code

-- Count the number of businesses in each continent and category
SELECT continent, category, COUNT(*) AS n
FROM businesses AS b
INNER JOIN categories AS c1
ON b.category_code = c1.category_code
INNER JOIN countries AS c2
ON b.country_code = c2.country_code
GROUP BY c2.continent, c1.category

-- Repeat that previous query, filtering for results having a count greater than 5
SELECT continent, category, COUNT(continent) AS n
FROM businesses AS b
INNER JOIN categories AS c1
ON b.category_code = c1.category_code
INNER JOIN countries AS c2
ON b.country_code = c2.country_code
GROUP BY c2.continent, c1.category
HAVING COUNT(continent) > 5
ORDER BY n DESC



