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


