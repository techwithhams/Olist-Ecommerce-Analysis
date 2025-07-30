# 🛒 Olist E-Commerce Sales Analysis Project

**End-to-End Portfolio Project | MS SQL Server + Power BI + PowerPoint**

This project presents a comprehensive analysis of the Olist e-commerce dataset, focusing on customer behavior, order patterns, product performance, delivery logistics, and payment methods using real-world data from a Brazilian marketplace.

---

## 🌟 Project Objective

To deliver business insights that help improve customer segmentation, delivery efficiency, product strategy, and payment optimization for Olist’s multi-category e-commerce platform using data-driven decisions.

---

## 🧰 Tools & Skills

* **📃 Dataset**: Olist E-Commerce Dataset (subset of 8 CSV files)
* **🧠 Analysis**: Advanced SQL Server queries (joins, views, CTEs, window functions)
* **📊 Visualization**: Power BI dashboards with interactive KPIs, maps, slicers
* **🛠 Tools Used**: MS SQL Server, Power BI, PowerPoint
* **🔍 Skills Applied**: SQL, RFM segmentation, data cleaning, business analytics, dashboard design

---

## 📁 Project Structure

```
Olist-Ecommerce-Analysis/
│
├── SQL/                                 # Organized SQL analysis in modular scripts
│   ├── 00_data_preparation.sql          # Column renaming, header fix, PKs
│   ├── 01_data_quality_checks.sql       # Row count, nulls, distincts, duplicates
│   ├── 02_data_cleaning.sql             # NULL handling, typo fixes, standardization
│   ├── 03_data_modeling_views.sql       # All CREATE VIEW statements
│   └── 04_business_analysis/            # Key business insight queries by topic
│       ├── 01_sales_and_products.sql
│       ├── 02_customer_behavior.sql
│       ├── 03_delivery_and_location.sql
│       ├── 04_payment_behavior.sql
│       └── 05_cancellations.sql
│
├── Olist_Ecommerce.sql                  # Full master SQL script (all-in-one)
├── Olist_Ecommerce_Dashboard.pdf        # 3-page Power BI dashboard summary
├── Olist_Ecommerce_Presentation.pptx    # Slide deck used for presenting findings
├── PowerBI_Screenshots/                 # Dashboard screenshots
│   ├── 1. Sales Analysis.jpg
│   ├── 2. Order and Delivery Analysis.jpg
│   └── 3. Customer and Payment Analysis.jpg
└── README.md                            # Project overview and key insights
```

---

## 🧠 Key Insights

### 👥 Customer & Payment Analysis

* **Total Revenue**: \$18.06M | **Total Orders**: 99K | **Average Order Value**: \$182.7
* **Installment Payments**: Used in 82% of transactions
* **Credit Card** is the most preferred method, followed by Boleto
* **Weekday orders** are 3x more common than weekend orders

### 📦 Product Segment & Sales Trends

* Top Revenue Categories:

  * 🏠 *Home & Garden*: \$6M
  * 💄 *Health & Beauty*: \$2M
  * 🧵 *Fashion & Accessories*: \$1.6M
* **High-performing products** are concentrated in fewer categories
* **Bundled promotions** recommended for top cross-sold items

### 🚚 Order & Delivery Insights

* **92% On-Time Delivery Rate**
* **Average Delivery Time**: 12 days
* **Monthly Peak**: May and August had the highest order volume
* **Delivery Delays** mostly affect a small fraction (\~8%) of orders

### 🌍 Regional Performance

* Top revenue comes from large metro areas: São Paulo and Rio de Janeiro
* Freight costs highest in rural northern regions, with longer delivery delays
* Revenue and freight are both growing YoY (2016 → 2018)

---

## 📊 Power BI Dashboard

The dashboard includes:

1. **Sales Analysis**
2. **Order and Delivery Analysis**
3. **Customer and Payment Analysis**

🔍 Features:

* Interactive slicers by state, category, and date
* Custom DAX measures for KPIs
* Geospatial maps, trend lines, stacked visuals
* Consistent, clean theme for readability

📸 Preview screenshots available in the [`/PowerBI_Screenshots`](./PowerBI_Screenshots) folder.
📄 [Dashboard PDF](./Olist_Ecommerce_Dashboard.pdf) | 📽️ [Presentation Slides](./Olist_Ecommerce_Presentation.pptx)

(Dashboards are built using a combination of SQL views and Power BI transformations.)

---

## 📌 How to Use

1. Execute the SQL files in MS SQL Server (starting with `00_data_preparation.sql`).
2. Run through data quality checks, cleaning, and modeling scripts in order.
3. Load views from `03_data_modeling_views.sql` for reporting.
4. Open the Power BI PDF to explore interactive visuals.
5. Use the PowerPoint to present findings to stakeholders.

---

## 📊 Business Recommendations

* 🍭 Promote high-revenue product categories with regional discounts
* 💳 Offer more installment flexibility during Q2–Q3 (peak sales)
* 🛠 Improve delivery logistics in northern states to reduce freight costs
* 👥 Target campaigns at medium-frequency customers to increase loyalty
* 🚚 Bundle commonly purchased products for higher AOV

---

📬 **Author**: Hams Saeed Alhakim
🔗 **GitHub**: [github.com/techwithhams](https://github.com/techwithhams)
🗓 **Date**: 2025
