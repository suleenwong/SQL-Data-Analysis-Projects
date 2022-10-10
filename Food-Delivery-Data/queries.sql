-- Revenue per customer
SELECT SUM(meals.meal_price*orders.order_quantity) AS revenue
  FROM meals
  JOIN orders ON meals.meal_id = orders.meal_id
-- Keep only the records of customer ID 15
WHERE user_id = 15;

-- Revenue per week
SELECT DATE_TRUNC('week', order_date) :: DATE AS delivr_week,
       -- Calculate revenue
       SUM(meal_price*order_quantity) AS revenue
  FROM meals
  JOIN orders ON meals.meal_id = orders.meal_id
-- Keep only the records in June 2018
WHERE DATE_TRUNC('month', order_date) = '2018-06-01'
GROUP BY delivr_week
ORDER BY delivr_week ASC;

-- Top meals by cost
SELECT
  -- Calculate cost per meal ID
  meals.meal_id,
  SUM(meals.meal_cost*stock.stocked_quantity) AS cost
FROM meals
JOIN stock ON meals.meal_id = stock.meal_id
GROUP BY meals.meal_id
ORDER BY cost DESC
-- Only the top 5 meal IDs by purchase cost
LIMIT 5;

-- Calculate cost per month
SELECT
  -- Calculate cost
  DATE_TRUNC('month', stocking_date)::DATE AS delivr_month,
  SUM(meals.meal_cost*stock.stocked_quantity) AS cost
FROM meals
JOIN stock ON meals.meal_id = stock.meal_id
GROUP BY delivr_month
ORDER BY delivr_month ASC;


-- Profit per eatery
WITH revenue AS (
  -- Calculate revenue per eatery
  SELECT eatery,
         SUM(meals.meal_price*orders.order_quantity) AS revenue
    FROM meals
    JOIN orders ON meals.meal_id = orders.meal_id
   GROUP BY eatery),

  cost AS (
  -- Calculate cost per eatery
  SELECT eatery,
         SUM(meals.meal_cost*stock.stocked_quantity) AS cost
    FROM meals
    JOIN stock ON meals.meal_id = stock.meal_id
   GROUP BY eatery)

   -- Calculate profit per eatery
   SELECT revenue.eatery,
          revenue-cost AS profit
     FROM revenue
     JOIN cost ON revenue.eatery = cost.eatery
    ORDER BY profit DESC;


-- Profit per month
-- Set up the revenue CTE
WITH revenue AS ( 
	SELECT
		DATE_TRUNC('month', order_date) :: DATE AS delivr_month,
		SUM(meal_price*order_quantity) AS revenue
	FROM meals
	JOIN orders ON meals.meal_id = orders.meal_id
	GROUP BY delivr_month),
-- Set up the cost CTE
  cost AS (
 	SELECT
		DATE_TRUNC('month', stocking_date) :: DATE AS delivr_month,
		SUM(meal_cost*stocked_quantity) AS cost
	FROM meals
    JOIN stock ON meals.meal_id = stock.meal_id
	GROUP BY delivr_month)
-- Calculate profit by joining the CTEs
SELECT
	revenue.delivr_month,
	revenue.revenue - cost.cost AS profit
FROM revenue
JOIN cost ON revenue.delivr_month = cost.delivr_month
ORDER BY revenue.delivr_month ASC;


-- Registrations by month
SELECT user_id,
       MIN(order_date) AS reg_date
FROM orders
GROUP BY user_id
ORDER BY user_id ASC;


-- Monthly active users (MAU)
SELECT
  -- Truncate the order date to the nearest month
  DATE_TRUNC('month', order_date) :: DATE AS delivr_month,
  -- Count the unique user IDs
  COUNT(DISTINCT user_id) AS mau
FROM orders
GROUP BY delivr_month
-- Order by month
ORDER BY delivr_month ASC;


-- Running total of registrations
WITH reg_dates AS (
  SELECT
    user_id,
    MIN(order_date) AS reg_date
  FROM orders
  GROUP BY user_id),

  regs AS (
  SELECT
    DATE_TRUNC('month', reg_date) :: DATE AS delivr_month,
    COUNT(DISTINCT user_id) AS regs
  FROM reg_dates
  GROUP BY delivr_month)

SELECT
  -- Calculate the registrations running total by month
  delivr_month,
  SUM(regs) OVER (ORDER BY delivr_month ASC) AS regs_rt
FROM regs
-- Order by month in ascending order
ORDER BY delivr_month ASC; 


-- CTE of MAU
WITH mau AS (
  SELECT
    DATE_TRUNC('month', order_date) :: DATE AS delivr_month,
    COUNT(DISTINCT user_id) AS mau
  FROM orders
  GROUP BY delivr_month)

