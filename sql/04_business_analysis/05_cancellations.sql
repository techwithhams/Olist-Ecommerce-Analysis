
-- ================================================================
-- 📊 BUSINESS ANALYSIS & INSIGHTS
-- PURPOSE:
--   Explore key business questions using SQL queries
--   Structured by topic: Sales, Customers, Delivery, Payments, etc.
-- ================================================================

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