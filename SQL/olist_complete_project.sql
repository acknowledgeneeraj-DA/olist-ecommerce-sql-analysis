
CREATE DATABASE olist1;
USE olist1;

SET GLOBAL local_infile = 1;

-- =========================
-- 1. CUSTOMERS
-- =========================
CREATE TABLE customers (
customer_id VARCHAR(50) PRIMARY KEY,
customer_unique_id VARCHAR(50),
customer_zip_code_prefix VARCHAR(10),
customer_city VARCHAR(100),
customer_state VARCHAR(5)
);

LOAD DATA LOCAL INFILE 'E:/0list archive/archive/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- =========================
-- 2. ORDERS
-- =========================
CREATE TABLE orders (
order_id VARCHAR(50),
customer_id VARCHAR(50),
order_status VARCHAR(50),
order_purchase_timestamp TEXT,
order_approved_at TEXT,
order_delivered_carrier_date TEXT,
order_delivered_customer_date TEXT,
order_estimated_delivery_date TEXT
);

LOAD DATA LOCAL INFILE 'E:/0list archive/archive/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SET SQL_SAFE_UPDATES = 0;


UPDATE orders
SET
order_approved_at = NULLIF(order_approved_at, ''),
order_delivered_carrier_date = NULLIF(order_delivered_carrier_date, ''),
order_delivered_customer_date = NULLIF(order_delivered_customer_date, '');

SET SQL_SAFE_UPDATES = 1;

ALTER TABLE orders
MODIFY order_id VARCHAR(50) PRIMARY KEY,
MODIFY customer_id VARCHAR(50),
MODIFY order_status VARCHAR(50),
MODIFY order_purchase_timestamp DATETIME,
MODIFY order_approved_at DATETIME,
MODIFY order_delivered_carrier_date DATETIME,
MODIFY order_delivered_customer_date DATETIME,
MODIFY order_estimated_delivery_date DATETIME;

-- =========================
-- 3. PRODUCTS
-- =========================
CREATE TABLE products (
product_id VARCHAR(50),
product_category_name TEXT,
product_name_lenght TEXT,
product_description_lenght TEXT,
product_photos_qty TEXT,
product_weight_g TEXT,
product_length_cm TEXT,
product_height_cm TEXT,
product_width_cm TEXT
);

LOAD DATA LOCAL INFILE 'E:/0list archive/archive/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SET SQL_SAFE_UPDATES = 0;

UPDATE products
SET
product_category_name = NULLIF(product_category_name, ''),
product_name_lenght = NULLIF(product_name_lenght, ''),
product_description_lenght = NULLIF(product_description_lenght, ''),
product_photos_qty = NULLIF(product_photos_qty, ''),
product_weight_g = NULLIF(product_weight_g, ''),
product_length_cm = NULLIF(product_length_cm, ''),
product_height_cm = NULLIF(product_height_cm, ''),
product_width_cm = NULLIF(product_width_cm, '');

ALTER TABLE products
MODIFY product_id VARCHAR(50) PRIMARY KEY,
MODIFY product_category_name VARCHAR(100),
MODIFY product_name_lenght INT,
MODIFY product_description_lenght INT,
MODIFY product_photos_qty INT,
MODIFY product_weight_g INT,
MODIFY product_length_cm INT,
MODIFY product_height_cm INT,
MODIFY product_width_cm INT;

-- =========================
-- 4. ORDER ITEMS
-- =========================
CREATE TABLE order_items (
order_id VARCHAR(50),
order_item_id INT,
product_id VARCHAR(50),
seller_id VARCHAR(50),
shipping_limit_date TEXT,
price DOUBLE,
freight_value DOUBLE
);

LOAD DATA LOCAL INFILE 'E:/0list archive/archive/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

ALTER TABLE order_items
MODIFY shipping_limit_date DATETIME;

ALTER TABLE order_items
ADD PRIMARY KEY (order_id, order_item_id);

-- =========================
-- 5. SELLERS
-- =========================
CREATE TABLE sellers (
seller_id VARCHAR(50),
seller_zip_code_prefix VARCHAR(10),
seller_city VARCHAR(100),
seller_state VARCHAR(5)
);

LOAD DATA LOCAL INFILE 'E:/0list archive/archive/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

UPDATE sellers
SET seller_state = TRIM(REPLACE(REPLACE(seller_state, '\r', ''), '\n', ''));

