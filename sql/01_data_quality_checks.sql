
-- =========================
-- DATA QUALITY CHECKS
-- =========================
-- ===================================================
-- 1. ROW COUNT CHECKS – Ensure all rows are imported
-- ===================================================

SELECT COUNT(*) AS Total_Customers
FROM olist_customers_dataset;
--99441
SELECT COUNT(*) AS Total_Geolocation
FROM olist_geolocation_dataset;
--1000163
SELECT COUNT(*) AS TotaL_Order_Items
FROM olist_order_items_dataset;
--112650
SELECT COUNT(*) AS Total_Order_Payments
FROM olist_order_payments_dataset;
--103886
SELECT COUNT(*) AS Total_Orders
FROM olist_orders_dataset;
--99441
SELECT COUNT(*) AS Total_Products
FROM olist_products_dataset;
--32951
SELECT COUNT(*) AS Total_Category_Names
FROM product_category_name_translation;
--71
SELECT COUNT(*) AS total_sellers 
FROM olist_sellers_dataset;
--3095

-- ===================================================
-- 2. SAMPLE ROWS – Quick preview of data content
-- ===================================================

SELECT TOP 5 * FROM olist_orders_dataset;
SELECT TOP 5 * FROM olist_customers_dataset;
SELECT TOP 5 * FROM olist_products_dataset;
SELECT TOP 5 * FROM olist_order_items_dataset;
SELECT TOP 5 * FROM olist_order_payments_dataset;
SELECT TOP 5 * FROM olist_sellers_dataset;
SELECT TOP 5 * FROM olist_geolocation_dataset;
SELECT TOP 5 * FROM product_category_name_translation;

-- ===================================================
-- 3. NULL VALUE CHECKS – Detect missing critical values
-- ===================================================

SELECT COUNT(*) - COUNT(customer_id) AS missing_customer_id FROM olist_customers_dataset; --0
SELECT COUNT(*) - COUNT(customer_city) AS missing_customer_city FROM olist_customers_dataset; --0
SELECT COUNT(*) - COUNT(customer_state) AS missing_customer_state FROM olist_customers_dataset; --0

SELECT COUNT(*) - COUNT(seller_id) AS missing_seller_id FROM olist_sellers_dataset; --0
SELECT COUNT(*) - COUNT(seller_city) AS missing_seller_city FROM olist_sellers_dataset; --0
SELECT COUNT(*) - COUNT(seller_state) AS missing_seller_state FROM olist_sellers_dataset; --0

SELECT COUNT(*) - COUNT(price) AS missing_price FROM olist_order_items_dataset; --0
SELECT COUNT(*) - COUNT(freight_value) AS missing_freight FROM olist_order_items_dataset; --0

SELECT COUNT(*) - COUNT(order_id) AS missing_order_id FROM olist_orders_dataset; --0
SELECT COUNT(*) - COUNT(order_purchase_timestamp) AS missing_purchase_date FROM olist_orders_dataset; --0
SELECT COUNT(*) - COUNT(order_delivered_customer_date) AS missing_delivered_date FROM olist_orders_dataset; --2965
SELECT COUNT(*) - COUNT(order_estimated_delivery_date) AS missing_estimated_date FROM olist_orders_dataset; --0
SELECT COUNT(*) - COUNT(order_status) AS missing_status FROM olist_orders_dataset; --0

SELECT COUNT(*) - COUNT(payment_value) AS missing_payment_amount FROM olist_order_payments_dataset; --0
SELECT COUNT(*) - COUNT(payment_type) AS missing_payment_type FROM olist_order_payments_dataset; --0


SELECT COUNT(*) - COUNT(product_category_name) AS missing_product_category FROM olist_products_dataset; --610
SELECT COUNT(*) - COUNT(product_category_name_english) AS missing_product_category_english FROM product_category_name_translation;


-- =============================================================
--  4. DISTINCT VALUE CHECKS – Detect uniqueness and integrity
-- =============================================================

SELECT COUNT(DISTINCT order_id) FROM olist_orders_dataset;
--99441
SELECT COUNT(DISTINCT customer_id) FROM olist_orders_dataset;
--99441

SELECT COUNT(DISTINCT customer_id) FROM olist_customers_dataset;
--99441
SELECT COUNT(DISTINCT customer_unique_id) FROM olist_customers_dataset;
-- 96096

SELECT DISTINCT order_status FROM olist_orders_dataset;
--created, shipped, canceled, approved, processing, unavailable, delivered, invoiced

SELECT DISTINCT payment_type FROM olist_order_payments_dataset;
-- credit_card, debit_card, not_defined, voucher, boleto

SELECT COUNT(DISTINCT product_id) AS unique_product_ids FROM olist_products_dataset;
--32951
SELECT COUNT(DISTINCT product_category_name) AS unique_raw_categories FROM olist_products_dataset;
--73

SELECT COUNT(DISTINCT seller_id) AS unique_seller_ids FROM olist_sellers_dataset;
-- 3095


-- ===============================================
-- 5. DUPLICATE ROW CHECK – for composite key tables
-- ===============================================

SELECT order_id, order_item_id, COUNT(*) AS Duplicates
FROM olist_order_items_dataset
GROUP BY order_id, order_item_id
HAVING COUNT (*)> 1;
-- No Duplicates
SELECT order_id, payment_sequential, COUNT(*) AS Duplicates
FROM olist_order_payments_dataset
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;
-- No Duplicates
