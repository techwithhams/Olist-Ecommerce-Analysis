
-- ================================================================
-- 📊 BUSINESS ANALYSIS & INSIGHTS
-- PURPOSE:
--   Explore key business questions using SQL queries
--   Structured by topic: Sales, Customers, Delivery, Payments, etc.
-- ================================================================

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
