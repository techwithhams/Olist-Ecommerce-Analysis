
-- ================================================================
-- 📊 BUSINESS ANALYSIS & INSIGHTS
-- PURPOSE:
--   Explore key business questions using SQL queries
--   Structured by topic: Sales, Customers, Delivery, Payments, etc.
-- ================================================================

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
