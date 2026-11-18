CREATE DATABASE maven_fuzzy_factory;
USE maven_fuzzy_factory;

CREATE TABLE products (
  product_id INT PRIMARY KEY,
  created_at DATETIME,
  product_name VARCHAR(50)
);

CREATE TABLE website_sessions (
  website_session_id INT PRIMARY KEY,
  created_at DATETIME,
  user_id INT,
  is_repeat_session TINYINT,
  utm_source VARCHAR(50),
  utm_campaign VARCHAR(50),
  utm_content VARCHAR(50),
  device_type VARCHAR(20),
  http_referer VARCHAR(100)
);

CREATE TABLE website_pageviews (
  website_pageview_id INT PRIMARY KEY,
  created_at DATETIME,
  website_session_id INT,
  pageview_url VARCHAR(100)
);

CREATE TABLE orders (
  order_id INT PRIMARY KEY,
  created_at DATETIME,
  website_session_id INT,
  user_id INT,
  primary_product_id INT,
  items_purchased INT,
  price_usd DECIMAL(10,2),
  cogs_usd DECIMAL(10,2)
);

CREATE TABLE order_items (
  order_item_id INT PRIMARY KEY,
  created_at DATETIME,
  order_id INT,
  product_id INT,
  is_primary_item TINYINT,
  price_usd DECIMAL(10,2),
  cogs_usd DECIMAL(10,2)
);

CREATE TABLE order_item_refunds (
  order_item_refund_id INT PRIMARY KEY,
  created_at DATETIME,
  order_item_id INT,
  order_id INT,
  refund_amount_usd DECIMAL(10,2)
);



USE maven_fuzzy_factory;
SELECT COUNT(*) FROM website_pageviews;
TRUNCATE TABLE website_pageviews;



USE maven_fuzzy_factory;
SELECT COUNT(*) FROM website_sessions;
TRUNCATE TABLE website_sessions;

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:\Users\Owner\Downloads\website_pageviews.csv'
INTO TABLE website_pageviews
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SHOW VARIABLES LIKE 'local_infile';

SHOW VARIABLES LIKE 'secure_file_priv';

USE maven_fuzzy_factory;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/website_pageviews.csv'
INTO TABLE website_pageviews
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(website_pageview_id, @created_at, website_session_id, pageview_url)
SET created_at = STR_TO_DATE(@created_at, '%m/%d/%Y %H:%i');

USE maven_fuzzy_factory;
TRUNCATE TABLE website_pageviews;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/website_pageviews.csv'
INTO TABLE website_pageviews
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM website_pageviews;
SELECT * FROM website_pageviews LIMIT 5;

TRUNCATE TABLE website_sessions;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/website_sessions.csv'
INTO TABLE website_sessions
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SELECT utm_source, COUNT(*) FROM website_sessions GROUP BY utm_source;

-- SQL BUSINESS ANALYSIS

-- Write SQL queries to answer the following questions:
-- 1. What is the total number of unique orders?
-- 2. What is the total revenue generated?
-- 3. Which five products generate the highest revenue?
-- 4. Which product categories or product types perform best, where available?
-- 5. Which marketing sources generate the most website sessions?
-- 6. Which device type generates the most website traffic?
-- 7. What is the website session-to-order conversion rate?
-- 8. What is the total number and value of refunds?
-- 9. Which months recorded the highest and lowest revenue?
-- 10. What is the average order value?

-- 1. Total number of unique orders
SELECT COUNT(DISTINCT order_id) AS Total_orders
FROM orders;

-- 2. Total revenue generated
SELECT SUM(price_usd) AS Total_revenue
FROM orders;

-- 3. Top five products by revenue
SELECT p.product_name,
       SUM(oi.price_usd) AS revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY revenue DESC
LIMIT 5;

-- 4. Best-performing product categories or types
SELECT p.product_name,
       COUNT(*) AS units_sold,
       SUM(oi.price_usd) AS revenue,
       SUM(oi.cogs_usd) AS cogs,
       SUM(oi.price_usd - oi.cogs_usd) AS gross_profit,
       ROUND(SUM(oi.price_usd - oi.cogs_usd) / SUM(oi.price_usd) * 100, 2) AS margin_pct
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY revenue DESC;

-- 5. Marketing sources with the most sessions
SELECT COALESCE(utm_source, 'direct / organic') AS marketing_source,
       COUNT(*) AS sessions
FROM website_sessions
GROUP BY COALESCE(utm_source, 'direct / organic')
ORDER BY sessions DESC;

-- 6. Device type with the most traffic
SELECT device_type,
       COUNT(*) AS sessions
FROM website_sessions
GROUP BY device_type
ORDER BY sessions DESC;

-- 7. Session-to-order conversion rate
SELECT COUNT(DISTINCT s.website_session_id) AS sessions,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(COUNT(DISTINCT o.order_id) / COUNT(DISTINCT s.website_session_id) * 100, 2) AS conversion_rate_pct
FROM website_sessions s
LEFT JOIN orders o ON o.website_session_id = s.website_session_id;

-- 8. Total number and value of refunds
SELECT COUNT(DISTINCT order_item_refund_id) AS total_refunds,
       SUM(refund_amount_usd) AS total_refund_value
FROM order_item_refunds;

-- 9. Months with the highest and lowest revenue
SELECT DATE_FORMAT(created_at, '%Y-%m') AS month,
       SUM(price_usd) AS revenue
FROM orders
GROUP BY DATE_FORMAT(created_at, '%Y-%m')
ORDER BY month;

-- 10. Average order value
SELECT ROUND(AVG(price_usd), 2) AS average_order_value
FROM orders;