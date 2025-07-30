       
-- ============================================================
-- 🛠 STEP 0: Column Renaming for Readability and Clean Modeling
-- ============================================================

-- Renaming default column names after importing
-- Column1 → product_category_name
-- Column2 → product_category_name_english

EXEC sp_rename 'product_category_name_translation.Column1', 'product_category_name', 'COLUMN';
EXEC sp_rename 'product_category_name_translation.Column2', 'product_category_name_english', 'COLUMN';

-- ============================================================
-- ❌ DATA ISSUE: Header row mistakenly included as data
-- ============================================================

-- Problem:
-- A row in product_category_name_translation contains values:
--   'product_category_name', 'product_category_name_english'
-- This is a leftover header row from the CSV import.

-- ✅ Fix: Remove the incorrect row

DELETE FROM product_category_name_translation
WHERE product_category_name = 'product_category_name'
AND product_category_name_english = 'product_category_name_english';


-- ============================================================
-- 🔐 STEP 1: Add Primary Keys to Composite Key Tables
-- ============================================================

-- Check existing primary keys (for documentation)

SELECT *
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE CONSTRAINT_TYPE = 'Primary Key';

-- Add composite primary key to order_items
AlTER TABLE olist_order_items_dataset
ADD CONSTRAINT pk_order_items PRIMARY KEY (order_id , order_item_id);

-- Add composite primary key to order_payments
ALTER TABLE olist_order_payments_dataset 
ADD CONSTRAINT pk_payments PRIMARY KEY (order_id , payment_sequential);


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

-- =========================
-- DATA CLEANING
-- =========================
-- =============================================================
-- 🔧 CLEANING 1: Handle NULL values in product_category_name
-- =============================================================

-- Problem:
-- 610 missing values in product_category_name column

-- ✅ Fix:
-- Replace NULLs with 'unknown' for better join compatibility

UPDATE olist_products_dataset
SET product_category_name = 'unknown'
WHERE product_category_name IS NULL;


-- Also, insert matching 'unknown' translation into the translation table
INSERT INTO product_category_name_translation (product_category_name, product_category_name_english)
VALUES ('unknown', 'unknown');

-- =============================================================
-- 🧹 CLEANING 2: Add missing translations to avoid NULLs in the view
-- PURPOSE:
--   These product_category_name values exist in the dataset
--   but were not found in the translation table.
--   This ensures the LEFT JOIN in the view does not return NULLs.

-- 🧠 NOTE:
--   We're following the formatting convention used in product_category_name_english:
--   lowercase, underscores, no spaces
-- =============================================================
INSERT INTO product_category_name_translation(product_category_name, product_category_name_english)
VALUES
('pc_gamer', 'pc_gamer'),
('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_appliances');

-- =============================================================
-- 🔧 CLEANING 3: Fix known typos in product_category_name_english
-- PURPOSE:
--   Correct translation typos to ensure accurate joins and clean segment classification
-- =============================================================

UPDATE product_category_name_translation
SET product_category_name_english = 'fashion_female_clothing'
WHERE product_category_name_english = 'fashio_female_clothing';

UPDATE product_category_name_translation
SET product_category_name_english = 'construction_tools_tools'
WHERE product_category_name_english = 'costruction_tools_tools';

UPDATE product_category_name_translation
SET product_category_name_english = 'construction_tools_garden'
WHERE product_category_name_english = 'costruction_tools_garden';

-- =============================================================
-- 🔧 CLEANING 4: Standardize payment_type values
-- =============================================================

-- Problem:
-- 'not_defined' is not a user-friendly or meaningful label

-- ✅ Fix:
-- Replace 'not_defined' with 'unknown' for clarity

UPDATE olist_order_payments_dataset
SET payment_type = 'unknown'
WHERE payment_type = 'not_defined';

-- ================================================================
-- 🏗️ DATA MODELING: BUSINESS-READY VIEWS
-- PURPOSE:
--   Define cleaned, structured, and reusable SQL views for analysis
-- ================================================================

-- ==================================================================
-- ✅ VIEW: vw_order_summary
-- PURPOSE:
--   Clean order-level delivery + revenue + weekday logic.
--   Used as a reusable base for many insights and joins.
--   ⚠️ Originally included canceled order values incorrectly — this version corrects it.
-- ==================================================================

CREATE OR ALTER VIEW vw_order_summary AS 
SELECT 
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    -- 💰 Financials
    CASE WHEN o.order_status = 'canceled' THEN 0 ELSE SUM(oi.price) END AS total_item_value,
    CASE WHEN o.order_status = 'canceled' THEN 0 ELSE SUM(oi.freight_value) END AS total_freight_value,
    CASE WHEN o.order_status = 'canceled' THEN 0 ELSE SUM(oi.price + oi.freight_value) END AS total_order_value,

    -- 📦 Item Count
    CASE WHEN o.order_status = 'canceled' THEN 0 ELSE COUNT(oi.product_id) END AS total_items,

    -- ⏱️ Duration (Only for delivered)
    CASE 
        WHEN o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL 
        THEN DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)
        ELSE NULL
    END AS delivery_duration_days,

    -- 🚚 Delivery Status
    CASE
        WHEN o.order_status = 'delivered' THEN 'Delivered'
        WHEN o.order_status = 'canceled' THEN 'Canceled'
        WHEN o.order_status IN ('created', 'shipped', 'approved', 'processing', 'invoiced') THEN 'In Progress'
        ELSE 'Other'
    END AS delivery_status,

    -- 📅 Purchase Day Type
    CASE 
        WHEN DATEPART(WEEKDAY, o.order_purchase_timestamp) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS purchase_day_type,

    -- 🎯 Delivery punctuality status
    CASE
        WHEN o.order_status = 'delivered' AND o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Delayed'
        WHEN o.order_status = 'delivered' AND o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'On Time'
        WHEN o.order_status = 'canceled' THEN 'Canceled'
        ELSE 'In Progress'
    END AS delivery_punctuality_status

FROM olist_orders_dataset o
INNER JOIN olist_order_items_dataset oi 
    ON o.order_id = oi.order_id
GROUP BY
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date;


-- =============================================================
-- 📄 VIEW: vw_product_segments
-- PURPOSE:
--   Provide product_id, category info, and assigned business segment.
--   Relies on pre-cleaned product_category_name_translation table (no typos, no NULLs).
--   Formatting (capitalization, spacing) is deferred to Power BI visuals.
-- =============================================================

CREATE OR ALTER VIEW vw_product_segments AS
SELECT 
    p.product_id,
    p.product_category_name,
    t.product_category_name_english,

    -- 🎯 Segment assignment based on cleaned English names
    CASE 
        WHEN t.product_category_name_english IN (
            'bed_bath_table', 'housewares', 'furniture_decor', 'home_appliances', 
            'home_construction', 'furniture_living_room', 'kitchen_dining_laundry_garden_furniture',
            'home_confort', 'home_comfort_2', 'construction_tools_construction', 
            'construction_tools_safety', 'construction_tools_lights', 'office_furniture',
            'furniture_mattress_and_upholstery', 'furniture_bedroom', 'portable_kitchen_appliances',
            'construction_tools_tools', 'construction_tools_garden'
        ) THEN 'Home & Garden'

        WHEN t.product_category_name_english IN (
            'telephony', 'electronics', 'computers_accessories', 'consoles_games',
            'fixed_telephony', 'cine_photo', 'tablets_printing_image', 'audio', 'pc_gamer'
        ) THEN 'Electronics'

        WHEN t.product_category_name_english IN (
            'fashion_bags_accessories', 'fashion_shoes', 'fashion_male_clothing',
            'fashion_female_clothing', 'fashion_underwear_beach', 'fashion_sport',
            'fashion_childrens_clothes', 'watches_gifts'
        ) THEN 'Fashion & Accessories'

        WHEN t.product_category_name_english IN (
            'health_beauty', 'perfumery', 'diapers_and_hygiene'
        ) THEN 'Health & Beauty'

        WHEN t.product_category_name_english IN (
            'sports_leisure', 'toys', 'baby'
        ) THEN 'Sports & Leisure'

        WHEN t.product_category_name_english IN (
            'books_technical', 'books_general_interest', 'books_imported',
            'cds_dvds_musicals', 'dvds_blu_ray', 'music'
        ) THEN 'Books & Media'

        WHEN t.product_category_name_english IN (
            'food_drink', 'drinks', 'food'
        ) THEN 'Food & Beverage'

        ELSE 'Others'
    END AS product_category_segment

FROM olist_products_dataset p
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name;


