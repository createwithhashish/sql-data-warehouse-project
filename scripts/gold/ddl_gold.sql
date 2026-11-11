
/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse.

    The Gold layer represents the final dimension and fact tables
    following the Star Schema design.

    Each view performs transformations and combines data from the
    Silver layer to produce clean, enriched, and business-ready datasets.

Views Created:
    1. gold.gold_dim_customers
       - Combines CRM customer information with ERP customer and location data.
       - Standardizes customer gender using CRM as the master source.
       - Provides customer details for analytical reporting.

    2. gold.dim_product
       - Combines CRM product information with ERP product category data.
       - Excludes historical product records.
       - Provides product and category details for analysis.

    3. gold.fact_sales
       - Combines sales transactions with customer and product dimensions.
       - Connects sales records using customer and product keys.
       - Provides measures such as sales amount, quantity, and sales price.

Usage:
    These views can be queried directly for analytics and reporting.

===============================================================================
*/


-- ====================================================================
-- Create Dimension: gold.gold_dim_customers
-- ====================================================================

CREATE OR REPLACE VIEW gold.gold_dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    la.cntry AS country,
    ci.cst_marital_status AS marital_status,
    CASE
        WHEN ci.cst_gendr <> 'N/A' THEN ci.cst_gendr
        ELSE COALESCE(ca.gen, 'N/A')
    END AS gender,
    ca.bdate AS birthdate,
    ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;


-- ====================================================================
-- Create Dimension: gold.dim_product
-- ====================================================================

CREATE OR REPLACE VIEW gold.dim_product AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY pn.prd_start_dt, pn.prd_key
    ) AS product_key,
    pn.prd_id AS product_id,
    pn.prd_key AS product_number,
    pn.prd_nm AS product_name,
    pn.cat_id AS category_id,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pc.maintenance AS maintenance,
    pn.prd_cost AS cost,
    pn.prd_line AS product_line,
    pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL;


-- ====================================================================
-- Create Fact: gold.fact_sales
-- ====================================================================

CREATE OR REPLACE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num AS order_number,
    pr.product_key AS product_key,
    cu.customer_key AS customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS sales_price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_product pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.gold_dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;
