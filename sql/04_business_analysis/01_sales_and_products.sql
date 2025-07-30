
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