-- =============================================================
-- 📄 VIEW: vw_product_sales_summary
-- PURPOSE:
--   Summarize product-level sales metrics, cleaned for reporting:
--   Includes product segments, time dimensions, and filters out canceled orders
--
-- 💡 NOTES:
--   - Order status is used to exclude canceled orders from revenue & quantity
--   - This view powers time-based and category-based product insights
-- =============================================================

CREATE OR ALTER VIEW vw_product_sales_summary AS 
SELECT 
	 -- 🔑 Product and classification
	 ps.product_id,
	 ps.product_category_name_english,
	 ps.product_category_segment,

	 -- 📦 Order details
	 o.order_id,
	 os.delivery_status,
	 o.order_purchase_timestamp,
	    
	 -- 📆 Time dimensions for Power BI slicing
	 YEAR(o.order_purchase_timestamp) AS order_year,
	 MONTH(o.order_purchase_timestamp) AS order_month,
	 DATENAME(MONTH, o.order_purchase_timestamp) AS order_month_name,
	 DATENAME(QUARTER, o.order_purchase_timestamp) AS order_quarter_name,
	 CONCAT(YEAR(o.order_purchase_timestamp) , '-', FORMAT(o.order_purchase_timestamp, 'MM')) AS year_month,
	 DATEFROMPARTS(YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp), 1) AS month_start_date,

	 -- 🧮 Sales metrics (exclude canceled orders from revenue/quantity)
	 CASE
		 WHEN os.delivery_status = 'canceled' THEN 0
		 ELSE COUNT(oi.order_item_id) 
	 END AS total_items_sold,

	 CASE
		WHEN os.delivery_status = 'canceled' THEN 0
		ELSE SUM(oi.price)
	 END AS total_item_revenue,
CAST(
	 CASE
		WHEN os.delivery_status = 'canceled' THEN NULL
		ELSE AVG(oi.price)
	 END AS DECIMAL(10,2)) AS avg_item_price

FROM olist_order_items_dataset oi
INNER JOIN olist_orders_dataset o
ON oi.order_id = o.order_id
INNER JOIN vw_product_segments ps
ON oi.product_id = ps.product_id
INNER JOIN vw_order_summary os
ON oi.order_id = os.order_id

GROUP BY
	ps.product_id,
	ps.product_category_name_english,
	ps.product_category_segment,
	o.order_id,
	os.delivery_status,
	o.order_purchase_timestamp;

-- =============================================================
-- 📄 VIEW: vw_category_segment_sales_summary
-- PURPOSE:
--   Summarize sales by product category and segment over time
--   Derived directly from vw_product_sales_summary for consistency
-- =============================================================

CREATE OR ALTER VIEW vw_category_segment_sales_summary AS
SELECT 
	   product_category_name_english,
	   product_category_segment,
	   order_year,
	   order_month,
	   order_month_name,
	   order_quarter_name,
	   year_month,
	   month_start_date,

	   SUM(total_items_sold) AS total_items_sold,
	   SUM(total_item_revenue) AS total_item_revenue,
	   CAST(SUM(total_item_revenue) / NULLIF(SUM(total_items_sold), 0) AS DECIMAL(10,2)) AS avg_item_price 

FROM vw_product_sales_summary
GROUP BY
	product_category_name_english,
    product_category_segment,
    order_year,
    order_month,
    order_month_name,
    order_quarter_name,
    year_month,
    month_start_date;


-- =============================================================
-- 📄 VIEW: vw_location_delivery_summary
-- PURPOSE:
--   Combines delivery performance, customer/seller location,
--   and product category/segment into a unified view.
--   Supports geographic delivery insight by both source and destination.
-- =============================================================

CREATE OR ALTER VIEW vw_location_delivery_summary AS 
SELECT 
    -- 📦 Product & Category Info
    ps.product_category_name_english,
    ps.product_category_segment,

    -- 🏠 Customer Location
    c.customer_city,
    c.customer_state,

    -- 🧾 Seller Location
    s.seller_city,
    s.seller_state,

    -- 📊 Delivery Status
    os.delivery_status,

    -- 📈 Average Delivery Duration
    AVG(os.delivery_duration_days) AS avg_delivery_duration,

    -- 📉 % of delayed deliveries
    CAST(
        100.0 * COUNT(CASE 
            WHEN os.delivery_status = 'Delivered'
             AND os.order_delivered_customer_date > os.order_estimated_delivery_date 
            THEN 1 
        END) / 
        NULLIF(COUNT(CASE WHEN os.delivery_status = 'Delivered' THEN 1 END), 0)
        AS DECIMAL(5,2)
    ) AS percent_delayed,

    -- 📈 % of on-time deliveries
    CAST(
        100.0 * COUNT(CASE 
            WHEN os.delivery_status = 'Delivered'
             AND os.order_delivered_customer_date <= os.order_estimated_delivery_date 
            THEN 1 
        END) / 
        NULLIF(COUNT(CASE WHEN os.delivery_status = 'Delivered' THEN 1 END), 0)
        AS DECIMAL(5,2)
    ) AS percent_on_time

FROM vw_order_summary os
INNER JOIN olist_customers_dataset c 
    ON os.customer_id = c.customer_id
INNER JOIN olist_order_items_dataset oi 
    ON os.order_id = oi.order_id
INNER JOIN olist_sellers_dataset s 
    ON oi.seller_id = s.seller_id
LEFT JOIN vw_product_segments ps 
    ON oi.product_id = ps.product_id

-- 📌 Aggregation grouping
GROUP BY 
    ps.product_category_name_english,
    ps.product_category_segment,
    c.customer_city,
    c.customer_state,
    s.seller_city,
    s.seller_state,
    os.delivery_status;


-- =============================================================
-- 💳 VIEW: vw_payment_summary
-- PURPOSE:
--   Analyze customer payment behavior across all methods.
--   Includes trends in payment type, installment use, and total/average spend.
-- =============================================================
CREATE OR ALTER VIEW vw_payment_summary AS 
SELECT 
    -- 💳 Payment Type & Mode
	p.payment_type,
	CASE 
		WHEN p.payment_installments > 1 THEN 'Installment'
		ELSE 'One-Time'
    END AS payment_mode,

	 -- 📍 Customer Location
	c.customer_city,
	c.customer_state,

	-- 📆 Time Dimensions
	YEAR(o.order_purchase_timestamp) AS order_year,
	MONTH(o.order_purchase_timestamp) AS order_month,
	DATENAME(MONTH, o.order_purchase_timestamp) AS order_month_name,
	DATENAME(QUARTER, o.order_purchase_timestamp) AS order_quarter_name,
	CONCAT(YEAR(o.order_purchase_timestamp), '-', FORMAT(o.order_purchase_timestamp,'MM')) AS year_month,
	DATEFROMPARTS(YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp), 1) AS month_start_date,

	-- 🧮 Aggregated Metrics
	COUNT(*) AS total_payments,
	SUM(p.payment_value) AS total_payment_value,
	CAST(AVG(p.payment_value) AS DECIMAL (10,2)) AS avg_payment_value,

	-- 📊 % Installment Usage
	CAST(
		100.0 * COUNT(CASE WHEN p.payment_installments > 1 THEN 1 END)/
		NULLIF(COUNT(*),0) AS DECIMAL(5,2)
    ) AS percent_installments


FROM olist_order_payments_dataset p
INNER JOIN olist_orders_dataset o
ON p.order_id = o.order_id
INNER JOIN olist_customers_dataset c
ON o.customer_id = c.customer_id

GROUP BY
p.payment_type,
CASE 
		WHEN p.payment_installments > 1 THEN 'Installment'
		ELSE 'One-Time'
    END,
c.customer_state,
c.customer_city,
YEAR(o.order_purchase_timestamp),
MONTH(o.order_purchase_timestamp),
DATENAME(MONTH, o.order_purchase_timestamp),
DATENAME(QUARTER, o.order_purchase_timestamp),
CONCAT(YEAR(o.order_purchase_timestamp), '-', FORMAT(o.order_purchase_timestamp, 'MM')),
DATEFROMPARTS(YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp), 1);

-- =============================================================
-- 👤 VIEW: vw_customer_behavior_summary
-- PURPOSE:
--   Summarize behavior for each customer:
--   order frequency, spend, weekday/weekend preference, installment use
-- =============================================================

CREATE OR ALTER VIEW vw_customer_behavior_summary AS
SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,

    -- 📦 Orders & Spend
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(os.total_order_value) AS total_spent,
    CAST(AVG(NULLIF(os.total_order_value, 0)) AS DECIMAL(10,2)) AS avg_order_value,

    -- 💳 Installment Usage
    COUNT(DISTINCT CASE 
        WHEN p.payment_installments > 1 THEN o.order_id 
    END) AS installment_orders,

    -- 📅 Day Preference
    COUNT(CASE WHEN os.purchase_day_type = 'Weekday' THEN 1 END) AS weekday_orders,
    COUNT(CASE WHEN os.purchase_day_type = 'Weekend' THEN 1 END) AS weekend_orders

FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o 
    ON c.customer_id = o.customer_id
INNER JOIN vw_order_summary os 
    ON o.order_id = os.order_id
LEFT JOIN olist_order_payments_dataset p 
    ON o.order_id = p.order_id

GROUP BY 
    c.customer_unique_id,
    c.customer_city,
    c.customer_state;

-- =============================================================
-- 👑 VIEW: vw_rfm_customer_segments
-- PURPOSE:
--   RFM scoring with both numeric & labeled categories
--   Uses dynamic reference date and business-friendly segments
-- =============================================================
CREATE OR ALTER VIEW vw_rfm_customer_segments AS 
WITH rfm_base AS (
	SELECT 
		c.customer_unique_id,
		MAX(o.order_purchase_timestamp) AS last_order_date,
		COUNT(DISTINCT o.order_id) AS order_frequency,
		SUM(os.total_order_value) AS monetary_value
	FROM olist_customers_dataset c
	INNER JOIN olist_orders_dataset o
	ON c.customer_id = o.customer_id
	INNER JOIN vw_order_summary os
	ON o.order_id = os.order_id
	WHERE os.delivery_status = 'delivered'
	GROUP BY c.customer_unique_id
),


scored AS(
	SELECT r.*,
		-- 🎯 Dynamic recency base
		DATEDIFF(DAY,last_order_date, MAX(last_order_date) OVER ()) AS recency_days
	FROM rfm_base r
),


percentiles AS (
	SELECT
		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY recency_days) OVER () AS r_p25,
		PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY recency_days) OVER () AS r_p50,
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY recency_days) OVER () AS r_p75,

		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY order_frequency) OVER () AS f_p25,
		PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY order_frequency) OVER () AS f_p50,
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY order_frequency) OVER () AS f_p75,

		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY monetary_value) OVER () AS m_p25,
		PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY monetary_value) OVER () AS m_p50,
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY monetary_value) OVER () AS m_p75
	FROM scored
),

rfm_score AS(
	SELECT s.*,
        p.r_p25, p.r_p50, p.r_p75,
        p.f_p25, p.f_p50, p.f_p75,
        p.m_p25, p.m_p50, p.m_p75,


		-- 🧠 Scoring (1 = best, 3 = worst)
		CASE 
			WHEN s.recency_days <= p.r_p25 THEN 1
			WHEN s.recency_days <= p.r_p50 THEN 2
			WHEN s.recency_days <= p.r_p75 THEN 3
			ELSE 4
		END AS recency_score,

		CASE 
			WHEN s.order_frequency >=  p.f_p75 THEN 1
			WHEN s.order_frequency >=  p.f_p50 THEN 2
			WHEN s.order_frequency >=  p.f_p25 THEN 3
			ELSE 4
		END AS frequency_score,

		CASE 
			WHEN s.monetary_value >= p.m_p75 THEN 1 
			WHEN s.monetary_value >=  p.m_p50 THEN 2
			WHEN s.monetary_value >=  p.m_p25 THEN 3
			ELSE 4
		END AS monetary_score
	FROM scored s
	CROSS JOIN percentiles p
)

-- 🏷️ Final Output
SELECT 
    customer_unique_id,
    last_order_date,
    recency_days,
    order_frequency,
    monetary_value,

    -- Scores
    recency_score,
    frequency_score,
    monetary_score,

	-- Score Labels
	CASE
		WHEN recency_score = 1 THEN 'Very Recent'
		WHEN recency_score = 2 THEN 'Recent'
		WHEN recency_score = 3 THEN 'Late'
		ELSE 'Inactive'
	END AS recency_category,

	CASE
		WHEN frequency_score = 1 THEN 'Frequent'
		WHEN frequency_score = 2 THEN 'Regular'
		WHEN frequency_score = 3 THEN 'Occasional'
		ELSE 'Rare'
	END AS frequency_category,

	CASE
		WHEN monetary_score = 1 THEN 'High Value'
		WHEN monetary_score = 2 THEN 'Mid Value'
		WHEN monetary_score = 3 THEN 'Low Value'
		ELSE 'Very Low'
	END AS monetary_category,

	 -- Final RFM Segment
CASE 
    WHEN recency_score = 1 AND frequency_score = 1 AND monetary_score = 1 THEN 'Champion'
    WHEN recency_score <= 2 AND monetary_score <= 2 THEN 'Loyal'
    WHEN recency_score IN (3,4) AND monetary_score IN (3,4) THEN 'At Risk'
    ELSE 'Others'
END AS rfm_segment


FROM rfm_score;

-- =============================================================
-- 👑 VIEW: vw_rfm_segments_only
-- PURPOSE:
--   Contains only customer ID and final RFM segment label.
--   Fastest option for joins and behavior breakdowns.
-- =============================================================

CREATE OR ALTER VIEW vw_rfm_segments_only AS
SELECT
	customer_unique_id,
	-- Final RFM Segment Classification
	CASE 
		WHEN recency_score = 1 AND frequency_score = 1 AND monetary_score = 1 THEN 'Champion'
		WHEN recency_score <= 2 AND monetary_score <= 2 THEN 'Loyal'
		WHEN recency_score IN (3,4) AND monetary_score IN (3,4) THEN 'At Risk'
		ELSE 'Others'
	END AS rfm_segment
FROM vw_rfm_customer_segments;


 -- ================================================================
-- 📊 VIEW: vw_summary_kpis
-- PURPOSE:
--   Master summary of business performance metrics.
--   Includes orders, revenue, delivery, and behavior trends.
-- ================================================================
CREATE OR ALTER VIEW vw_summary_kpis AS 
SELECT 
    -- 📦 Orders
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN delivery_status = 'Delivered' THEN order_id END) AS total_delivered_orders,
    COUNT(DISTINCT CASE WHEN delivery_status = 'Canceled' THEN order_id END) AS total_canceled_orders,

    -- 📦 Items
    SUM(total_items) AS total_items_sold,

    -- 💰 Revenue & Freight
    SUM(total_order_value) AS total_revenue,
    SUM(total_freight_value) AS total_freight_value,
    CAST(AVG(NULLIF(total_order_value, 0)) AS DECIMAL(10, 2)) AS avg_order_value,

    -- ⏱️ Delivery Speed
    CAST(AVG(delivery_duration_days) AS DECIMAL(10, 2)) AS avg_delivery_duration_days,

    -- ⏰ On-Time vs Delayed %
    CAST(
        100.0 * COUNT(CASE 
            WHEN delivery_status = 'Delivered' 
             AND order_delivered_customer_date <= order_estimated_delivery_date 
            THEN 1 
        END) / 
        NULLIF(COUNT(CASE WHEN delivery_status = 'Delivered' THEN 1 END), 0)
        AS DECIMAL(5,2)
    ) AS percent_on_time_delivery,

    CAST(
        100.0 * COUNT(CASE 
            WHEN delivery_status = 'Delivered' 
             AND order_delivered_customer_date > order_estimated_delivery_date 
            THEN 1 
        END) / 
        NULLIF(COUNT(CASE WHEN delivery_status = 'Delivered' THEN 1 END), 0)
        AS DECIMAL(5,2)
    ) AS percent_delayed_delivery,

    -- 📅 Order Frequency (per month)
    CAST(
        COUNT(DISTINCT order_id) * 1.0 / 
        NULLIF(DATEDIFF(MONTH, MIN(order_purchase_timestamp), MAX(order_purchase_timestamp)), 0)
        AS DECIMAL(10,2)
    ) AS avg_orders_per_month,

    -- 💳 Installment Behavior
    (
        SELECT COUNT(DISTINCT o.order_id)
        FROM olist_order_payments_dataset p
        INNER JOIN olist_orders_dataset o 
            ON o.order_id = p.order_id
        WHERE p.payment_installments > 1
    ) AS total_inst
FROM vw_order_summary;

-- ================================================================
-- 📊 BUSINESS ANALYSIS & INSIGHTS
-- PURPOSE:
--   Explore key business questions using SQL queries
--   Structured by topic: Sales, Customers, Delivery, Payments, etc.
-- ================================================================

-- ==========================================================================================
-- 📦 SECTION 1: SALES & PRODUCT PERFORMANCE
-- PURPOSE:
--   Analyze revenue, product performance, customer value
--   across time (monthly, quarterly, yearly), category, and quantity
-- ==========================================================================================

