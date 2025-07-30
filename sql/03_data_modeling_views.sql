
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