SELECT
  -- Select the month and the MAU
  delivr_month,
  mau,
  COALESCE(
    LAG(mau) OVER (ORDER BY delivr_month ASC),
  0) AS last_mau
FROM mau
-- Ordered by month in ascending order
ORDER BY delivr_month ASC;


-- CTE of MAU and previous month's MAU for every month
WITH mau AS (
  SELECT DATE_TRUNC('month', order_date) :: DATE AS delivr_month,
         COUNT(DISTINCT user_id) AS mau
  FROM orders
  GROUP BY delivr_month),

  mau_with_lag AS (
  SELECT delivr_month,
         mau,
         -- Fetch the previous month's MAU
         COALESCE(LAG(mau) OVER (ORDER BY delivr_month ASC), 0) AS last_mau
  FROM mau)
-- Calculate each month's delta of MAUs
SELECT delivr_month,
       (mau - last_mau) AS mau_delta
FROM mau_with_lag
-- Ordered by month in ascending order
ORDER BY delivr_month;


-- CTE of MAU and previous month's MAU for every month
WITH mau AS (
  SELECT
    DATE_TRUNC('month', order_date) :: DATE AS delivr_month,
    COUNT(DISTINCT user_id) AS mau
  FROM orders
  GROUP BY delivr_month),

  mau_with_lag AS (
  SELECT
    delivr_month,
    mau,
    GREATEST(
      LAG(mau) OVER (ORDER BY delivr_month ASC),
    1) AS last_mau
  FROM mau)
-- Calculate the month to month MAU growth rates
SELECT delivr_month,
       ROUND((mau - last_mau) :: NUMERIC / last_mau,2) AS growth
FROM mau_with_lag
-- Order by month in ascending order
ORDER BY delivr_month;


-- CTE for number of orders of current and previous month
WITH orders AS (
  SELECT DATE_TRUNC('month', order_date) :: DATE AS delivr_month,
         --  Number of unique order IDs
         COUNT(DISTINCT order_id) AS orders
  FROM orders
  GROUP BY delivr_month),

orders_with_lag AS (
  SELECT delivr_month,
         -- Current and previous orders for each month
         orders,
         COALESCE(LAG(orders) OVER (ORDER BY delivr_month ASC),1) AS last_orders
  FROM orders
  )
-- Month to month order growth rate
SELECT delivr_month,
       ROUND((orders - last_orders) :: NUMERIC / last_orders,2) AS growth
FROM orders_with_lag
ORDER BY delivr_month ASC;


-- CTE of monthly user activity
WITH user_monthly_activity AS (
    SELECT DISTINCT DATE_TRUNC('month', order_date) :: DATE AS delivr_month,
           user_id
    FROM orders
)
-- Retention rates for each month
SELECT previous.delivr_month,
    ROUND(COUNT(DISTINCT current.user_id) :: NUMERIC / GREATEST(COUNT(DISTINCT previous.user_id), 1), 2) AS retention_rate
FROM user_monthly_activity AS previous
LEFT JOIN user_monthly_activity AS current
-- Join on user and month
ON previous.user_id = current.user_id
AND previous.delivr_month = (current.delivr_month - INTERVAL'1 month')
GROUP BY previous.delivr_month
ORDER BY previous.delivr_month ASC;


-- Revenue for each user ID
SELECT user_id,
       SUM(meal_price*order_quantity) AS revenue
FROM meals AS m
JOIN orders AS o 
    ON m.meal_id = o.meal_id
GROUP BY user_id;


-- ARPU (average revenue per user)
-- kpi CTE
WITH kpi AS (
  SELECT user_id,
         SUM(m.meal_price * o.order_quantity) AS revenue
  FROM meals AS m
  JOIN orders AS o ON m.meal_id = o.meal_id
  GROUP BY user_id)
-- Calculate ARPU (average revenue per user)
SELECT ROUND(AVG(revenue) :: NUMERIC, 2) AS arpu
FROM kpi;


-- Average orders per user
-- kpi CTE
WITH kpi AS (
  SELECT
    -- Number of distinct orders and users
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT user_id) AS users
  FROM orders)
-- Calculate the average orders per user
SELECT ROUND(orders :: NUMERIC / users, 2) AS arpu
FROM kpi;


-- CTE of revenue
WITH user_revenues AS (
    SELECT user_id,
           SUM(meal_price*order_quantity) AS revenue
    FROM meals AS m
    JOIN orders AS o 
        ON m.meal_id = o.meal_id
    GROUP BY user_id)
-- Return the frequency table of revenue by user
SELECT ROUND(revenue :: NUMERIC, -2) AS revenue_100,
       COUNT(DISTINCT user_id) AS users