-- 🔢 PART 1: Total Revenue, Items Sold, Average Order Value
-- Purpose: Measure overall performance metrics from delivered orders
SELECT 
    SUM(total_order_value) AS total_revenue,
    SUM(total_items) AS total_items_sold,
    CAST(AVG(NULLIF(total_order_value, 0)) AS DECIMAL(10,2)) AS avg_order_value
FROM vw_order_summary
WHERE delivery_status = 'Delivered';

-- 🔢 PART 2: Order Size Distribution (% of Orders by Item Count)
-- Purpose: Show how many items are typically included in orders
SELECT 
    total_items,
    COUNT(*) AS num_orders,
    CAST(100.0 * COUNT(*) / 
         NULLIF((SELECT COUNT(*) FROM vw_order_summary WHERE delivery_status = 'Delivered'), 0)
         AS DECIMAL(5,2)) AS percent_of_orders
FROM vw_order_summary
WHERE delivery_status = 'Delivered'
GROUP BY total_items
ORDER BY total_items;

-- 📅 PART 3: Monthly Revenue & Order Trends (Each Year)
-- Purpose: Track monthly revenue and order activity per year
SELECT 
    YEAR(order_purchase_timestamp) AS order_year,
    MONTH(order_purchase_timestamp) AS order_month,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(total_order_value) AS total_revenue,
    SUM(total_items) AS total_items_sold,
    CAST(SUM(total_order_value) / NULLIF(COUNT(DISTINCT order_id), 0) AS DECIMAL(10,2)) AS avg_order_value
FROM vw_order_summary
WHERE delivery_status = 'Delivered'
GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
ORDER BY order_year, order_month;

-- 📅 PART 4: Monthly Revenue & Order Trends (All Years Combined)
-- Purpose: Compare monthly seasonality across all years
SELECT 
    MONTH(order_purchase_timestamp) AS order_month,
    DATENAME(MONTH, order_purchase_timestamp) AS month_name,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(total_order_value) AS total_revenue,
    SUM(total_items) AS total_items_sold,
    CAST(SUM(total_order_value) / NULLIF(COUNT(DISTINCT order_id), 0) AS DECIMAL(10,2)) AS avg_order_value
FROM vw_order_summary
WHERE delivery_status = 'Delivered'
GROUP BY MONTH(order_purchase_timestamp), DATENAME(MONTH, order_purchase_timestamp)
ORDER BY order_month;

-- 📅 PART 5: Quarterly Revenue Trends (Each Year)
-- Purpose: Track quarterly sales performance across different years
SELECT 
    YEAR(order_purchase_timestamp) AS order_year,
    DATEPART(QUARTER, order_purchase_timestamp) AS order_quarter,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(total_order_value) AS total_revenue
FROM vw_order_summary
WHERE delivery_status = 'Delivered'
GROUP BY YEAR(order_purchase_timestamp), DATEPART(QUARTER, order_purchase_timestamp)
ORDER BY order_year, order_quarter;

-- 📅 PART 6: Quarterly Revenue Trends (All Years Combined)
-- Purpose: Compare average order value and quantity by quarter
SELECT 
    DATEPART(QUARTER, order_purchase_timestamp) AS order_quarter,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(total_order_value) AS total_revenue,
    SUM(total_items) AS total_items_sold,
    CAST(SUM(total_order_value) / NULLIF(COUNT(DISTINCT order_id), 0) AS DECIMAL(10,2)) AS avg_order_value
FROM vw_order_summary
WHERE delivery_status = 'Delivered'
GROUP BY DATEPART(QUARTER, order_purchase_timestamp)
ORDER BY total_revenue DESC;

-- 📅 PART 7: Yearly Revenue Trends
-- Purpose: Show total revenue and orders per year
SELECT 
    YEAR(order_purchase_timestamp) AS order_year,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(total_order_value) AS total_revenue
FROM vw_order_summary
WHERE delivery_status = 'Delivered'
GROUP BY YEAR(order_purchase_timestamp)
ORDER BY order_year;

-- 📈 PART 8: Monthly Revenue Growth %
-- Purpose: Measure month-over-month revenue change
WITH monthly_sales AS (
    SELECT 
        year_month,
        SUM(total_item_revenue) AS monthly_revenue
    FROM vw_product_sales_summary
    GROUP BY year_month
)
SELECT 
    year_month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY year_month) AS prev_month_revenue,
    CAST(
        (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY year_month)) * 100.0 /
        NULLIF(LAG(monthly_revenue) OVER (ORDER BY year_month), 0)
    AS DECIMAL(10,2)) AS revenue_growth_percent
FROM monthly_sales;

-- 🏷️ PART 9: Monthly Top & Bottom 3 Segments by Revenue
-- Purpose: Highlight best and worst-performing segments each month
WITH segment_month_revenue AS (
    SELECT 
        product_category_segment,
        MONTH(order_purchase_timestamp) AS order_month,
        DATENAME(MONTH, order_purchase_timestamp) AS month_name,
        SUM(total_item_revenue) AS total_revenue
    FROM vw_product_sales_summary
    GROUP BY product_category_segment, MONTH(order_purchase_timestamp), DATENAME(MONTH, order_purchase_timestamp)
),
ranked_segments AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY order_month ORDER BY total_revenue DESC) AS rank_desc,
        ROW_NUMBER() OVER (PARTITION BY order_month ORDER BY total_revenue ASC) AS rank_asc
    FROM segment_month_revenue
)
SELECT 
    order_month,
    month_name,
    product_category_segment,
    total_revenue,
    'Top' AS position
FROM ranked_segments
WHERE rank_desc <= 3
UNION ALL
SELECT 
    order_month,
    month_name,
    product_category_segment,
    total_revenue,
    'Bottom' AS position
FROM ranked_segments
WHERE rank_asc <= 3
ORDER BY order_month, total_revenue DESC;

-- 🏷️ PART 10: Revenue & Quantity by Product Segment
-- Purpose: Understand which product segments contribute most to revenue and volume
SELECT 
    product_category_segment,
    SUM(total_item_revenue) AS total_segment_revenue,
    SUM(total_items_sold) AS total_segment_quantity
FROM vw_product_sales_summary
GROUP BY product_category_segment
ORDER BY total_segment_revenue DESC;

-- 🏷️ PART 11: Revenue & Quantity by Product Category
-- Purpose: Provide more granular view at the product category level
SELECT 
    product_category_name_english,
    SUM(total_item_revenue) AS total_category_revenue,
    SUM(total_items_sold) AS total_category_quantity
FROM vw_product_sales_summary
GROUP BY product_category_name_english
ORDER BY total_category_revenue DESC;

-- 🥇 PART 12: Top 10 Product Categories by Revenue
-- Purpose: Identify top-performing product categories by sales value
SELECT 
    product_category_name_english,
    SUM(total_item_revenue) AS category_revenue
FROM vw_product_sales_summary
GROUP BY product_category_name_english
ORDER BY category_revenue DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- 🥇 PART 13: Top 10 Product Categories by Quantity
-- Purpose: Identify most frequently sold product categories
SELECT 
    product_category_name_english,
    SUM(total_items_sold) AS category_quantity
FROM vw_product_sales_summary
GROUP BY product_category_name_english
ORDER BY category_quantity DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- ❌ PART 14: Bottom 10 Product Categories by Revenue
-- Purpose: Show least valuable product categories by sales
SELECT 
    product_category_name_english,
    SUM(total_item_revenue) AS category_revenue
FROM vw_product_sales_summary
GROUP BY product_category_name_english
ORDER BY category_revenue ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- ❌ PART 15: Bottom 10 Product Categories by Quantity
-- Purpose: Show product categories with lowest sales volume
SELECT 
    product_category_name_english,
    SUM(total_items_sold) AS category_quantity
FROM vw_product_sales_summary
GROUP BY product_category_name_english
ORDER BY category_quantity ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- 🥇 PART 16: Top 10 Segments by Revenue
-- Purpose: Identify best-performing product segments by revenue
SELECT 
    product_category_segment,
    SUM(total_item_revenue) AS total_segment_revenue
FROM vw_product_sales_summary
GROUP BY product_category_segment
ORDER BY total_segment_revenue DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- 🥇 PART 17: Top 10 Segments by Quantity
-- Purpose: Identify most frequently sold product segments
SELECT 
    product_category_segment,
    SUM(total_items_sold) AS total_segment_quantity
FROM vw_product_sales_summary
GROUP BY product_category_segment
ORDER BY total_segment_quantity DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- ❌ PART 18: Bottom 10 Segments by Revenue
-- Purpose: Show segments contributing least to overall revenue
SELECT 
    product_category_segment,
    SUM(total_item_revenue) AS total_segment_revenue
