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
	dw.sales s
INNER JOIN dw.calendar c ON s.order_date_id = c.date_id 
WHERE
	c.year = 2019
	AND c.month = 11;


-- KPIs overview with year-over-year change 
WITH metrics AS (
  SELECT 
    c.year AS YEAR,
    c.month AS MONTH,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    COUNT(DISTINCT customer_id) AS total_customers,
    SUM(sales) / COUNT(DISTINCT customer_id) AS sales_per_customer,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(profit) / COUNT(DISTINCT order_id) AS profit_per_order,
    AVG(discount) AS avg_discount,
    SUM(profit) / SUM(sales) AS profit_ratio
  FROM dw.sales s
  INNER JOIN dw.calendar c ON s.order_date_id = c.date_id 
  GROUP BY
    c.year,
    c.month
)
SELECT
  cur.YEAR,
  cur.MONTH,
  ROUND(cur.total_sales) AS total_sales,
  ROUND((cur.total_sales - prev.total_sales) / prev.total_sales, 3) * 100 AS total_sales_yoy,
  ROUND(cur.total_profit) AS total_profit,
  ROUND((cur.total_profit - prev.total_profit) / prev.total_profit, 3) * 100 AS total_profit_yoy,
  cur.total_customers,
  ROUND(1.0 *(cur.total_customers - prev.total_customers) / prev.total_customers, 3) * 100 AS total_customers_yoy,
  ROUND(cur.sales_per_customer) AS sales_per_customer,
  ROUND((cur.sales_per_customer - prev.sales_per_customer) / prev.sales_per_customer, 3) * 100 AS sales_per_customer_yoy,
  cur.total_orders,
  ROUND(1.0 *(cur.total_orders - prev.total_orders) / prev.total_orders, 3) * 100 AS total_orders_yoy,
  ROUND(cur.profit_per_order) AS profit_per_order,
  ROUND((cur.profit_per_order - prev.profit_per_order) / prev.profit_per_order, 3) * 100 AS profit_per_order_yoy,
  ROUND(cur.avg_discount, 3) * 100 AS avg_discount,
  ROUND((cur.avg_discount - prev.avg_discount) / prev.avg_discount, 3) * 100 AS avg_discount_yoy,
  ROUND(cur.profit_ratio, 3) * 100 AS profit_ratio,
  ROUND((cur.profit_ratio - prev.profit_ratio) / prev.profit_ratio, 3) * 100 AS profit_ratio_yoy
FROM metrics AS cur
LEFT JOIN metrics AS prev
	ON cur.YEAR = prev.YEAR + 1 AND cur.MONTH = prev.MONTH
ORDER BY 
	cur.YEAR,
	cur.MONTH;


-- Sales and profit by month 
SELECT 
	c.year AS YEAR,
	c.month AS MONTH,
	ROUND(SUM(sales)) AS total_sales,
	ROUND(SUM(profit)) AS total_profit
FROM 
	dw.sales s
INNER JOIN dw.calendar c ON s.order_date_id = c.date_id 
GROUP BY
	c.year,
	c.month
ORDER BY
	c.year,
	c.month;


-- Profit by state for specified period
SELECT 
	g.state,
	ROUND(SUM(s.profit)) AS total_profit
FROM 
	dw.sales s
INNER JOIN dw.geo g ON s.geo_id = g.id 
INNER JOIN dw.calendar c ON s.order_date_id = c.date_id 
WHERE 
	c.year = 2019
	AND c.month = 11
GROUP BY
	g.state
ORDER BY
	total_profit DESC;


-- Top-5 profitable customers by segment for specified period
WITH profit_by_customer AS
	(SELECT 
		p.segment,
		c.name AS customer_name,
		ROUND(SUM(s.profit)) AS total_profit,
		ROW_NUMBER() OVER(PARTITION BY p.segment ORDER BY SUM(s.profit) DESC) AS rating
	FROM
		dw.sales s
	INNER JOIN dw.products p ON s.product_id = p.id
	INNER JOIN dw.customers c ON s.customer_id = c.id
	INNER JOIN dw.calendar cl ON s.order_date_id = cl.date_id
	WHERE
		cl.year = 2019
		AND cl.month = 11
	GROUP BY
		p.segment,
		c.name)
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
	p.category,
	p.subcategory,
	ROUND(SUM(s.sales)) AS total_sales,
	ROUND(SUM(s.profit)) AS total_profit
FROM 
	dw.sales s 
INNER JOIN dw.products p ON s.product_id = p.id
INNER JOIN dw.calendar c ON s.order_date_id = c.date_id 
WHERE 
	c.year = 2019
	AND c.month = 11
GROUP BY
	p.category,
	p.subcategory
ORDER BY
	p.category,
	total_sales DESC;
	

-- Total sum of returned orders vs total sales
SELECT 
	ROUND(SUM(s.sales)) AS total_sales,
	ROUND(SUM(CASE WHEN r.order_id IS NOT NULL THEN sales END)) AS returned_orders_sum,
	ROUND(SUM(CASE WHEN r.order_id IS NOT NULL THEN sales END) / SUM(sales), 2) AS share_of_returned_sales
FROM 
	dw.sales s
LEFT JOIN dw.returns r USING(order_id);