-- Calculating KPI metrics for the Superstore

-- KPIs overview for specified period
SELECT 
	ROUND(SUM(sales)) AS total_sales,
	ROUND(SUM(profit)) AS total_profit,
	COUNT(DISTINCT customer_id) AS total_customers,
	ROUND(SUM(sales) / COUNT(DISTINCT customer_id)) AS sales_per_customer,
	COUNT(DISTINCT order_id) AS total_orders,
	ROUND(SUM(profit) / COUNT(DISTINCT order_id)) AS profit_per_order,
	ROUND(AVG(discount), 2) avg_discount,
	ROUND(SUM(profit) / SUM(sales), 2) AS profit_ratio
FROM 
	datalearn.orders
WHERE
	EXTRACT(YEAR FROM order_date) = 2019
	AND EXTRACT(MONTH FROM order_date) = 11;


-- Sales and profit by month 
SELECT 
	EXTRACT(YEAR FROM order_date) AS YEAR,
	EXTRACT(MONTH FROM order_date) AS MONTH,
	ROUND(SUM(sales)) AS total_sales,
	ROUND(SUM(profit)) AS total_profit
FROM 
	datalearn.orders
GROUP BY
	EXTRACT(YEAR FROM order_date),
	EXTRACT(MONTH FROM order_date)
ORDER BY
	YEAR,
	MONTH;


-- Profit by state for specified period
SELECT 
	state,
	ROUND(SUM(profit)) AS total_profit
FROM 
	datalearn.orders
WHERE 
	EXTRACT(YEAR FROM order_date) = 2019
	AND EXTRACT(MONTH FROM order_date) = 11
GROUP BY
	state
ORDER BY
	total_profit DESC


-- Top-5 profitable customers by segment for specified period
WITH profit_by_customer AS
	(SELECT 
		segment,
		customer_name,
		ROUND(SUM(profit)) AS total_profit,
		ROW_NUMBER() OVER(PARTITION BY segment ORDER BY SUM(profit) DESC) AS rating
	FROM
		datalearn.orders
	WHERE
		EXTRACT(YEAR FROM order_date) = 2019
		AND EXTRACT(MONTH FROM order_date) = 11
	GROUP BY
		segment,
		customer_name)
SELECT
	segment,
	customer_name,
	total_profit
FROM 
	profit_by_customer
WHERE
	rating <=5;


-- Sales and profit by product category for specified period
SELECT 
	category,
	subcategory,
	ROUND(SUM(sales)) AS total_sales,
	ROUND(SUM(profit)) AS total_profit
FROM 
	datalearn.orders
WHERE 
	EXTRACT(YEAR FROM order_date) = 2019
	AND EXTRACT(MONTH FROM order_date) = 11
GROUP BY
	category,
	subcategory
ORDER BY
	category,
	total_sales DESC;
	

-- Total sum of returned orders vs total sales
SELECT 
	ROUND(SUM(sales)) AS total_sales,
	ROUND(SUM(CASE WHEN r.returned IS NOT NULL THEN sales END)) AS returned_orders_sum,
	ROUND(SUM(CASE WHEN r.returned IS NOT NULL THEN sales END) / SUM(sales), 2) AS share_of_returned_sales
FROM 
	datalearn.orders o 
LEFT JOIN datalearn."returns" r USING(order_id)