FROM vw_product_sales_summary
GROUP BY product_category_segment
ORDER BY total_segment_revenue ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- ❌ PART 19: Bottom 10 Segments by Quantity
-- Purpose: Show segments with lowest product movement volume
SELECT 
    product_category_segment,
    SUM(total_items_sold) AS total_segment_quantity
FROM vw_product_sales_summary
GROUP BY product_category_segment
ORDER BY total_segment_quantity ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- 🧑‍🤝‍🧑 PART 20: Avg Revenue per Customer by Segment
-- Purpose: Understand how much revenue is generated per customer by segment
SELECT 
    ps.product_category_segment,
    COUNT(DISTINCT os.customer_id) AS unique_customers,
    SUM(ps.total_item_revenue) AS total_revenue,
    CAST(SUM(ps.total_item_revenue) / NULLIF(COUNT(DISTINCT os.customer_id), 0) AS DECIMAL(10,2)) AS avg_revenue_per_customer
FROM vw_product_sales_summary ps
INNER JOIN vw_order_summary os
    ON ps.order_id = os.order_id
GROUP BY ps.product_category_segment;



-- ==========================================================================================
-- 👥 SECTION 2: CUSTOMER BEHAVIOR & SEGMENTATION
-- PURPOSE:
--   Analyze customer loyalty, purchase patterns, installment usage,
--   weekday/weekend behavior, and segment performance using RFM.
--   
--   ⚠️ Note: Some queries that originally joined multiple complex views were rewritten
--   using IN (...) filters to avoid performance issues with SQL Server in local environments.
--   This approach reduces memory usage and improves execution time.
-- ==========================================================================================


-- 🔢 PART 1: Unique Customers and Order Frequency
-- Purpose: Get the number of unique customers and how often they order
SELECT 
    COUNT(DISTINCT customer_unique_id) AS total_customers
FROM vw_customer_behavior_summary;


-- 🔢 PART 2: Order Frequency Distribution
-- Purpose: Understand how often customers buy
SELECT 
    total_orders,
    COUNT(*) AS customer_count
FROM vw_customer_behavior_summary
GROUP BY total_orders
ORDER BY total_orders;


-- 💳 PART 3: Installment vs One-Time Usage
-- Purpose: Identify total and percent of customers using installments vs one-time payments
SELECT 
    SUM(installment_orders) AS total_installment_orders,
    SUM(total_orders) - SUM(installment_orders) AS total_one_time_orders,
    CAST(SUM(installment_orders) * 100.0 / NULLIF(SUM(total_orders), 0) AS DECIMAL(5,2)) AS percent_installment_orders,
    CAST((SUM(total_orders) - SUM(installment_orders)) * 100.0 / NULLIF(SUM(total_orders), 0) AS DECIMAL(5,2)) AS percent_one_time_orders
FROM vw_customer_behavior_summary;


-- 💡 Note:
-- This query was originally written using a JOIN with the RFM view,
-- but I optimized it using an IN (...) filter for each segment to
-- avoid performance issues and long execution time in SQL Server.

-- 💳 PART 4: Installment vs One-Time Usage by RFM Segment (Optimized with IN filter)
-- Purpose: Run per segment to avoid heavy joins and speed up analysis

SELECT 
    'Champion' AS rfm_segment,
    COUNT(*) AS customer_count,
    SUM(installment_orders) AS total_installment_orders,
    SUM(total_orders) - SUM(installment_orders) AS total_one_time_orders,
    CAST(SUM(installment_orders) * 100.0 / NULLIF(SUM(total_orders), 0) AS DECIMAL(5,2)) AS percent_installment_orders,
    CAST((SUM(total_orders) - SUM(installment_orders)) * 100.0 / NULLIF(SUM(total_orders), 0) AS DECIMAL(5,2)) AS percent_one_time_orders
FROM vw_customer_behavior_summary
WHERE customer_unique_id IN (
    SELECT customer_unique_id FROM vw_rfm_segments_only WHERE rfm_segment = 'Champion'
)

UNION ALL

SELECT 
    'Loyal',
    COUNT(*),
    SUM(installment_orders),
    SUM(total_orders) - SUM(installment_orders),
    CAST(SUM(installment_orders) * 100.0 / NULLIF(SUM(total_orders), 0) AS DECIMAL(5,2)),
    CAST((SUM(total_orders) - SUM(installment_orders)) * 100.0 / NULLIF(SUM(total_orders), 0) AS DECIMAL(5,2))
FROM vw_customer_behavior_summary
WHERE customer_unique_id IN (
    SELECT customer_unique_id FROM vw_rfm_segments_only WHERE rfm_segment = 'Loyal'
)

UNION ALL

SELECT 
    'At Risk',
    COUNT(*),
    SUM(installment_orders),
    SUM(total_orders) - SUM(installment_orders),
    CAST(SUM(installment_orders) * 100.0 / NULLIF(SUM(total_orders), 0) AS DECIMAL(5,2)),
    CAST((SUM(total_orders) - SUM(installment_orders)) * 100.0 / NULLIF(SUM(total_orders), 0) AS DECIMAL(5,2))
FROM vw_customer_behavior_summary
WHERE customer_unique_id IN (
    SELECT customer_unique_id FROM vw_rfm_segments_only WHERE rfm_segment = 'At Risk'
)

UNION ALL

SELECT 
    'Others',
    COUNT(*),
    SUM(installment_orders),
    SUM(total_orders) - SUM(installment_orders),
    CAST(SUM(installment_orders) * 100.0 / NULLIF(SUM(total_orders), 0) AS DECIMAL(5,2)),
    CAST((SUM(total_orders) - SUM(installment_orders)) * 100.0 / NULLIF(SUM(total_orders), 0) AS DECIMAL(5,2))
FROM vw_customer_behavior_summary
WHERE customer_unique_id IN (
    SELECT customer_unique_id FROM vw_rfm_segments_only WHERE rfm_segment = 'Others'
);


-- 📅 PART 5: Weekday vs Weekend Order Behavior
-- Purpose: Understand when customers prefer to shop
SELECT 
    SUM(weekday_orders) AS total_weekday_orders,
    SUM(weekend_orders) AS total_weekend_orders,
    CAST(SUM(weekend_orders) * 100.0 / NULLIF(SUM(weekday_orders + weekend_orders), 0) AS DECIMAL(5,2)) AS weekend_order_percent,
    CAST(SUM(weekday_orders) * 100.0 / NULLIF(SUM(weekday_orders + weekend_orders), 0) AS DECIMAL(5,2)) AS weekday_order_percent
FROM vw_customer_behavior_summary;


-- 💸 PART 6: Total and Average Spend per Customer
-- Purpose: Understand how much customers spend overall and per order
SELECT 
    ROUND(AVG(total_spent), 2) AS avg_total_spent,
    ROUND(AVG(avg_order_value), 2) AS avg_order_value,
    ROUND(AVG(total_orders), 2) AS avg_orders_per_customer
FROM vw_customer_behavior_summary;


-- 📊 PART 7: RFM Segment Distribution
-- Purpose: Show counts and % of customers in each RFM segment
WITH segment_counts AS (
  SELECT rfm_segment, COUNT_BIG(*) AS customer_count
  FROM vw_rfm_segments_only
  GROUP BY rfm_segment
),
total_customers AS (
  SELECT COUNT_BIG(*) AS total FROM vw_rfm_segments_only
)
SELECT 
  sc.rfm_segment,
  sc.customer_count,
  CAST(100.0 * sc.customer_count / NULLIF(tc.total, 0) AS DECIMAL(5,2)) AS percent_of_customers
FROM segment_counts sc
CROSS JOIN total_customers tc
ORDER BY customer_count DESC;


-- 💡 Note:
-- To avoid slow performance from joining two large views,
-- I rewrote this query using IN (...) filtering per segment.

-- 📊 PART 8: Avg Order Value and Frequency by RFM Segment (IN-based filtering)
-- Purpose: Avoid JOINs for better performance
SELECT 
    'Champion' AS rfm_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_orders), 2) AS avg_orders,
    ROUND(AVG(total_spent), 2) AS avg_spent,
    ROUND(AVG(avg_order_value), 2) AS avg_order_value
FROM vw_customer_behavior_summary
WHERE customer_unique_id IN (
    SELECT customer_unique_id FROM vw_rfm_segments_only WHERE rfm_segment = 'Champion'
)

UNION ALL

SELECT 
    'Loyal',
    COUNT(*),
    ROUND(AVG(total_orders), 2),
    ROUND(AVG(total_spent), 2),
    ROUND(AVG(avg_order_value), 2)
