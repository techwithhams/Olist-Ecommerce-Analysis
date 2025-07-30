       
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