DELETE FROM sellers
WHERE LENGTH(seller_state) != 2;

SELECT seller_state, COUNT(*)
FROM sellers
GROUP BY seller_state
ORDER BY seller_state;

SELECT COUNT(*) FROM sellers;

ALTER TABLE sellers
ADD PRIMARY KEY (seller_id);

-- =========================
-- 6. PAYMENTS
-- =========================
CREATE TABLE payments (
order_id VARCHAR(50),
payment_sequential INT,
payment_type VARCHAR(50),
payment_installments INT,
payment_value DOUBLE
);

LOAD DATA LOCAL INFILE 'E:/0list archive/archive/olist_order_payments_dataset.csv'
INTO TABLE payments
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

UPDATE payments
SET order_id = REPLACE(order_id, '"', '');

ALTER TABLE payments
ADD PRIMARY KEY (order_id, payment_sequential);

-- =========================
-- 7. REVIEWS (RAW → CLEAN)
-- =========================
CREATE TABLE reviews_raw (
review_id VARCHAR(50),
order_id VARCHAR(50),
review_score INT,
review_comment_title TEXT,
review_comment_message TEXT,
review_creation_date TEXT,
review_answer_timestamp TEXT
);

LOAD DATA LOCAL INFILE 'E:/0list archive/archive/olist_order_reviews_dataset.csv'
INTO TABLE reviews_raw
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE reviews AS
SELECT
review_id,
order_id,
review_score,
review_comment_title,
review_comment_message,
NULLIF(review_creation_date, '0000-00-00 00:00:00') AS review_creation_date,
NULLIF(review_answer_timestamp, '0000-00-00 00:00:00') AS review_answer_timestamp
FROM reviews_raw;

ALTER TABLE reviews
MODIFY review_creation_date DATETIME,
MODIFY review_answer_timestamp DATETIME;

ALTER TABLE reviews
ADD PRIMARY KEY (review_id, order_id);

-- =========================
-- 8. GEOLOCATION
-- =========================
CREATE TABLE geolocation_raw (
geolocation_zip_code_prefix TEXT,
geolocation_lat TEXT,
geolocation_lng TEXT,
geolocation_city TEXT,
geolocation_state TEXT
);

LOAD DATA LOCAL INFILE 'E:/0list archive/archive/olist_geolocation_dataset.csv'
INTO TABLE geolocation_raw
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE geolocation AS
SELECT
geolocation_zip_code_prefix AS zip_code_prefix,
AVG(CAST(geolocation_lat AS DECIMAL(10,6))) AS lat,
AVG(CAST(geolocation_lng AS DECIMAL(10,6))) AS lng,
MIN(geolocation_city) AS city,
MIN(geolocation_state) AS state
FROM geolocation_raw
GROUP BY geolocation_zip_code_prefix;

ALTER TABLE geolocation
MODIFY zip_code_prefix VARCHAR(10);

ALTER TABLE geolocation
ADD PRIMARY KEY (zip_code_prefix);

-- =========================
-- 9. CATEGORY TRANSLATION
-- =========================
CREATE TABLE category_translation (
product_category_name VARCHAR(100),
product_category_name_english VARCHAR(100)
);

LOAD DATA LOCAL INFILE 'E:/0list archive/archive/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

ALTER TABLE category_translation
ADD PRIMARY KEY (product_category_name);

-- =========================
-- 10. FOREIGN KEYS
-- =========================
ALTER TABLE orders
ADD CONSTRAINT fk_orders_customers
FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_items_orders
FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_items_products
FOREIGN KEY (product_id) REFERENCES products(product_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_items_sellers
FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);

SELECT COUNT(*) AS invalid_sellers
FROM order_items oi
LEFT JOIN sellers s
ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

ALTER TABLE payments
ADD CONSTRAINT fk_payments_orders
FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE reviews
ADD CONSTRAINT fk_reviews_orders
FOREIGN KEY (order_id) REFERENCES orders(order_id);

-- =========================
-- 11. FINAL CHECK
-- =========================
SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL SELECT 'category_translation', COUNT(*) FROM category_translation;

SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

SET SQL_SAFE_UPDATES = 0;



UPDATE products
SET product_category_name = 'unknown'
WHERE product_category_name IS NULL;

