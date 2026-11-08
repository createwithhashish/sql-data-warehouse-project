
-- ============================================================
-- PROJECT: SQL DATA WAREHOUSE
-- LAYER: BRONZE
-- DATABASE: MySQL
-- PURPOSE:
-- This stored procedure loads raw CRM and ERP data from CSV
-- files into Bronze layer tables using the LOAD DATA command.
-- It also tracks the loading duration for CRM, ERP, and the
-- complete Bronze layer.
-- ============================================================


-- Select the Bronze database
USE bronze;


-- Remove the existing procedure if it already exists
DROP PROCEDURE IF EXISTS load_bronze;


-- Change the delimiter to allow multiple statements
-- inside the stored procedure
DELIMITER $$


-- Create the stored procedure for loading Bronze layer data
CREATE PROCEDURE load_bronze()
BEGIN

    -- ========================================================
    -- 1. DECLARE VARIABLES
    -- These variables capture the start and end times of
    -- CRM loading, ERP loading, and total Bronze loading.
    -- DATETIME(3) stores timestamps with millisecond precision.
    -- ========================================================

    DECLARE bronze_start_time DATETIME(3);
    DECLARE bronze_end_time DATETIME(3);

    DECLARE crm_start_time DATETIME(3);
    DECLARE crm_end_time DATETIME(3);

    DECLARE erp_start_time DATETIME(3);
    DECLARE erp_end_time DATETIME(3);


    -- ========================================================
    -- 2. ERROR HANDLING
    -- This handler catches SQL exceptions during execution
    -- and displays the corresponding error message.
    -- ========================================================

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @error_message = MESSAGE_TEXT;

        SELECT CONCAT('ERROR OCCURRED: ', @error_message)
        AS error_message;
    END;


    -- ========================================================
    -- 3. START BRONZE LAYER LOADING
    -- Capture the overall start time before loading begins.
    -- ========================================================

    SET bronze_start_time = NOW(3);

    SELECT '========================================' AS message;
    SELECT 'LOADING BRONZE LAYER' AS message;
    SELECT '========================================' AS message;


    -- ========================================================
    -- 4. TRUNCATE BRONZE TABLES
    -- Remove existing records before loading fresh raw data.
    -- This prevents duplicate records during repeated loads.
    -- ========================================================

    TRUNCATE TABLE crm_cust_info;
    TRUNCATE TABLE crm_prd_info;
    TRUNCATE TABLE crm_sales_details;
    TRUNCATE TABLE erp_cust_az12;
    TRUNCATE TABLE erp_loc_a101;
    TRUNCATE TABLE erp_px_cat_g1v2;


    -- ========================================================
    -- 5. LOAD CRM DATA
    -- Load customer, product, and sales data from CRM CSV files.
    -- Capture the CRM loading start time before execution.
    -- ========================================================

    SET crm_start_time = NOW(3);

    SELECT 'LOADING CRM TABLES' AS message;


    -- Load customer information into the CRM customer table
    LOAD DATA LOCAL INFILE
    'D:/DATA ANALTICS/SQL/New folder/sql-data-warehouse-project/sql-data-warehouse-project/01_datasets/source_crm/cust_info.csv'
    INTO TABLE crm_cust_info
    FIELDS TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'
    LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS;


    -- Load product information into the CRM product table
    LOAD DATA LOCAL INFILE
    'D:/DATA ANALTICS/SQL/New folder/sql-data-warehouse-project/sql-data-warehouse-project/01_datasets/source_crm/prd_info.csv'
    INTO TABLE crm_prd_info
    FIELDS TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'
    LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS;


    -- Load sales transaction data into the CRM sales table
    LOAD DATA LOCAL INFILE
    'D:/DATA ANALTICS/SQL/New folder/sql-data-warehouse-project/sql-data-warehouse-project/01_datasets/source_crm/sales_details.csv'
    INTO TABLE crm_sales_details
    FIELDS TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'
    LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS;


    -- Capture CRM loading end time
    SET crm_end_time = NOW(3);


    -- Calculate and display total CRM loading duration
    -- TIMESTAMPDIFF(MICROSECOND) provides precise duration
    -- Dividing by 1000 converts microseconds into milliseconds.

    SELECT
        'CRM' AS process,
        crm_start_time AS start_time,
        crm_end_time AS end_time,
        TIMESTAMPDIFF(MICROSECOND, crm_start_time, crm_end_time) / 1000
        AS duration_milliseconds;


    -- ========================================================
    -- 6. LOAD ERP DATA
    -- Load customer, location, and product category data
    -- from ERP CSV files.
    -- ========================================================

    SET erp_start_time = NOW(3);

    SELECT 'LOADING ERP TABLES' AS message;


    -- Load ERP customer information
    LOAD DATA LOCAL INFILE
    'D:/DATA ANALTICS/SQL/New folder/sql-data-warehouse-project/sql-data-warehouse-project/01_datasets/source_erp/CUST_AZ12.csv'
    INTO TABLE erp_cust_az12
    FIELDS TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'
    LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS;


    -- Load ERP location information
    LOAD DATA LOCAL INFILE
    'D:/DATA ANALTICS/SQL/New folder/sql-data-warehouse-project/sql-data-warehouse-project/01_datasets/source_erp/LOC_A101.csv'
    INTO TABLE erp_loc_a101
    FIELDS TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'
    LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS;


    -- Load ERP product category information
    LOAD DATA LOCAL INFILE
    'D:/DATA ANALTICS/SQL/New folder/sql-data-warehouse-project/sql-data-warehouse-project/01_datasets/source_erp/PX_CAT_G1V2.csv'
    INTO TABLE erp_px_cat_g1v2
    FIELDS TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'
    LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS;


    -- Capture ERP loading end time
    SET erp_end_time = NOW(3);


    -- Calculate and display total ERP loading duration
    SELECT
        'ERP' AS process,
        erp_start_time AS start_time,
        erp_end_time AS end_time,
        TIMESTAMPDIFF(MICROSECOND, erp_start_time, erp_end_time) / 1000
        AS duration_milliseconds;


    -- ========================================================
    -- 7. CALCULATE TOTAL BRONZE LOADING DURATION
    -- Capture the end time after all CRM and ERP tables
    -- have been loaded.
    -- ========================================================

    SET bronze_end_time = NOW(3);


    -- Display the overall Bronze layer loading performance
    SELECT
        'BRONZE' AS process,
        bronze_start_time AS start_time,
        bronze_end_time AS end_time,
        TIMESTAMPDIFF(MICROSECOND, bronze_start_time, bronze_end_time) / 1000
        AS duration_milliseconds;


    -- Display completion message
    SELECT 'BRONZE LOADING COMPLETED SUCCESSFULLY' AS message;

END $$


-- Restore the default statement delimiter
DELIMITER ;


-- ============================================================
-- 8. EXECUTE THE STORED PROCEDURE
-- Run the procedure to load all six Bronze layer tables.
-- ============================================================

USE bronze;

CALL load_bronze();


-- ============================================================
-- 9. VERIFY LOADED RECORD COUNTS
-- Check the total number of records loaded into each table.
-- ============================================================

SELECT 'crm_cust_info' AS table_name, COUNT(*) AS total_rows FROM crm_cust_info
UNION ALL
SELECT 'crm_prd_info', COUNT(*) FROM crm_prd_info
UNION ALL
SELECT 'crm_sales_details', COUNT(*) FROM crm_sales_details
UNION ALL
SELECT 'erp_cust_az12', COUNT(*) FROM erp_cust_az12
UNION ALL
SELECT 'erp_loc_a101', COUNT(*) FROM erp_loc_a101
UNION ALL
SELECT 'erp_px_cat_g1v2', COUNT(*) FROM erp_px_cat_g1v2;
