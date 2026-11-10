
/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure loads data from the Bronze layer into the Silver
    layer of the Data Warehouse.

    It performs the following operations:
        1. Truncates existing Silver tables before loading new data.
        2. Extracts data from the corresponding Bronze tables.
        3. Cleans, transforms, and standardizes the data.
        4. Removes duplicate customer records.
        5. Handles missing, invalid, and inconsistent data.
        6. Displays execution messages for each loading step.
        7. Handles SQL exceptions and displays error information.
        8. Tracks execution time for each operation and the entire process.

Parameters:
    None.
    This stored procedure does not accept any input parameters.

Usage Example:
    CALL silver.load_silver();

Important Notes:
    - Run the Bronze loading procedure before executing this procedure.
    - Existing Silver table data is truncated before new data is inserted.
    - This procedure uses MySQL syntax.

===============================================================================
*/

USE silver;

DROP PROCEDURE IF EXISTS load_silver;

DELIMITER $$

CREATE PROCEDURE load_silver()
BEGIN

    -- Variables for execution timing
    DECLARE v_start_time DATETIME(3);
    DECLARE v_end_time DATETIME(3);
    DECLARE v_step_start DATETIME(3);
    DECLARE v_step_end DATETIME(3);
    DECLARE v_error_message TEXT;

    -- Error handling
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_error_message = MESSAGE_TEXT;

        SET v_end_time = NOW(3);

        SELECT
            'ERROR OCCURRED DURING SILVER LOADING' AS status,
            v_error_message AS error_message,
            ROUND(
                TIMESTAMPDIFF(MICROSECOND, v_start_time, v_end_time) / 1000,
                2
            ) AS total_duration_ms;

        RESIGNAL;
    END;

    -- Start Silver Layer loading
    SET v_start_time = NOW(3);

    SELECT '========================================' AS message;
    SELECT 'STARTING SILVER LAYER LOADING' AS message;
    SELECT '========================================' AS message;


    -- =============================================
    -- 1. CRM CUSTOMER INFORMATION
    -- =============================================

    SELECT '>> Processing CRM Customer Information' AS message;

    -- Truncate
    SELECT '>> Truncating table: silver.crm_cust_info' AS message;

    SET v_step_start = NOW(3);

    TRUNCATE TABLE silver.crm_cust_info;

    SET v_step_end = NOW(3);

    SELECT CONCAT(
        '>> Truncate duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_step_start, v_step_end) / 1000, 2),
        ' ms'
    ) AS message;

    -- Insert
    SELECT '>> Inserting data into: silver.crm_cust_info' AS message;

    SET v_step_start = NOW(3);

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
    ) AS ranked_customers
    WHERE flag_last = 1;

    SET v_step_end = NOW(3);

    SELECT CONCAT(
        '>> Insert duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_step_start, v_step_end) / 1000, 2),
        ' ms'
    ) AS message;


    -- =============================================
    -- 2. CRM PRODUCT INFORMATION
    -- =============================================

    SELECT '>> Processing CRM Product Information' AS message;

    -- Truncate
    SELECT '>> Truncating table: silver.crm_prd_info' AS message;

    SET v_step_start = NOW(3);

    TRUNCATE TABLE silver.crm_prd_info;

    SET v_step_end = NOW(3);

    SELECT CONCAT(
        '>> Truncate duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_step_start, v_step_end) / 1000, 2),
        ' ms'
    ) AS message;

    -- Insert
    SELECT '>> Inserting data into: silver.crm_prd_info' AS message;

    SET v_step_start = NOW(3);

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
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_'),
        SUBSTRING(prd_key, 7, CHAR_LENGTH(prd_key)),
        prd_nm,
        COALESCE(prd_cost, 0),
        CASE
            WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
            WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
            WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
            WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
            ELSE 'N/A'
        END,
        CAST(prd_start_dt AS DATE),
        DATE_SUB(
            CAST(
                LEAD(prd_start_dt) OVER (
                    PARTITION BY prd_key
                    ORDER BY prd_start_dt
                ) AS DATE
            ),
            INTERVAL 1 DAY
        )
    FROM bronze.crm_prd_info;

    SET v_step_end = NOW(3);

    SELECT CONCAT(
        '>> Insert duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_step_start, v_step_end) / 1000, 2),
        ' ms'
    ) AS message;


    -- =============================================
    -- 3. CRM SALES DETAILS
    -- =============================================

    SELECT '>> Processing CRM Sales Details' AS message;

    -- Truncate
    SELECT '>> Truncating table: silver.crm_sales_details' AS message;

    SET v_step_start = NOW(3);

    TRUNCATE TABLE silver.crm_sales_details;

    SET v_step_end = NOW(3);

    SELECT CONCAT(
        '>> Truncate duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_step_start, v_step_end) / 1000, 2),
        ' ms'
    ) AS message;

    -- Insert
    SELECT '>> Inserting data into: silver.crm_sales_details' AS message;

    SET v_step_start = NOW(3);

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
            WHEN sls_order_dt = 0 OR CHAR_LENGTH(sls_order_dt) <> 8
            THEN NULL
            ELSE STR_TO_DATE(CAST(sls_order_dt AS CHAR), '%Y%m%d')
        END,

        CASE
            WHEN sls_ship_dt = 0 OR CHAR_LENGTH(sls_ship_dt) <> 8
            THEN NULL
            ELSE STR_TO_DATE(CAST(sls_ship_dt AS CHAR), '%Y%m%d')
        END,

        CASE
            WHEN sls_due_dt = 0 OR CHAR_LENGTH(sls_due_dt) <> 8
            THEN NULL
            ELSE STR_TO_DATE(CAST(sls_due_dt AS CHAR), '%Y%m%d')
        END,

        CASE
            WHEN sls_sales IS NULL
              OR sls_sales <= 0
              OR sls_sales <> sls_quantity * ABS(sls_price)
            THEN ROUND(sls_quantity * ABS(sls_price), 0)
            ELSE sls_sales
        END,

        sls_quantity,

        CASE
            WHEN sls_price IS NULL OR sls_price <= 0
            THEN ROUND(sls_sales / NULLIF(sls_quantity, 0), 0)
            ELSE ROUND(sls_price, 0)
        END

    FROM bronze.crm_sales_details;

    SET v_step_end = NOW(3);

    SELECT CONCAT(
        '>> Insert duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_step_start, v_step_end) / 1000, 2),
        ' ms'
    ) AS message;


    -- =============================================
    -- 4. ERP CUSTOMER INFORMATION
    -- =============================================

    SELECT '>> Processing ERP Customer Information' AS message;

    -- Truncate
    SELECT '>> Truncating table: silver.erp_cust_az12' AS message;

    SET v_step_start = NOW(3);

    TRUNCATE TABLE silver.erp_cust_az12;

    SET v_step_end = NOW(3);

    SELECT CONCAT(
        '>> Truncate duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_step_start, v_step_end) / 1000, 2),
        ' ms'
    ) AS message;

    -- Insert
    SELECT '>> Inserting data into: silver.erp_cust_az12' AS message;

    SET v_step_start = NOW(3);

    INSERT INTO silver.erp_cust_az12 (
        cid,
        bdate,
        gen
    )
    SELECT
        CASE
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, CHAR_LENGTH(cid))
            ELSE cid
        END,

        CASE
            WHEN bdate > CURDATE() THEN NULL
            ELSE bdate
        END,

        CASE
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
            ELSE 'N/A'
        END

    FROM bronze.erp_cust_az12;

    SET v_step_end = NOW(3);

    SELECT CONCAT(
        '>> Insert duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_step_start, v_step_end) / 1000, 2),
        ' ms'
    ) AS message;


    -- =============================================
    -- 5. ERP LOCATION INFORMATION
    -- =============================================

    SELECT '>> Processing ERP Location Information' AS message;

    -- Truncate
    SELECT '>> Truncating table: silver.erp_loc_a101' AS message;

    SET v_step_start = NOW(3);

    TRUNCATE TABLE silver.erp_loc_a101;

    SET v_step_end = NOW(3);

    SELECT CONCAT(
        '>> Truncate duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_step_start, v_step_end) / 1000, 2),
        ' ms'
    ) AS message;

    -- Insert
    SELECT '>> Inserting data into: silver.erp_loc_a101' AS message;

    SET v_step_start = NOW(3);

    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )
    SELECT
        REPLACE(cid, '-', ''),
        CASE
            WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
            WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United States'
            WHEN cntry IS NULL OR TRIM(cntry) = '' THEN 'N/A'
            ELSE TRIM(cntry)
        END
    FROM bronze.erp_loc_a101;

    SET v_step_end = NOW(3);

    SELECT CONCAT(
        '>> Insert duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_step_start, v_step_end) / 1000, 2),
        ' ms'
    ) AS message;


    -- =============================================
    -- 6. ERP PRODUCT CATEGORY INFORMATION
    -- =============================================

    SELECT '>> Processing ERP Product Category Information' AS message;

    -- Truncate
    SELECT '>> Truncating table: silver.erp_px_cat_g1v2' AS message;

    SET v_step_start = NOW(3);

    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    SET v_step_end = NOW(3);

    SELECT CONCAT(
        '>> Truncate duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_step_start, v_step_end) / 1000, 2),
        ' ms'
    ) AS message;

    -- Insert
    SELECT '>> Inserting data into: silver.erp_px_cat_g1v2' AS message;

    SET v_step_start = NOW(3);

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

    SET v_step_end = NOW(3);

    SELECT CONCAT(
        '>> Insert duration: ',
        ROUND(TIMESTAMPDIFF(MICROSECOND, v_step_start, v_step_end) / 1000, 2),
        ' ms'
    ) AS message;


    -- =============================================
    -- TOTAL SILVER LAYER DURATION
    -- =============================================

    SET v_end_time = NOW(3);

    SELECT '========================================' AS message;
    SELECT 'SILVER LAYER LOADING COMPLETED' AS message;

    SELECT
        ROUND(
            TIMESTAMPDIFF(MICROSECOND, v_start_time, v_end_time) / 1000,
            2
        ) AS total_silver_duration_ms;

    SELECT '========================================' AS message;

END $$

DELIMITER ;

