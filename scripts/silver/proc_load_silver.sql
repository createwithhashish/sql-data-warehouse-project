/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process
    to populate the Silver layer tables from the Bronze layer.

    Actions Performed:
        - Truncates existing Silver tables.
        - Inserts transformed and cleansed data from Bronze into Silver tables.
        - Removes duplicate customer records.
        - Standardizes inconsistent values.
        - Handles missing and invalid data.
        - Tracks execution time for each table and the entire process.
        - Handles SQL exceptions and displays error information.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    CALL silver.load_silver();

===============================================================================
*/

USE silver;

DROP PROCEDURE IF EXISTS load_silver;

DELIMITER $$

CREATE PROCEDURE load_silver()
BEGIN

    -- Declare variables for execution time tracking
    DECLARE v_start_time DATETIME(3);
    DECLARE v_end_time DATETIME(3);
    DECLARE v_batch_start_time DATETIME(3);
    DECLARE v_batch_end_time DATETIME(3);
    DECLARE v_error_message TEXT;

    -- Error handling
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_error_message = MESSAGE_TEXT;

        SET v_batch_end_time = NOW(3);

        SELECT
            'ERROR OCCURRED DURING SILVER LOADING' AS status,
            v_error_message AS error_message,
            TIMESTAMPDIFF(
                MICROSECOND,
                v_batch_start_time,
                v_batch_end_time
            ) / 1000 AS total_duration_ms;

        RESIGNAL;
    END;

    -- Record batch start time
    SET v_batch_start_time = NOW(3);

    SELECT '=============================================' AS message;
    SELECT 'Loading Silver Layer' AS message;
    SELECT '=============================================' AS message;


    -- =====================================================
    -- Loading CRM Tables
    -- =====================================================

    SELECT '---------------------------------------------' AS message;
    SELECT 'Loading CRM Tables' AS message;
    SELECT '---------------------------------------------' AS message;


    -- CRM Customer Information
    SET v_start_time = NOW(3);

    TRUNCATE TABLE silver.crm_cust_info;

    INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gendr,
        cst_create_date
    )
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname),
        TRIM(cst_lastname),
        CASE
            WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
            WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
            ELSE 'N/A'
        END,
        CASE
            WHEN UPPER(TRIM(cst_gendr)) = 'F' THEN 'Female'
            WHEN UPPER(TRIM(cst_gendr)) = 'M' THEN 'Male'
            ELSE 'N/A'
        END,
        cst_create_date
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY cst_id
                ORDER BY cst_create_date DESC
            ) AS flag_last
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
          AND cst_id <> 0
    ) AS t
    WHERE flag_last = 1;

    SET v_end_time = NOW(3);

    SELECT
        'CRM Customer Information Loaded' AS message,
        TIMESTAMPDIFF(MICROSECOND, v_start_time, v_end_time) / 1000
            AS duration_ms;


    -- CRM Product Information
    SET v_start_time = NOW(3);

    TRUNCATE TABLE silver.crm_prd_info;

    INSERT INTO silver.crm_prd_info (
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )
    SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
        SUBSTRING(prd_key, 7, CHAR_LENGTH(prd_key)) AS prd_key,
        prd_nm,
        COALESCE(prd_cost, 0) AS prd_cost,
        CASE
            WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
            WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
            WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
            WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
            ELSE 'N/A'
        END AS prd_line,
        CAST(prd_start_dt AS DATE) AS prd_start_dt,
        DATE_SUB(
            CAST(
                LEAD(prd_start_dt) OVER (
                    PARTITION BY prd_key
                    ORDER BY prd_start_dt
                ) AS DATE
            ),
            INTERVAL 1 DAY
        ) AS prd_end_dt
    FROM bronze.crm_prd_info;

    SET v_end_time = NOW(3);

    SELECT
        'CRM Product Information Loaded' AS message,
        TIMESTAMPDIFF(MICROSECOND, v_start_time, v_end_time) / 1000
            AS duration_ms;


    -- CRM Sales Details
    SET v_start_time = NOW(3);

    TRUNCATE TABLE silver.crm_sales_details;

    INSERT INTO silver.crm_sales_details (
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,

        CASE
            WHEN sls_order_dt IS NULL
              OR sls_order_dt = 0
              OR CHAR_LENGTH(CAST(sls_order_dt AS CHAR)) <> 8
            THEN NULL
            ELSE STR_TO_DATE(
                CAST(sls_order_dt AS CHAR),
                '%Y%m%d'
            )
        END AS sls_order_dt,

        CASE
            WHEN sls_ship_dt IS NULL
              OR sls_ship_dt = 0
              OR CHAR_LENGTH(CAST(sls_ship_dt AS CHAR)) <> 8
            THEN NULL
            ELSE STR_TO_DATE(
                CAST(sls_ship_dt AS CHAR),
                '%Y%m%d'
            )
        END AS sls_ship_dt,

        CASE
            WHEN sls_due_dt IS NULL
              OR sls_due_dt = 0
              OR CHAR_LENGTH(CAST(sls_due_dt AS CHAR)) <> 8
            THEN NULL
            ELSE STR_TO_DATE(
                CAST(sls_due_dt AS CHAR),
                '%Y%m%d'
            )
        END AS sls_due_dt,

        CASE
            WHEN sls_sales IS NULL
              OR sls_sales <= 0
              OR sls_sales <> sls_quantity * ABS(sls_price)
            THEN ROUND(sls_quantity * ABS(sls_price), 0)
            ELSE sls_sales
        END AS sls_sales,

        sls_quantity,

        CASE
            WHEN sls_price IS NULL
              OR sls_price <= 0
            THEN ROUND(
                sls_sales / NULLIF(sls_quantity, 0),
                0
            )
            ELSE ROUND(sls_price, 0)
        END AS sls_price

    FROM bronze.crm_sales_details;

    SET v_end_time = NOW(3);

    SELECT
        'CRM Sales Details Loaded' AS message,
        TIMESTAMPDIFF(MICROSECOND, v_start_time, v_end_time) / 1000
            AS duration_ms;


    -- =====================================================
    -- Loading ERP Tables
    -- =====================================================

    SELECT '---------------------------------------------' AS message;
    SELECT 'Loading ERP Tables' AS message;
    SELECT '---------------------------------------------' AS message;


    -- ERP Customer Information
    SET v_start_time = NOW(3);

    TRUNCATE TABLE silver.erp_cust_az12;

    INSERT INTO silver.erp_cust_az12 (
        cid,
        bdate,
        gen
    )
    SELECT
        CASE
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, CHAR_LENGTH(cid))
            ELSE cid
        END AS cid,

        CASE
            WHEN bdate > CURDATE() THEN NULL
            ELSE bdate
        END AS bdate,

        CASE
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
            ELSE 'N/A'
        END AS gen

    FROM bronze.erp_cust_az12;

    SET v_end_time = NOW(3);

    SELECT
        'ERP Customer Information Loaded' AS message,
        TIMESTAMPDIFF(MICROSECOND, v_start_time, v_end_time) / 1000
            AS duration_ms;


    -- ERP Location Information
    SET v_start_time = NOW(3);

    TRUNCATE TABLE silver.erp_loc_a101;

    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )
    SELECT
        REPLACE(cid, '-', '') AS cid,

        CASE
            WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
            WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
            ELSE TRIM(cntry)
        END AS cntry

    FROM bronze.erp_loc_a101;

    SET v_end_time = NOW(3);

    SELECT
        'ERP Location Information Loaded' AS message,
        TIMESTAMPDIFF(MICROSECOND, v_start_time, v_end_time) / 1000
            AS duration_ms;


    -- ERP Product Category Information
    SET v_start_time = NOW(3);

    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    INSERT INTO silver.erp_px_cat_g1v2 (
        id,
        cat,
        subcat,
        maintenance
    )
    SELECT
        id,
        cat,
        subcat,
        maintenance
    FROM bronze.erp_px_cat_g1v2;

    SET v_end_time = NOW(3);

    SELECT
        'ERP Product Category Information Loaded' AS message,
        TIMESTAMPDIFF(MICROSECOND, v_start_time, v_end_time) / 1000
            AS duration_ms;


    -- =====================================================
    -- Completion
    -- =====================================================

    SET v_batch_end_time = NOW(3);

    SELECT '=============================================' AS message;
    SELECT 'Silver Layer Loading Completed' AS message;
    SELECT '=============================================' AS message;

    SELECT
        'Total Silver Loading Duration' AS message,
        TIMESTAMPDIFF(
            MICROSECOND,
            v_batch_start_time,
            v_batch_end_time
        ) / 1000 AS total_duration_ms;

END $$

DELIMITER ;
