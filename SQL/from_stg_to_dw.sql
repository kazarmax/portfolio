CREATE SCHEMA dw;

-- CREATING TABLES IN DW SCHEMA

-- 1 Creating table dw.customers
DROP TABLE IF EXISTS dw.customers CASCADE;
CREATE TABLE dw.customers
(
 id   		 INTEGER PRIMARY KEY,
 customer_id VARCHAR(8) NOT NULL,
 name 		 VARCHAR(22) NOT NULL
);

-- Deleting rows
TRUNCATE TABLE dw.customers;

-- 1 Generating id for customers and inserting rows from orders
INSERT INTO dw.customers 
SELECT
	100 + ROW_NUMBER() OVER(),
	customer_id,
	customer_name 
FROM 
	(SELECT DISTINCT customer_id, customer_name FROM stg.orders) sub;

-- Checking
SELECT * FROM dw.customers;


-- 2 Creating table dw.regions
DROP TABLE IF EXISTS dw.regions CASCADE;
CREATE TABLE dw.regions
(
 id  INTEGER PRIMARY KEY,
 name VARCHAR(7) NOT NULL
);

-- Deleting rows
TRUNCATE TABLE dw.regions;

-- 2 Filling table dw.regions
INSERT INTO dw.regions
SELECT
	110 + ROW_NUMBER() OVER(),
	region
FROM
	(SELECT DISTINCT region FROM stg.orders) sub;

-- Checking
SELECT * FROM dw.regions;


-- 3 Creating table dw.region_managers
DROP TABLE IF EXISTS dw.region_managers CASCADE;
CREATE TABLE dw.region_managers
(
 id        INTEGER PRIMARY KEY,
 name      VARCHAR(17) NOT NULL,
 region_id INTEGER NOT NULL,
 CONSTRAINT fk_region FOREIGN KEY (region_id) REFERENCES dw.regions (id)
);

-- Deleting rows
TRUNCATE TABLE dw.region_managers;

-- 3 Filling table dw.region_managers
INSERT INTO dw.region_managers
SELECT 
	1000 + ROW_NUMBER() over(),
	p.person,
	r.id
FROM stg.people p
JOIN dw.regions r ON p.region = r.name;

-- Checking
SELECT * FROM dw.region_managers;


-- 4 Creating table dw.geo
DROP TABLE IF EXISTS dw.geo CASCADE;
CREATE TABLE dw.geo
(
 id          INTEGER PRIMARY KEY,
 country     VARCHAR(13) NOT NULL,
 city        VARCHAR(17) NOT NULL,
 state       VARCHAR(20) NOT NULL,
 region_id   INTEGER NOT NULL,
 postal_code VARCHAR(20) NULL,
 CONSTRAINT fk_region FOREIGN KEY (region_id) REFERENCES dw.regions (id)
);

-- Deleting rows
TRUNCATE TABLE dw.geo;

-- 4 Filling table dw.geo
INSERT INTO dw.geo
SELECT 
	100 + ROW_NUMBER() OVER(), -- generate id starting FROM 100
	country,
	city,
	state,
	r.id,
	postal_code
FROM
	(SELECT DISTINCT country, city, state, region, postal_code FROM stg.orders) AS o
INNER JOIN dw.regions r ON o.region = r.name;

-- Checking
SELECT * FROM dw.geo;

-- Data quality check
SELECT DISTINCT country, city, state, region_id, postal_code FROM dw.geo
WHERE country IS NULL OR city IS NULL OR region_id IS NULL OR postal_code IS NULL;

-- City Burlington, Vermont doesn't have postal code. Fill the postal code for it
UPDATE dw.geo 
SET postal_code = '05401'
WHERE city = 'Burlington' AND postal_code IS NULL;

-- Update the same missing postal code in source file
UPDATE stg.orders 
SET postal_code = '05401'
WHERE city = 'Burlington' AND postal_code IS NULL;


-- 5 Creating table dw.calendar
DROP TABLE IF EXISTS dw.calendar CASCADE;
CREATE TABLE dw.calendar
(
 date_id	INTEGER PRIMARY KEY,
 year       INTEGER NOT NULL,
 quarter    INTEGER NOT NULL,
 month      INTEGER NOT NULL,
 week       INTEGER NOT NULL,
 date		DATE    NOT NULL,
 week_day	VARCHAR(20) NOT NULL
);

-- Deleting rows
TRUNCATE TABLE dw.calendar;
-- Inserting data
INSERT INTO dw.calendar
SELECT 
	to_char(date, 'yyyymmdd')::int AS date_id,
	EXTRACT(YEAR FROM date)::int AS YEAR,
	EXTRACT(QUARTER FROM date)::int AS quarter,
	EXTRACT(MONTH FROM date)::int AS MONTH,
	to_char(date, 'WW')::int AS week,
	date::DATE,
	to_char(date, 'dy') AS week_day
