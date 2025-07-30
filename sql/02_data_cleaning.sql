
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
