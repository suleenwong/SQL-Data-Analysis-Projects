-- A. Pizza Metrics
-- 1. How many pizzas were ordered?
SET search_path = pizza_runner;
SELECT COUNT(*)
FROM customer_orders

-- 2. How many unique customer orders were made?
SET search_path = pizza_runner;
SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM customer_orders;

-- 3. How many successful orders were delivered by each runner?
SET search_path = pizza_runner;
SELECT runner_id,
	SUM(CASE WHEN pickup_time = 'null' 
        AND distance = 'null'
        AND duration = 'null' THEN 0
    ELSE 1 END) AS delivered
FROM runner_orders
GROUP BY runner_id
ORDER BY runner_id;

-- 4. How many of each type of pizza was delivered?
SET search_path = pizza_runner;
SELECT p.pizza_name, COUNT(*)
FROM customer_orders c
JOIN runner_orders r
	ON c.order_id = r.order_id
JOIN pizza_names p
	ON c.pizza_id = p.pizza_id
WHERE
  pickup_time != 'null'
  AND distance != 'null'
  AND duration != 'null'    
GROUP BY p.pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SET search_path = pizza_runner;
SELECT c.customer_id, p.pizza_name, COUNT(*)
FROM customer_orders c
JOIN pizza_names p
	ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id, p.pizza_name
ORDER BY c.customer_id, p.pizza_name;

-- 6. What was the maximum number of pizzas delivered in a single order?
SET search_path = pizza_runner;
SELECT c.order_id, COUNT(*) AS num_pizzas
FROM customer_orders AS c
JOIN runner_orders AS r
	ON c.order_id = r.order_id
WHERE pickup_time != 'null'
	AND distance != 'null'
    AND duration != 'null'
GROUP BY c.order_id
ORDER BY num_pizzas DESC
LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

-- 8. How many pizzas were delivered that had both exclusions and extras?

-- 9. What was the total volume of pizzas ordered for each hour of the day?

-- 10. What was the volume of orders for each day of the week?

-- B. Runner and Customer Experience