FROM GENERATE_SERIES(DATE '2000-01-01',
                     DATE '2030-01-01',
                     INTERVAL '1 day') as t(date);

-- Checking
SELECT * FROM dw.calendar;


-- 6 Creating table dw.shipping
DROP TABLE IF EXISTS dw.shipping CASCADE;
CREATE TABLE dw.shipping
(
 id        INTEGER PRIMARY KEY,
 ship_mode VARCHAR(14) NOT NULL
);

-- Deleting rows
TRUNCATE TABLE dw.shipping;
-- Inserting data
INSERT INTO dw.shipping
SELECT 
	100 + ROW_NUMBER() OVER() AS id,
	ship_mode
FROM (SELECT DISTINCT ship_mode FROM stg.orders) t;

-- Checking
SELECT * FROM dw.shipping;


-- 7 Creating table dw.products
DROP TABLE IF EXISTS dw.products CASCADE;
CREATE TABLE dw.products
(
 id          INTEGER PRIMARY KEY,
 product_id	 VARCHAR(50) NOT NULL,
 name        VARCHAR(127) NOT NULL,
 category    VARCHAR(15) NOT NULL,
 subcategory VARCHAR(11) NOT NULL,
 segment     VARCHAR(11) NOT NULL
);

-- Deleting rows
TRUNCATE TABLE dw.products;
-- Inserting data
INSERT INTO dw.products
SELECT
	100 + ROW_NUMBER() over() AS id,
	product_id,
	product_name,
	category,
	subcategory,
	segment
FROM (SELECT DISTINCT product_id, product_name, category, subcategory, segment FROM stg.orders) t;

-- Checking
SELECT * FROM dw.products;


-- 8 Creating table dw.sales
DROP TABLE IF EXISTS dw.sales CASCADE;
CREATE TABLE dw.sales
(
 id          INTEGER PRIMARY KEY,
 order_id    VARCHAR(25) NOT NULL,
 order_date_id  INTEGER NOT NULL,
 ship_date_id   INTEGER NOT NULL,
 sales       NUMERIC(9,4) NOT NULL,
 profit      NUMERIC(21,16) NOT NULL,
 quantity    INTEGER NOT NULL,
 discount    NUMERIC(4,2) NOT NULL,
 product_id  INTEGER NOT NULL,
 customer_id INTEGER NOT NULL,
 ship_id     INTEGER NOT NULL,
 geo_id      INTEGER NOT NULL,
 CONSTRAINT fk_geo FOREIGN KEY (geo_id) REFERENCES dw.geo (id),
 CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES dw.customers (id),
 CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES dw.products (id),
 CONSTRAINT fk_shipping FOREIGN KEY (ship_id) REFERENCES dw.shipping (id)
);

-- Deleting rows
TRUNCATE TABLE dw.sales;
-- Inserting data
INSERT INTO dw.sales
SELECT
	100 + ROW_NUMBER() over() AS id,
 	order_id,
 	to_char(order_date, 'yyyymmdd')::int AS order_date_id,
	to_char(ship_date, 'yyyymmdd')::int AS ship_date_id,
 	sales,
 	profit,
 	quantity,
 	discount,
 	product.id AS product_id,
 	customer.id AS customer_id,
 	shipping.id AS ship_id,
 	geo.id AS geo_id
FROM stg.orders AS orders 
INNER JOIN dw.products AS product ON 
 	orders.product_id = product.product_id
 	AND orders.product_name = product.name 
 	AND orders.category = product.category
 	AND orders.subcategory = product.subcategory
 	AND orders.segment = product.segment
INNER JOIN dw.customers AS customer ON orders.customer_name = customer.name 
INNER JOIN dw.shipping AS shipping ON orders.ship_mode = shipping.ship_mode 
INNER JOIN dw.geo AS geo ON 
 	orders.country = geo.country 
 	AND orders.city = geo.city 
 	AND orders.state = geo.state 
 	AND orders.postal_code = geo.postal_code;

-- Checking
SELECT * FROM dw.sales;


-- 9 Creating table dw.returns
DROP TABLE IF EXISTS dw.returns CASCADE;
CREATE TABLE dw.returns(
  order_id   VARCHAR(14) PRIMARY KEY
);

-- Deleting rows
TRUNCATE TABLE dw.returns;
-- Inserting data
INSERT INTO dw.returns
SELECT DISTINCT order_id FROM stg.RETURNS;

-- Checking
SELECT * FROM dw.returns;