FROM vw_customer_behavior_summary
WHERE customer_unique_id IN (
    SELECT customer_unique_id FROM vw_rfm_segments_only WHERE rfm_segment = 'Loyal'
)

UNION ALL

SELECT 
    'At Risk',
    COUNT(*),
    ROUND(AVG(total_orders), 2),
    ROUND(AVG(total_spent), 2),
    ROUND(AVG(avg_order_value), 2)
FROM vw_customer_behavior_summary
WHERE customer_unique_id IN (
    SELECT customer_unique_id FROM vw_rfm_segments_only WHERE rfm_segment = 'At Risk'
)

UNION ALL

SELECT 
    'Others',
    COUNT(*),
    ROUND(AVG(total_orders), 2),
    ROUND(AVG(total_spent), 2),
    ROUND(AVG(avg_order_value), 2)
FROM vw_customer_behavior_summary
WHERE customer_unique_id IN (
    SELECT customer_unique_id FROM vw_rfm_segments_only WHERE rfm_segment = 'Others'
);


-- 💡 Note:
-- I used IN (...) filters here instead of JOINs to improve execution speed
-- and reduce memory usage during aggregation by RFM segment.

-- 📊 PART 9: Revenue Contribution by Segment (IN-based filtering)
-- Purpose: Avoid JOINs for performance
SELECT 
    'Champion' AS rfm_segment,
    SUM(total_spent) AS segment_total_spent,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_spent) / NULLIF(COUNT(*), 0), 2) AS avg_spent_per_customer
FROM vw_customer_behavior_summary
WHERE customer_unique_id IN (
    SELECT customer_unique_id FROM vw_rfm_segments_only WHERE rfm_segment = 'Champion'
)

UNION ALL

SELECT 
    'Loyal',
    SUM(total_spent),
    COUNT(*),
    ROUND(SUM(total_spent) / NULLIF(COUNT(*), 0), 2)
FROM vw_customer_behavior_summary
WHERE customer_unique_id IN (
    SELECT customer_unique_id FROM vw_rfm_segments_only WHERE rfm_segment = 'Loyal'
)

UNION ALL

SELECT 
    'At Risk',
    SUM(total_spent),
    COUNT(*),
    ROUND(SUM(total_spent) / NULLIF(COUNT(*), 0), 2)
FROM vw_customer_behavior_summary
WHERE customer_unique_id IN (
    SELECT customer_unique_id FROM vw_rfm_segments_only WHERE rfm_segment = 'At Risk'
)

UNION ALL

SELECT 
    'Others',
    SUM(total_spent),
    COUNT(*),
    ROUND(SUM(total_spent) / NULLIF(COUNT(*), 0), 2)
FROM vw_customer_behavior_summary
WHERE customer_unique_id IN (
    SELECT customer_unique_id FROM vw_rfm_segments_only WHERE rfm_segment = 'Others'
);


-- 📈 PART 10: Strategic Insight - Pareto (Top 20% Customers = % Revenue)
-- Purpose: Show how much revenue comes from your most valuable 20% of customers
WITH ranked_customers AS (
  SELECT *,
         ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank_by_spend,
         COUNT(*) OVER () AS total_customers
  FROM vw_customer_behavior_summary
),
top_20_percent AS (
  SELECT *
  FROM ranked_customers
  WHERE rank_by_spend <= total_customers * 0.2
)
SELECT 
  COUNT(*) AS top_20_percent_customers,
  SUM(total_spent) AS top_20_percent_revenue,
  CAST(100.0 * SUM(total_spent) / 
       NULLIF((SELECT SUM(total_spent) FROM vw_customer_behavior_summary), 0) AS DECIMAL(5,2)) AS percent_of_total_revenue
FROM top_20_percent;

-- ==========================================================================================
-- 🚚 SECTION 3: DELIVERY & LOCATION INSIGHTS
-- PURPOSE:
--   Analyze delivery performance across customers, sellers, locations, and product segments
--   to understand delays, shipping times, and geographic impacts on fulfillment.
-- ==========================================================================================


