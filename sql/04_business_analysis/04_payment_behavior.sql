
-- ================================================================
-- 📊 BUSINESS ANALYSIS & INSIGHTS
-- PURPOSE:
--   Explore key business questions using SQL queries
--   Structured by topic: Sales, Customers, Delivery, Payments, etc.
-- ================================================================

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