DELETE FROM payments
WHERE payment_type = 'not_defined';


SELECT 
ROUND(SUM(payment_value), 2) AS total_revenue,
COUNT(DISTINCT order_id) AS total_orders,
ROUND(SUM(payment_value) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM payments;

SELECT 
COALESCE(ct.product_category_name_english, 'unknown') AS category,
ROUND(SUM(oi.price), 2) AS revenue,
COUNT(DISTINCT oi.order_id) AS orders
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct 
ON p.product_category_name = ct.product_category_name
GROUP BY category
ORDER BY revenue DESC
LIMIT 10;


SELECT 
DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
COUNT(DISTINCT o.order_id) AS orders,
ROUND(SUM(p.payment_value), 2) AS revenue
FROM orders o
JOIN payments p ON o.order_id = p.order_id
WHERE o.order_purchase_timestamp < '2018-09-01'
GROUP BY month
ORDER BY month;


WITH delivery_calc AS (
SELECT 
o.order_id,
c.customer_state,
DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS actual_days,
CASE 
WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 
ELSE 0 END AS is_late
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
)
SELECT 
customer_state,
COUNT(*) AS delivered_orders,
ROUND(AVG(actual_days), 1) AS avg_delivery_days,
ROUND(SUM(is_late) * 100.0 / COUNT(*), 1) AS late_percentage
FROM delivery_calc
GROUP BY customer_state
ORDER BY late_percentage DESC
LIMIT 10;


WITH customer_orders AS (
SELECT 
c.customer_unique_id,
COUNT(DISTINCT o.order_id) AS order_count,
ROUND(SUM(p.payment_value), 2) AS total_spend
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN payments p ON o.order_id = p.order_id
GROUP BY c.customer_unique_id
)
SELECT 
CASE 
WHEN order_count = 1 THEN 'One-time'
WHEN order_count = 2 THEN 'Returned once'
ELSE 'Loyal (3+)'
END AS customer_segment,
COUNT(*) AS customers,
ROUND(AVG(total_spend), 2) AS avg_spend
FROM customer_orders
GROUP BY customer_segment
ORDER BY customers DESC;



WITH order_delivery_review AS (
SELECT 
o.order_id,
r.review_score,
DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS delivery_days
FROM orders o
JOIN reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
)
SELECT 
review_score,
COUNT(*) AS total_reviews,
ROUND(AVG(delivery_days), 1) AS avg_delivery_days
FROM order_delivery_review
GROUP BY review_score
ORDER BY review_score;


CREATE VIEW v_delivery_performance AS
SELECT 
o.order_id,
o.order_status,
c.customer_state,
DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS actual_delivery_days,
DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) AS delay_days,
CASE 
WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
WHEN o.order_delivered_customer_date IS NULL THEN 'Not Delivered'
ELSE 'On Time'
END AS delivery_status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id;


CREATE VIEW v_sales_by_category AS
SELECT 
COALESCE(ct.product_category_name_english, 'unknown') AS category,
ROUND(SUM(oi.price), 2) AS revenue,
COUNT(DISTINCT oi.order_id) AS total_orders,
ROUND(AVG(oi.price), 2) AS avg_item_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
ON p.product_category_name = ct.product_category_name
GROUP BY category;


SELECT * FROM v_delivery_performance LIMIT 10;
SELECT * FROM v_sales_by_category ORDER BY revenue DESC LIMIT 10;


CREATE TABLE export_order_details AS
SELECT 
o.order_id,
o.order_status,
o.order_purchase_timestamp,
c.customer_unique_id,
c.customer_city,
c.customer_state,
oi.product_id,
COALESCE(ct.product_category_name_english, 'unknown') AS category,
oi.seller_id,
oi.price,
oi.freight_value,
p.payment_type,
p.payment_value,
r.review_score,
DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS delivery_days,
CASE 
WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
WHEN o.order_delivered_customer_date IS NULL THEN 'Not Delivered'
ELSE 'On Time'
END AS delivery_status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products pr ON oi.product_id = pr.product_id
LEFT JOIN category_translation ct ON pr.product_category_name = ct.product_category_name
LEFT JOIN payments p ON o.order_id = p.order_id
LEFT JOIN reviews r ON o.order_id = r.order_id;



SELECT COUNT(*) FROM export_order_details;
SELECT * FROM export_order_details LIMIT 10;