-- ⏱️ PART 1: On-Time vs Delayed Deliveries (KPI)
-- Purpose: What % of delivered orders arrived on time vs. delayed?
SELECT 
    COUNT(*) AS total_delivered_orders,
    SUM(CASE 
        WHEN delivery_status = 'Delivered' AND order_delivered_customer_date <= order_estimated_delivery_date 
        THEN 1 ELSE 0 END) AS on_time_orders,
    SUM(CASE 
        WHEN delivery_status = 'Delivered' AND order_delivered_customer_date > order_estimated_delivery_date 
        THEN 1 ELSE 0 END) AS delayed_orders,
    CAST(100.0 * SUM(CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END) / 
        NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS percent_on_time,
    CAST(100.0 * SUM(CASE 
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) / 
        NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS percent_delayed
FROM vw_order_summary
WHERE delivery_status = 'Delivered';


-- 🚀 PART 2: Average Delivery Duration (Days)
-- Purpose: How long does it take to deliver orders on average?
SELECT 
    CAST(AVG(delivery_duration_days) AS DECIMAL(10,2)) AS avg_delivery_days
FROM vw_order_summary
WHERE delivery_status = 'Delivered';


-- 🔄 PART 3: Order Count by Delivery Status
-- Purpose: See how many orders are in each delivery stage
SELECT 
    delivery_status,
    COUNT(*) AS order_count
FROM vw_order_summary
GROUP BY delivery_status
ORDER BY order_count DESC;


-- 📅 PART 4: Monthly Delivery Duration Trends
-- Purpose: Track delivery speed over time
SELECT 
    YEAR(order_purchase_timestamp) AS order_year,
    MONTH(order_purchase_timestamp) AS order_month,
    CAST(AVG(delivery_duration_days) AS DECIMAL(10,2)) AS avg_delivery_days
FROM vw_order_summary
WHERE delivery_status = 'Delivered'
GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
ORDER BY order_year, order_month;


-- 🗺️ PART 5: Top Customer States by Customer Count
-- Purpose: Where are the majority of customers located?
SELECT 
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS num_customers
FROM olist_customers_dataset
GROUP BY customer_state
ORDER BY num_customers DESC;


-- 🏡 PART 6: Avg Delivery Duration by Customer State
-- Purpose: Which customer states receive fastest vs slowest?
SELECT 
    c.customer_state,
    COUNT(*) AS total_orders,
    CAST(AVG(o.delivery_duration_days) AS DECIMAL(10,2)) AS avg_delivery_days
FROM vw_order_summary o
INNER JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.delivery_status = 'Delivered'
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;


-- 🧯 PART 7: % On-Time & Delayed Orders by Customer State
-- Purpose: Which states experience the most delays?
SELECT 
    c.customer_state,
    COUNT(*) AS total_delivered_orders,
    CAST(SUM(CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS percent_on_time,
    CAST(SUM(CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS percent_delayed
FROM vw_order_summary o
INNER JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.delivery_status = 'Delivered'
GROUP BY c.customer_state
ORDER BY percent_delayed DESC;


-- 🧑‍🏭 PART 8: Top Seller States by Seller Count
-- Purpose: Where are most sellers located?
SELECT 
    seller_state,
    COUNT(DISTINCT seller_id) AS num_sellers
FROM olist_sellers_dataset
GROUP BY seller_state
ORDER BY num_sellers DESC;


-- 🚚 PART 9: Delivery Duration by Seller State
-- Purpose: Which seller locations deliver fastest?
SELECT 
    s.seller_state,
    COUNT(*) AS total_delivered_orders,
    CAST(AVG(o.delivery_duration_days) AS DECIMAL(10,2)) AS avg_delivery_days
FROM vw_order_summary o
INNER JOIN olist_order_items_dataset i ON o.order_id = i.order_id
INNER JOIN olist_sellers_dataset s ON i.seller_id = s.seller_id
WHERE o.delivery_status = 'Delivered'
GROUP BY s.seller_state
ORDER BY avg_delivery_days DESC;


-- ⏳ PART 10: % On-Time & Delayed Deliveries by Seller State
-- Purpose: On-time rate for sellers by region
SELECT 
    s.seller_state,
    COUNT(*) AS total_delivered_orders,
    CAST(SUM(CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS percent_on_time,
    CAST(SUM(CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS percent_delayed
FROM vw_order_summary o
INNER JOIN olist_order_items_dataset i ON o.order_id = i.order_id
INNER JOIN olist_sellers_dataset s ON i.seller_id = s.seller_id
WHERE o.delivery_status = 'Delivered'
GROUP BY s.seller_state
ORDER BY percent_delayed DESC;


-- 🧊 PART 11: Avg Delivery Duration by Product Segment
-- Purpose: Which product segments take longer to deliver?
SELECT 
    p.product_category_segment,
    COUNT(*) AS total_orders,
    CAST(AVG(o.delivery_duration_days) AS DECIMAL(10,2)) AS avg_delivery_days
FROM vw_order_summary o
INNER JOIN olist_order_items_dataset i ON o.order_id = i.order_id
INNER JOIN vw_product_segments p ON i.product_id = p.product_id
WHERE o.delivery_status = 'Delivered'
GROUP BY p.product_category_segment
ORDER BY avg_delivery_days DESC;


-- ❄️ PART 12: % On-Time & Delayed Orders by Product Segment
-- Purpose: Are some segments more delay-prone?
SELECT 
    p.product_category_segment,
    COUNT(*) AS total_orders,
    CAST(SUM(CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS percent_on_time,
    CAST(SUM(CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS percent_delayed
FROM vw_order_summary o
INNER JOIN olist_order_items_dataset i ON o.order_id = i.order_id
INNER JOIN vw_product_segments p ON i.product_id = p.product_id
WHERE o.delivery_status = 'Delivered'
GROUP BY p.product_category_segment
ORDER BY percent_delayed DESC;


-- 🔁 PART 13: Most Common Seller–Customer Location Pairs
-- Purpose: High-volume seller–customer region combos
SELECT 
    s.seller_state,
    c.customer_state,
    COUNT(*) AS num_orders
FROM vw_order_summary o
INNER JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
INNER JOIN olist_order_items_dataset i ON o.order_id = i.order_id
INNER JOIN olist_sellers_dataset s ON i.seller_id = s.seller_id
WHERE o.delivery_status = 'Delivered'
GROUP BY s.seller_state, c.customer_state
ORDER BY num_orders DESC;


-- 🚀 PART 14: Fastest Shipping Pairs (Seller → Customer)
-- Purpose: Efficient shipping paths
SELECT 
    s.seller_state,
    c.customer_state,
    COUNT(*) AS num_orders,
    CAST(AVG(o.delivery_duration_days) AS DECIMAL(10,2)) AS avg_delivery_days
FROM vw_order_summary o
INNER JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
INNER JOIN olist_order_items_dataset i ON o.order_id = i.order_id
INNER JOIN olist_sellers_dataset s ON i.seller_id = s.seller_id
WHERE o.delivery_status = 'Delivered'
GROUP BY s.seller_state, c.customer_state
ORDER BY avg_delivery_days ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;


-- 💰 PART 15: Revenue by Seller–Customer State Pair
-- Purpose: Revenue distribution by shipping route
SELECT 
    s.seller_state,
    c.customer_state,
    SUM(o.total_order_value) AS route_revenue
FROM vw_order_summary o
INNER JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
INNER JOIN olist_order_items_dataset i ON o.order_id = i.order_id
INNER JOIN olist_sellers_dataset s ON i.seller_id = s.seller_id
WHERE o.delivery_status = 'Delivered'
GROUP BY s.seller_state, c.customer_state
ORDER BY route_revenue DESC;


-- 🏆 PART 16: Top 5 Customer States by Revenue, Quantity, Delivery
-- Purpose: Compare regions by value and shipping performance
SELECT 
    c.customer_state,
    SUM(o.total_order_value) AS total_revenue,
    SUM(o.total_items) AS total_quantity,
    CAST(AVG(o.delivery_duration_days) AS DECIMAL(10,2)) AS avg_delivery_days
FROM vw_order_summary o
INNER JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.delivery_status = 'Delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;


-- 🥇 PART 17: Top 5 Seller States by Revenue, Quantity, Punctuality
-- Purpose: Evaluate seller regions by sales and on-time performance
SELECT 
    s.seller_state,
    SUM(o.total_order_value) AS total_revenue,
    SUM(o.total_items) AS total_quantity,
    CAST(SUM(CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS percent_on_time,
    CAST(SUM(CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS percent_delayed
FROM vw_order_summary o
INNER JOIN olist_order_items_dataset i ON o.order_id = i.order_id
INNER JOIN olist_sellers_dataset s ON i.seller_id = s.seller_id
WHERE o.delivery_status = 'Delivered'
GROUP BY s.seller_state
ORDER BY total_revenue DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;


-- ⚠️ PART 18: Bottom 5 States or Cities by Delay Rate
-- Purpose: Highlight locations with worst delivery performance
SELECT TOP 5 
    c.customer_state,
    c.customer_city,
    COUNT(*) AS total_orders,
    CAST(SUM(CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / 
         NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS percent_delayed,
    CAST(SUM(CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / 
         NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS percent_on_time
FROM vw_order_summary o
INNER JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.delivery_status = 'Delivered'
GROUP BY c.customer_state, c.customer_city
ORDER BY percent_delayed DESC;


-- =========================================================================================
-- 💳 SECTION 4: PAYMENT BEHAVIOR ANALYSIS
-- PURPOSE:
--   Analyze how customers pay, how much they pay, and how behavior varies by type,
--   region, time, and value. Uncover installment usage, delivery impact, and revenue insights.
-- =========================================================================================

-- 🔢 PART 1: Total Payments Overview
-- Purpose: Understand total volume and value of all payments
SELECT 
    COUNT(*) AS total_payments,
    SUM(payment_value) AS total_payment_value,
    CAST(AVG(payment_value) AS DECIMAL(10,2)) AS avg_payment_value
FROM olist_order_payments_dataset;


-- 📊 PART 2: Payment Method Distribution
-- Purpose: See which payment types are most used and their contribution
SELECT 
    payment_type,
    COUNT(*) AS num_payments,
    CAST(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM olist_order_payments_dataset), 0) AS DECIMAL(5,2)) AS percent_of_payments,
    SUM(payment_value) AS total_value,
    CAST(AVG(payment_value) AS DECIMAL(10,2)) AS avg_value
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_value DESC;


-- 💳 PART 3: Installment Behavior – Avg Number of Installments
-- Purpose: Understand how many installments are typically used when not paying one-time
SELECT 
    payment_type,
    COUNT(*) AS installment_payments,
    CAST(AVG(payment_installments * 1.0) AS DECIMAL(10,2)) AS avg_installments
FROM olist_order_payments_dataset
WHERE payment_installments > 1
GROUP BY payment_type
ORDER BY avg_installments DESC;


-- 📅 PART 4: Monthly Payment Trends by Type
-- Purpose: Track usage of each payment type over time
SELECT 
    YEAR(o.order_purchase_timestamp) AS order_year,
    MONTH(o.order_purchase_timestamp) AS order_month,
    p.payment_type,
    COUNT(*) AS num_payments,
    SUM(p.payment_value) AS total_value
FROM olist_order_payments_dataset p
INNER JOIN vw_order_summary o ON p.order_id = o.order_id
GROUP BY 
    YEAR(o.order_purchase_timestamp),
    MONTH(o.order_purchase_timestamp),
    p.payment_type
ORDER BY order_year, order_month, total_value DESC;


-- 📈 PART 5: Installment Usage Over Time
-- Purpose: See if installment usage affects delivery over time
SELECT 
    YEAR(o.order_purchase_timestamp) AS order_year,
    MONTH(o.order_purchase_timestamp) AS order_month,
    COUNT(CASE WHEN p.payment_installments > 1 THEN 1 END) AS installment_orders,
    COUNT(CASE WHEN p.payment_installments = 1 THEN 1 END) AS one_time_orders,
    COUNT(*) AS total_orders,
    CAST(100.0 * COUNT(CASE WHEN p.payment_installments > 1 THEN 1 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS percent_installment_usage,
    CAST(100.0 * COUNT(CASE WHEN p.payment_installments = 1 THEN 1 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS percent_one_time_usage,
    COUNT(CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 END) AS on_time_orders,
    COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) AS delayed_orders,
    CAST(100.0 * COUNT(CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS percent_on_time,
    CAST(100.0 * COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS percent_delayed
FROM olist_order_payments_dataset p
INNER JOIN vw_order_summary o ON p.order_id = o.order_id
WHERE o.delivery_status = 'Delivered'
GROUP BY YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp)
ORDER BY order_year, order_month;


-- 📍 PART 6: Regional Preferences – Payment Type by State
-- Purpose: Understand which states use which payment types more
SELECT 
    c.customer_state,
    p.payment_type,
    COUNT(*) AS num_payments,
    CAST(SUM(payment_value) AS DECIMAL(10,2)) AS total_value
FROM olist_order_payments_dataset p
INNER JOIN olist_orders_dataset o ON p.order_id = o.order_id
INNER JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
GROUP BY c.customer_state, p.payment_type
ORDER BY c.customer_state, total_value DESC;


-- 📍 PART 7: Regional Preferences – Installment Usage by State
-- Purpose: How does installment usage and delivery success vary by location?
SELECT 
    c.customer_state,
    COUNT(CASE WHEN p.payment_installments > 1 THEN 1 END) AS installment_orders,
    COUNT(CASE WHEN p.payment_installments = 1 THEN 1 END) AS one_time_orders,
    COUNT(*) AS total_orders,
    CAST(100.0 * COUNT(CASE WHEN p.payment_installments > 1 THEN 1 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS percent_installment_usage,
    CAST(100.0 * COUNT(CASE WHEN p.payment_installments = 1 THEN 1 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS percent_one_time_usage,
    COUNT(CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 END) AS on_time_orders,
    COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) AS delayed_orders,
    CAST(100.0 * COUNT(CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS percent_on_time,
    CAST(100.0 * COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS percent_delayed
FROM olist_order_payments_dataset p
INNER JOIN vw_order_summary o ON p.order_id = o.order_id
INNER JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.delivery_status = 'Delivered'
GROUP BY c.customer_state
ORDER BY percent_installment_usage DESC;


-- 🧾 PART 8: Payment Value Distribution – Labeled Buckets Using NTILE
-- Purpose: Segment payment values into labeled ranges (Very Low → Very High)
WITH payment_buckets AS (
    SELECT 
        payment_value,
        payment_type,
        NTILE(5) OVER (ORDER BY payment_value) AS bucket
    FROM olist_order_payments_dataset
)
SELECT 
    CASE bucket
        WHEN 1 THEN 'Very Low'
        WHEN 2 THEN 'Low'
        WHEN 3 THEN 'Medium'
        WHEN 4 THEN 'High'
        ELSE 'Very High'
    END AS payment_segment,
    COUNT(*) AS num_payments,
    MIN(payment_value) AS min_value,
    MAX(payment_value) AS max_value,
    CAST(AVG(payment_value) AS DECIMAL(10,2)) AS avg_value,
    SUM(payment_value) AS total_value,
    CAST(SUM(payment_value) * 100.0 / NULLIF((SELECT SUM(payment_value) FROM olist_order_payments_dataset), 0) AS DECIMAL(5,2)) AS percent_of_total_value
FROM payment_buckets
GROUP BY bucket
ORDER BY bucket;


-- 📟 PART 9: Payment Type Distribution by Value Segment
-- Purpose: Compare payment method usage across value buckets
WITH payment_buckets AS (
    SELECT 
        payment_value,
        payment_type,
        NTILE(5) OVER (ORDER BY payment_value) AS bucket
    FROM olist_order_payments_dataset
)
SELECT 
    CASE bucket
        WHEN 1 THEN 'Very Low'
        WHEN 2 THEN 'Low'
        WHEN 3 THEN 'Medium'
        WHEN 4 THEN 'High'
        ELSE 'Very High'
    END AS payment_segment,
    payment_type,
    COUNT(*) AS num_payments,
    SUM(payment_value) AS total_value,
    CAST(AVG(payment_value) AS DECIMAL(10,2)) AS avg_value
FROM payment_buckets
GROUP BY bucket, payment_type
ORDER BY bucket, total_value DESC;


-- 🔍 PART 10: Installment vs One-Time Payment Revenue Comparison
-- Purpose: Understand how payment mode affects revenue
SELECT 
    CASE 
        WHEN payment_installments > 1 THEN 'Installment'
        ELSE 'One-Time'
    END AS payment_mode,
    COUNT(*) AS total_payments,
    SUM(payment_value) AS total_payment_value,
    CAST(AVG(payment_value) AS DECIMAL(10,2)) AS avg_payment_value
FROM olist_order_payments_dataset
GROUP BY CASE 
             WHEN payment_installments > 1 THEN 'Installment'
             ELSE 'One-Time'
         END
ORDER BY total_payment_value DESC;


-- =========================================================================================
-- 🚫 SECTION 5: CANCELLATIONS & ORDER LOSS ANALYSIS
-- PURPOSE:
--   Analyze patterns in canceled orders across time, regions, and payment behavior
--   to understand where and why the business might be losing revenue.
-- =========================================================================================

-- 🔢 PART 1: Total Cancellations Overview
-- Purpose: Understand how many orders were canceled
SELECT 
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN delivery_status = 'Canceled' THEN 1 END) AS total_canceled_orders,
    CAST(100.0 * COUNT(CASE WHEN delivery_status = 'Canceled' THEN 1 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS cancellation_rate_percent
FROM vw_order_summary;


-- 📅 PART 2: Monthly Cancellation Rate Trend
-- Purpose: Track how cancellations vary by month
SELECT 
    YEAR(order_purchase_timestamp) AS order_year,
    MONTH(order_purchase_timestamp) AS order_month,
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN delivery_status = 'Canceled' THEN 1 END) AS canceled_orders,
    CAST(100.0 * COUNT(CASE WHEN delivery_status = 'Canceled' THEN 1 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS cancellation_rate_percent
FROM vw_order_summary
GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
ORDER BY order_year, order_month;


-- 🗺️ PART 3: Cancellation Rate by Customer State
-- Purpose: Identify states with highest cancellation rates
SELECT 
    c.customer_state,
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN o.delivery_status = 'Canceled' THEN 1 END) AS canceled_orders,
    CAST(100.0 * COUNT(CASE WHEN o.delivery_status = 'Canceled' THEN 1 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS cancellation_rate_percent
FROM vw_order_summary o
INNER JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
HAVING COUNT(*) > 20
ORDER BY cancellation_rate_percent DESC;


-- 💳 PART 4: Cancellation Rate by Payment Type
-- Purpose: See if certain payment types are more likely to result in cancellations
SELECT 
    p.payment_type,
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN o.order_status = 'Canceled' THEN 1 END) AS canceled_orders,
    CAST(100.0 * COUNT(CASE WHEN o.order_status = 'Canceled' THEN 1 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS cancellation_rate_percent
FROM olist_order_payments_dataset p
INNER JOIN olist_orders_dataset o ON p.order_id = o.order_id
GROUP BY p.payment_type
HAVING COUNT(*) > 20
ORDER BY cancellation_rate_percent DESC;


-- 🏷️ PART 5: Cancellation Rate by Product Segment
-- Purpose: Analyze which product segments get canceled more
SELECT 
    ps.product_category_segment,
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN os.delivery_status = 'Canceled' THEN 1 END) AS canceled_orders,
    CAST(100.0 * COUNT(CASE WHEN os.delivery_status = 'Canceled' THEN 1 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS cancellation_rate_percent
FROM vw_product_sales_summary ps
INNER JOIN vw_order_summary os ON ps.order_id = os.order_id
GROUP BY ps.product_category_segment
HAVING COUNT(*) > 20
ORDER BY cancellation_rate_percent DESC;


-- 🏷️ PART 6: Cancellation Rate by Product Category
-- Purpose: Provide more granularity than segment level
SELECT 
    ps.product_category_name_english,
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN os.delivery_status = 'Canceled' THEN 1 END) AS canceled_orders,
    CAST(100.0 * COUNT(CASE WHEN os.delivery_status = 'Canceled' THEN 1 END) / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)) AS cancellation_rate_percent
FROM vw_product_sales_summary ps
INNER JOIN vw_order_summary os ON ps.order_id = os.order_id
GROUP BY ps.product_category_name_english
HAVING COUNT(*) > 20
ORDER BY cancellation_rate_percent DESC;


-- 💸 PART 7: Estimated Revenue Lost to Cancellations (Based on Items)
-- Purpose: Approximate how much potential revenue was lost due to order cancellations
SELECT 
    COUNT(DISTINCT o.order_id) AS canceled_orders,
    CAST(AVG(i.price + i.freight_value) AS DECIMAL(10,2)) AS avg_canceled_order_value,
    CAST(SUM(i.price + i.freight_value) AS DECIMAL(10,2)) AS estimated_lost_revenue
FROM olist_orders_dataset o
JOIN olist_order_items_dataset i ON o.order_id = i.order_id
WHERE o.order_status = 'canceled';


-- 📅 PART 8: Estimated Lost Revenue by Month (Based on Items)
-- Purpose: Show which months lost the most potential revenue
SELECT 
    YEAR(o.order_purchase_timestamp) AS order_year,
    MONTH(o.order_purchase_timestamp) AS order_month,
    CAST(SUM(i.price + i.freight_value) AS DECIMAL(10,2)) AS estimated_lost_revenue
FROM olist_orders_dataset o
JOIN olist_order_items_dataset i ON o.order_id = i.order_id
WHERE o.order_status = 'canceled'
GROUP BY YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp)
ORDER BY order_year, order_month;