FROM user_revenues
GROUP BY revenue_100
ORDER BY revenue_100 ASC;


-- CTE of user orders
WITH user_orders AS (
    SELECT user_id,
           COUNT(DISTINCT order_id) AS orders
  FROM orders
  GROUP BY user_id)
-- Return the frequency table of orders by user
SELECT orders, 
       COUNT(DISTINCT user_id) AS users
FROM user_orders
GROUP BY orders
ORDER BY orders ASC;


-- CTE of revenue for each user
WITH user_revenues AS (
  SELECT
    -- Select the user IDs and the revenues they generate
    user_id,
    SUM(meal_price*order_quantity) AS revenue
  FROM meals AS m
  JOIN orders AS o 
    ON m.meal_id = o.meal_id
  GROUP BY user_id)
-- Bucketing users by revenue
SELECT
    CASE WHEN revenue < 150 THEN 'Low-revenue users'
         WHEN revenue < 300 THEN 'Mid-revenue users'
         ELSE 'High-revenue users'
    END AS revenue_group,
    COUNT(DISTINCT user_id) AS users
FROM user_revenues
GROUP BY revenue_group;


-- Store each user's count of orders in a CTE named user_orders
WITH user_orders AS (
  SELECT
    user_id,
    COUNT(DISTINCT order_id) AS orders
  FROM orders
  GROUP BY user_id)
-- Write the conditions for the three buckets
SELECT
  CASE
    WHEN orders < 8 THEN 'Low-orders users'
    WHEN orders < 15 THEN 'Mid-orders users'
    ELSE 'High-orders users'
  END AS order_group,
  -- Count the distinct users in each bucket
  COUNT(DISTINCT user_id) AS users
FROM user_orders
GROUP BY order_group;

-- CTE with user IDs and their revenues
 WITH user_revenues AS (
  SELECT
    user_id,
    SUM(meal_price*order_quantity) AS revenue
  FROM meals AS m
  JOIN orders AS o ON m.meal_id = o.meal_id
  GROUP BY user_id)

-- Calculate the first, second, and third quartile
SELECT
  ROUND(
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue ASC) :: NUMERIC,
  2) AS revenue_p25,
  ROUND(
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY revenue ASC) :: NUMERIC,
  2) AS revenue_p50,
  ROUND(
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue ASC) :: NUMERIC,
  2) AS revenue_p75,
  -- Calculate the average
  ROUND(AVG(revenue) :: NUMERIC, 2) AS avg_revenue
FROM user_revenues;


-- Create a CTE named user_revenues
WITH user_revenues AS (
  SELECT
    -- Select user_id and calculate revenue by user 
    user_id,
    SUM(m.meal_price * o.order_quantity) AS revenue
  FROM meals AS m
  JOIN orders AS o ON m.meal_id = o.meal_id
  GROUP BY user_id)
  -- Calculate the first and third revenue quartiles
SELECT
  ROUND(
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue ASC) :: NUMERIC,
  2) AS revenue_p25,
  ROUND(
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue ASC) :: NUMERIC,
  2) AS revenue_p75
FROM user_revenues;


-- CTE of user_id and revenue by user 
WITH user_revenues AS (
  SELECT
    user_id,
    SUM(m.meal_price * o.order_quantity) AS revenue
  FROM meals AS m
  JOIN orders AS o ON m.meal_id = o.meal_id
  GROUP BY user_id),
-- Calculate the first and third revenue quartiles
  quartiles AS (
  SELECT
    ROUND(
      PERCENTILE_CONT(0.25) WITHIN GROUP
      (ORDER BY revenue ASC) :: NUMERIC,
    2) AS revenue_p25,
    ROUND(
      PERCENTILE_CONT(0.75) WITHIN GROUP
      (ORDER BY revenue ASC) :: NUMERIC,
    2) AS revenue_p75
  FROM user_revenues)
-- Count the number of users in the IQR
SELECT
  COUNT(DISTINCT user_id) AS users
FROM user_revenues
CROSS JOIN quartiles
-- Only keep users with revenues in the IQR range
WHERE revenue :: NUMERIC >= revenue_p25
  AND revenue :: NUMERIC <= revenue_p75;


-- Select and format order date 
 SELECT DISTINCT
  order_date,
  TO_CHAR(order_date, 'FMDay DD, FMMonth YYYY') AS format_order_date
FROM orders
ORDER BY order_date ASC
LIMIT 3; 


-- Set up the user_count_orders CTE
WITH user_count_orders AS (
    SELECT user_id,
           COUNT(DISTINCT order_id) AS count_orders
    FROM orders
    -- Only keep orders in August 2018
    WHERE DATE_TRUNC('month', order_date) = '2018-08-01'
    GROUP BY user_id)
