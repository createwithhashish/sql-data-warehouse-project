
/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy,
    and standardization across the 'silver' schemas. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/


-- ====================================================================
-- Checking 'silver.crm_cust_info'
-- ====================================================================

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results

SELECT
    cst_id,
    COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;


-- Check for unwanted spaces in customer names
-- Expectation: No Results

SELECT
    cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname);

SELECT
    cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname <> TRIM(cst_lastname);


-- Check data standardization in marital status and gender
-- Expectation: Only standardized values

SELECT DISTINCT
    cst_marital_status
FROM silver.crm_cust_info;

SELECT DISTINCT
    cst_gendr
FROM silver.crm_cust_info;



-- ====================================================================
-- Checking 'silver.crm_prd_info'
-- ====================================================================

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results

SELECT
    prd_id,
    COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;


-- Check for unwanted spaces in product name
-- Expectation: No Results

SELECT
    prd_nm
FROM silver.crm_prd_info
WHERE prd_nm <> TRIM(prd_nm);


-- Check for NULL or negative product costs
-- Expectation: No Results

SELECT
    prd_id,
    prd_cost
FROM silver.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0;


-- Check product line standardization
-- Expectation: Only standardized values

SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info;


-- Check for invalid product date ranges
-- Expectation: No Results

SELECT
    prd_id,
    prd_start_dt,
    prd_end_dt
FROM silver.crm_prd_info
WHERE prd_end_dt IS NOT NULL
  AND prd_start_dt > prd_end_dt;



-- ====================================================================
-- Checking 'silver.crm_sales_details'
-- ====================================================================

-- Check for NULLs in sales order number
-- Expectation: No Results

SELECT *
FROM silver.crm_sales_details
WHERE sls_ord_num IS NULL;


-- Check for invalid order, shipping, and due dates
-- Expectation: No Results

SELECT *
FROM silver.crm_sales_details
WHERE (sls_order_dt IS NOT NULL AND sls_order_dt = '0000-00-00')
   OR (sls_ship_dt IS NOT NULL AND sls_ship_dt = '0000-00-00')
   OR (sls_due_dt IS NOT NULL AND sls_due_dt = '0000-00-00');


-- Check for invalid date ordering
-- Expectation: No Results

SELECT *
FROM silver.crm_sales_details
WHERE (sls_order_dt IS NOT NULL AND sls_ship_dt IS NOT NULL
       AND sls_order_dt > sls_ship_dt)
   OR (sls_order_dt IS NOT NULL AND sls_due_dt IS NOT NULL
       AND sls_order_dt > sls_due_dt);


-- Check sales consistency
-- Expectation: No Results

SELECT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales <> sls_quantity * ABS(sls_price);


-- Check for negative or zero sales values
-- Expectation: No Results

SELECT *
FROM silver.crm_sales_details
WHERE sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0;



-- ====================================================================
-- Checking 'silver.erp_cust_az12'
-- ====================================================================

-- Check for NULL or duplicate customer IDs
-- Expectation: No Results

SELECT
    cid,
    COUNT(*)
FROM silver.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1 OR cid IS NULL;


-- Check for future birth dates
-- Expectation: No Results

SELECT *
FROM silver.erp_cust_az12
WHERE bdate > CURDATE();


-- Check gender standardization
-- Expectation: Only standardized values

SELECT DISTINCT
    gen
FROM silver.erp_cust_az12;



-- ====================================================================
-- Checking 'silver.erp_loc_a101'
-- ====================================================================

-- Check for NULL or duplicate customer IDs
-- Expectation: No Results

SELECT
    cid,
    COUNT(*)
FROM silver.erp_loc_a101
GROUP BY cid
HAVING COUNT(*) > 1 OR cid IS NULL;


-- Check country standardization
-- Expectation: Standardized country values

SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101;


-- Check for unwanted spaces in country names
-- Expectation: No Results

SELECT
    cntry
FROM silver.erp_loc_a101
WHERE cntry <> TRIM(cntry);



-- ====================================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- ====================================================================

-- Check for NULL or duplicate category IDs
-- Expectation: No Results

SELECT
    id,
    COUNT(*)
FROM silver.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(*) > 1 OR id IS NULL;


-- Check for unwanted spaces in category fields
-- Expectation: No Results

SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat <> TRIM(cat)
   OR subcat <> TRIM(subcat)
   OR maintenance <> TRIM(maintenance);


-- Check for NULL values in category fields
-- Expectation: No Results

SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat IS NULL
   OR subcat IS NULL
   OR maintenance IS NULL;



-- ====================================================================
-- Cross-Table Quality Checks
-- ====================================================================

-- Check for unmatched CRM customer IDs in ERP customer data
-- Note: These are different source systems; investigate unmatched records.

SELECT
    e.cid
FROM silver.erp_cust_az12 AS e
LEFT JOIN silver.crm_cust_info AS c
    ON e.cid = c.cst_key
WHERE c.cst_key IS NULL;


-- Check for unmatched CRM product keys in sales data
-- Expectation: No Results

SELECT
    s.sls_prd_key
FROM silver.crm_sales_details AS s
LEFT JOIN silver.crm_prd_info AS p
    ON s.sls_prd_key = p.prd_key
WHERE p.prd_key IS NULL;

