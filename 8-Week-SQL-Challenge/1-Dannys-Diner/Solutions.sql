/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- 1. What is the total amount each customer spent at the restaurant?
SET search_path = dannys_diner;
SELECT 
    customer_id, 
    SUM(price) AS total_amount
FROM sales
JOIN menu
	ON sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SET
  search_path = dannys_diner;
SELECT customer_id,
	COUNT(DISTINCT order_date)
FROM sales
GROUP BY customer_id
ORDER BY customer_id

-- 3. What was the first item from the menu purchased by each customer?
SET search_path = dannys_diner;
WITH orders_ranked AS (
  SELECT 
  	customer_id, 
  	order_date, 
  	sales.product_id,
  	menu.product_name,
	ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_rank
  FROM sales
  JOIN menu
      ON sales.product_id = menu.product_id
  GROUP BY customer_id, order_date, sales.product_id, menu.product_name
)
SELECT 
    customer_id, 
    product_name, 
    order_date
FROM orders_ranked
WHERE order_rank = 1
ORDER BY customer_id, order_date;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SET search_path = dannys_diner;
SELECT 
	menu.product_name,
    COUNT(*) AS num_purchases
FROM sales
JOIN menu
	ON sales.product_id = menu.product_id
GROUP BY sales.product_id, menu.product_name
ORDER BY num_purchases DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
SET search_path = dannys_diner;
WITH num_orders_customer AS (
  SELECT 
      sales.customer_id,
      menu.product_name,
      COUNT(*) AS num_orders,
  	  RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS item_rank
  FROM sales
  JOIN menu
      ON sales.product_id = menu.product_id
  GROUP BY sales.customer_id, menu.product_name
  ORDER BY sales.customer_id, num_orders DESC
)
SELECT customer_id,
	product_name,
    num_orders
FROM num_orders_customer
WHERE item_rank = 1
ORDER BY customer_id;

-- 6. Which item was purchased first by the customer after they became a member?
SET search_path = dannys_diner;
WITH member_orders AS (
  SELECT 
      sales.customer_id, 
      menu.product_name,
      sales.order_date,
      RANK() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date) AS order_rank
  FROM sales
  JOIN members
      ON sales.customer_id = members.customer_id
      AND sales.order_date >= members.join_date
  JOIN menu
      ON sales.product_id = menu.product_id
)
SELECT customer_id, product_name
FROM member_orders
WHERE order_rank = 1;

-- 7. Which item was purchased just before the customer became a member?
SET search_path = dannys_diner;
WITH non_member_orders AS (
  SELECT 
        sales.customer_id, 
        menu.product_name,
        sales.order_date,
        RANK() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date DESC) AS order_rank
    FROM sales
    JOIN members
        ON sales.customer_id = members.customer_id
        AND sales.order_date < members.join_date
    JOIN menu
        ON sales.product_id = menu.product_id
)
SELECT customer_id, product_name
FROM non_member_orders
WHERE order_rank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SET search_path = dannys_diner;
WITH non_member_orders AS (
  SELECT 
        sales.customer_id, 
        menu.product_name,
        sales.order_date,
		menu.price
  FROM sales
  JOIN members
        ON sales.customer_id = members.customer_id
        AND sales.order_date < members.join_date
  JOIN menu
        ON sales.product_id = menu.product_id
)
SELECT customer_id, SUM(price) AS total
FROM non_member_orders
GROUP BY customer_id
ORDER BY customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SET search_path = dannys_diner;
WITH customer_points AS (
SELECT 
    sales.customer_id, 
    menu.product_name, 
    menu.price,
	CASE WHEN menu.product_name = 'sushi' THEN menu.price*2*10
        ELSE menu.price*10 END AS points
FROM sales
JOIN menu
	ON sales.product_id = menu.product_id
)
SELECT 
    customer_id, 
    SUM(points)
FROM customer_points
GROUP BY customer_id
ORDER BY customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SET search_path = dannys_diner;
WITH customer_points AS (
SELECT 
	sales.customer_id,
    sales.order_date,
    members.join_date,
	menu.product_name,
    menu.price,
    CASE WHEN sales.order_date >= members.join_date AND
    	sales.order_date < members.join_date + INTERVAL '7 days' THEN 1
         ELSE 0 END AS first_week,
    CASE WHEN menu.product_name = 'sushi' THEN menu.price*2*10
         ELSE menu.price*10 END AS points
FROM sales
JOIN members
	ON sales.customer_id = members.customer_id
JOIN menu
	ON sales.product_id = menu.product_id
ORDER BY sales.customer_id, sales.order_date
)
SELECT 
    customer_id,
	SUM(CASE WHEN first_week = 1 AND product_name <> 'sushi' THEN points*2 ELSE points END) AS final_points
FROM customer_points   
WHERE DATE_PART('month', order_date) = 1
GROUP BY customer_id