-- Select user ID, and rank user ID by count_orders
SELECT
  user_id,
  RANK() OVER (ORDER BY count_orders DESC) AS count_orders_rank
FROM user_count_orders
ORDER BY count_orders_rank ASC
-- Limit the user IDs selected to 3
LIMIT 3;

-- Import tablefunc
CREATE EXTENSION IF NOT EXISTS tablefunc;
-- Create pivot table
SELECT * FROM CROSSTAB($$
  SELECT
    user_id,
    DATE_TRUNC('month', order_date) :: DATE AS delivr_month,
    SUM(meal_price * order_quantity) :: FLOAT AS revenue
  FROM meals
  JOIN orders ON meals.meal_id = orders.meal_id
 WHERE user_id IN (0, 1, 2, 3, 4)
   AND order_date < '2018-09-01'
 GROUP BY user_id, delivr_month
 ORDER BY user_id, delivr_month;
$$)
-- Select user ID and the months from June to August 2018
AS ct (user_id INT,
       "2018-06-01" FLOAT,
       "2018-07-01" FLOAT,
       "2018-08-01" FLOAT)
ORDER BY user_id ASC;


-- Select eatery and calculate total cost
SELECT
  eatery,
  DATE_TRUNC('month', stocking_date) :: DATE AS delivr_month,
  SUM(meal_cost*stocked_quantity) :: FLOAT AS cost
FROM meals
JOIN stock ON meals.meal_id = stock.meal_id
-- Keep only the records after October 2018
WHERE stocking_date > '2018-10-31'
GROUP BY eatery, delivr_month
ORDER BY eatery, delivr_month;


-- Import tablefunc
CREATE EXTENSION IF NOT EXISTS tablefunc;

-- Select eatery and calculate total cost
SELECT * FROM CROSSTAB($$
  SELECT
    eatery,
    DATE_TRUNC('month', stocking_date) :: DATE AS delivr_month,
    SUM(meal_cost * stocked_quantity) :: FLOAT AS cost
  FROM meals
  JOIN stock ON meals.meal_id = stock.meal_id
  -- Keep only the records after October 2018
  WHERE DATE_TRUNC('month', stocking_date) > '2018-10-01'
  GROUP BY eatery, delivr_month
  ORDER BY eatery, delivr_month;
$$)
-- Select the eatery and November and December 2018 as columns
AS ct (eatery TEXT,
       "2018-11-01" FLOAT,
       "2018-12-01" FLOAT)
ORDER BY eatery ASC;


-- unique ordering users by eatery and by quarter.
SELECT
  eatery,
  TO_CHAR(order_date, '"Q"Q YYYY') AS delivr_quarter,
  COUNT(DISTINCT user_id) AS users
FROM meals
JOIN orders ON meals.meal_id = orders.meal_id
GROUP BY eatery, delivr_quarter
ORDER BY delivr_quarter, users;


-- CTE of eatery users
WITH eatery_users AS  (
  SELECT
    eatery,
    TO_CHAR(order_date, '"Q"Q YYYY') AS delivr_quarter,
    COUNT(DISTINCT user_id) AS users
  FROM meals
  JOIN orders ON meals.meal_id = orders.meal_id
  GROUP BY eatery, delivr_quarter
  ORDER BY delivr_quarter, users)

-- Rank rows, partition by quarter and order by users  
SELECT
  eatery,
  delivr_quarter,
  RANK() OVER
    (PARTITION BY delivr_quarter
     ORDER BY users DESC) :: INT AS users_rank
FROM eatery_users
ORDER BY delivr_quarter, users_rank;


-- Create pivot table of eatery ranks for last three quarters of 2018
-- Import tablefunc
CREATE EXTENSION IF NOT EXISTS tablefunc;
-- Pivot the previous query by quarter
SELECT * FROM CROSSTAB($$
  WITH eatery_users AS  (
    SELECT
      eatery,
      TO_CHAR(order_date, '"Q"Q YYYY') AS delivr_quarter,
      COUNT(DISTINCT user_id) AS users
    FROM meals
    JOIN orders ON meals.meal_id = orders.meal_id
    GROUP BY eatery, delivr_quarter
    ORDER BY delivr_quarter, users)
  -- Rank rows, partition by quarter and order by users
  SELECT
    eatery,
    delivr_quarter,
    RANK() OVER
      (PARTITION BY delivr_quarter
       ORDER BY users DESC) :: INT AS users_rank
  FROM eatery_users
  ORDER BY eatery, delivr_quarter;
$$)
-- Select the columns of the pivoted table
AS  ct (eatery TEXT,
        "Q2 2018" INT,
        "Q3 2018" INT,
        "Q4 2018" INT)
ORDER BY "Q4 2018";