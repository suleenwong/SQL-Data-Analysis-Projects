-- Count total number of products
-- Count the number of non-missing entries for description, listing_price, and last_visited
-- Join info, finance, and traffic
SELECT COUNT(*) AS total_rows, 
       COUNT(description) AS count_description,
       COUNT(listing_price) AS count_listing_price,
       COUNT(last_visited) AS count_last_visited
FROM info AS i
LEFT JOIN finance AS f
ON i.product_id = f.product_id
LEFT JOIN traffic AS t
ON i.product_id = t.product_id

-- Select the brand, listing_price as an integer, and a count of all products in finance 
-- Join brands to finance on product_id
-- Filter for products with a listing_price more than zero
-- Aggregate results by brand and listing_price, and sort the results by listing_price in descending order
SELECT b.brand, f.listing_price::integer, COUNT(f.product_id)
FROM brands AS b
INNER JOIN finance AS f
ON b.product_id = f.product_id
WHERE f.listing_price > 0
GROUP BY brand, f.listing_price
ORDER BY f.listing_price DESC

-- Select the brand, a count of all products in the finance table, and total revenue
-- Create four labels for products based on their price range, aliasing as price_category
-- Join brands to finance on product_id and filter out products missing a value for brand
-- Group results by brand and price_category, sort by total_revenue
SELECT brand, COUNT(f.*), SUM(f.revenue) AS total_revenue, 
       CASE WHEN f.listing_price < 42 THEN 'Budget'
            WHEN f.listing_price >= 42 AND f.listing_price < 74 THEN 'Average'
            WHEN f.listing_price >= 74 AND f.listing_price < 129 THEN 'Expensive'
            ELSE 'Elite' END AS price_category
FROM brands AS b
INNER JOIN finance AS f
ON b.product_id = f.product_id
WHERE brand IS NOT NULL
GROUP BY brand, price_category
ORDER BY total_revenue DESC;

-- Select brand and average_discount as a percentage
-- Join brands to finance on product_id
-- Aggregate by brand
-- Filter for products without missing values for brand
SELECT b.brand, AVG(f.discount)*100 AS average_discount
FROM brands AS b
INNER JOIN finance AS f
ON b.product_id = f.product_id
WHERE b.brand IS NOT NULL
GROUP BY b.brand;

-- Calculate the correlation between reviews and revenue as review_revenue_corr
-- Join the reviews and finance tables on product_id
SELECT corr(reviews, revenue) AS review_revenue_corr
FROM reviews AS r
INNER JOIN finance AS f
ON r.product_id = f.product_id

-- Calculate description_length
-- Convert rating to a numeric data type and calculate average_rating
-- Join info to reviews on product_id and group the results by description_length
-- Filter for products without missing values for description, and sort results by description_length
SELECT TRUNC(LENGTH(description),-2) AS description_length,
       ROUND(AVG(rating::numeric),2) AS average_rating
FROM info AS i
INNER JOIN reviews AS r
ON i.product_id = r.product_id
WHERE description IS NOT NULL
GROUP BY description_length
ORDER BY description_length

-- Select brand, month from last_visited, and a count of all products in reviews aliased as num_reviews
-- Join traffic with reviews and brands on product_id
-- Group by brand and month, filtering out missing values for brand and month
-- Order the results by brand and month
SELECT b.brand, DATE_PART('MONTH', last_visited) AS month, COUNT(r.*) AS num_reviews
FROM traffic AS t
INNER JOIN reviews AS r
ON t.product_id = r.product_id
INNER JOIN brands AS b
ON t.product_id = b.product_id
WHERE b.brand IS NOT NULL 
    AND DATE_PART('MONTH', last_visited) IS NOT NULL
GROUP BY b.brand, DATE_PART('MONTH', last_visited)
ORDER BY b.brand, month

-- Create the footwear CTE, containing description and revenue
-- Filter footwear for products with a description containing %shoe%, %trainer, or %foot%
-- Also filter for products that are not missing values for description
-- Calculate the number of products and median revenue for footwear products
WITH footwear AS 
(
    SELECT i.description, f.revenue
    FROM info AS i
    INNER JOIN finance AS f
    ON i.product_id = f.product_id
    WHERE (i.description ILIKE '%shoe%' 
        OR i.description ILIKE '%trainer%'
        OR i.description ILIKE '%foot%')
    AND i.description IS NOT NULL
)
SELECT COUNT(*) AS num_footwear_products, 
       percentile_disc(0.5) WITHIN GROUP(ORDER BY revenue) AS median_footwear_revenue
FROM footwear;

-- Copy the footwear CTE from the previous task
-- Calculate the number of products in info and median revenue from finance
-- Inner join info with finance on product_id
-- Filter the selection for products with a description not in footwear
WITH footwear AS 
(
    SELECT i.description, f.revenue
    FROM info AS i
    INNER JOIN finance AS f
    ON i.product_id = f.product_id
    WHERE (i.description ILIKE '%shoe%' 
        OR i.description ILIKE '%trainer%'
        OR i.description ILIKE '%foot%')
    AND i.description IS NOT NULL
)
SELECT COUNT(i.*) AS num_clothing_products, 
       percentile_disc(0.5) WITHIN GROUP(ORDER BY revenue) AS median_clothing_revenue
FROM info AS i
INNER JOIN finance AS f
ON i.product_id = f.product_id
WHERE i.description NOT IN (SELECT description FROM footwear);