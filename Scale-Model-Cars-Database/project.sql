-- dimensions of each table
SELECT 'Customers' AS table_name,
	   13 AS number_of_attributes,
	   (SELECT COUNT(*) FROM customers) AS number_of_rows
UNION ALL
SELECT 'Products' AS table_name,
	   9 AS number_of_attributes,
 	   (SELECT COUNT(*) FROM products) AS number_of_rows
UNION ALL
SELECT 'ProductLines' AS table_name,
       4 AS number_of_attributes,
  	   (SELECT COUNT(*) FROM productlines) AS number_of_rows
UNION ALL
SELECT 'Orders' AS table_name,
       7 AS number_of_attributes,
  	   (SELECT COUNT(*) FROM orders) AS number_of_rows
UNION ALL
SELECT 'OrderDetails' AS table_name,
       5 AS number_of_attributes,
  	   (SELECT COUNT(*) FROM orderdetails) AS number_of_rows
UNION ALL
SELECT 'Payments' AS table_name,
       4 AS number_of_attributes,
  	   (SELECT COUNT(*) FROM payments) AS number_of_rows
UNION ALL
SELECT 'Employees' AS table_name,
       8 AS number_of_attributes,
  	   (SELECT COUNT(*) FROM employees) AS number_of_rows	   
UNION ALL
SELECT 'Offices' AS table_name,
       9 AS number_of_attributes,
  	   (SELECT COUNT(*) FROM offices) AS number_of_rows
	   
-- Question 1: Which Products Should We Order More of or Less of?
-- Identify top 10 low stock items
SELECT p.productcode, 
	   ROUND(SUM(o.quantityordered)*1.0/p.quantityInStock,2) AS low_stock
FROM orderdetails AS o
INNER JOIN products AS p
ON o.productCode = p.productCode
GROUP BY o.productCode
ORDER BY low_stock
LIMIT 10;

-- Product performance
SELECT productcode, 
	   SUM(quantityOrdered*priceEach) AS performance
FROM orderdetails
GROUP BY productCode
ORDER BY performance DESC
LIMIT 10;

-- Priority Products for restocking
WITH low_stock_table AS (
	SELECT p.productcode, 
		   ROUND(SUM(o.quantityordered)*1.0/p.quantityInStock,2) AS low_stock
	FROM orderdetails AS o
	INNER JOIN products AS p
		ON o.productCode = p.productCode
	GROUP BY o.productCode
	ORDER BY low_stock
	LIMIT 10
)
SELECT od.productCode, p.productLine, p.productName,
       SUM(quantityOrdered * priceEach) AS prod_perf
  FROM orderdetails AS od
INNER JOIN products AS p
	ON od.productCode = p.productCode
  WHERE od.productCode IN (SELECT productCode
                         FROM low_stock_table)
GROUP BY od.productCode 
ORDER BY prod_perf DESC


-- Question 2: How should we match marketing and communication strategies to customer behaviors?
-- Top 5 VIP customers
WITH customerProfit AS (
	SELECT customerNumber, 
		   SUM(quantityordered*(priceeach-buyPrice)) AS profit
	FROM orders AS o
	INNER JOIN orderdetails AS od
		ON o.orderNumber = od.orderNumber
	INNER JOIN products AS p
		ON od.productCode = p.productCode
	GROUP BY customerNumber
	ORDER BY profit DESC
	LIMIT 5
	)
SELECT cp.customerNumber, 
	   cp.profit, 
	   c.customerName,
	   c.contactFirstName,
	   c.contactLastName,
	   c.city, 
	   c.country
FROM customerProfit AS cp
INNER JOIN customers AS c
	ON cp.customerNumber = c.customerNumber


-- Top 5 less engaged customers
WITH customerProfit AS (
	SELECT customerNumber, 
		   SUM(quantityordered*(priceeach-buyPrice)) AS profit
	FROM orders AS o
	INNER JOIN orderdetails AS od
		ON o.orderNumber = od.orderNumber
	INNER JOIN products AS p
		ON od.productCode = p.productCode
	GROUP BY customerNumber
	ORDER BY profit
	LIMIT 5
	)
SELECT cp.customerNumber, 
	   cp.profit, 
	   c.customerName,
	   c.contactFirstName,
	   c.contactLastName,
	   c.city, 
	   c.country
FROM customerProfit AS cp
INNER JOIN customers AS c
	ON cp.customerNumber = c.customerNumber


-- Question 3: How Much Can We Spend on Acquiring New Customers?
WITH customer_profit AS (
	SELECT 
		customerNumber, 
		SUM(quantityordered*(priceeach-buyPrice)) AS profit
	FROM orders AS o
	INNER JOIN orderdetails AS od
		ON o.orderNumber = od.orderNumber
	INNER JOIN products AS p
		ON od.productCode = p.productCode
	GROUP BY customerNumber
)
SELECT AVG(profit) AS ltv
FROM customer_profit