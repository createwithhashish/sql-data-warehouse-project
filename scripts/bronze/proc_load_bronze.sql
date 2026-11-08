
-- ============================================================
-- Stored Procedure: Load Bronze Layer (Source to Bronze)
-- Database: MySQL
-- Project: SQL Data Warehouse
-- ============================================================

/*
Script Purpose:
    This stored procedure loads raw data into the Bronze layer
    from external CRM and ERP CSV files.

    It performs the following actions:
    1. Truncates existing Bronze tables before loading new data.
    2. Loads CRM data from external CSV files.
    3. Loads ERP data from external CSV files.
    4. Tracks start time, end time, and loading duration.
    5. Displays loading performance for CRM, ERP, and the
       complete Bronze layer.

Parameters:
    This stored procedure does not accept any parameters
    or return any values.

Usage Example:
    USE bronze;
    CALL load_bronze();
*/


USE bronze;

DROP PROCEDURE IF EXISTS load_bronze;

DELIMITER $$

CREATE PROCEDURE load_bronze()
BEGIN

    -- ========================================================
    -- Declare variables for tracking loading duration
    -- DATETIME(3) provides millisecond precision.
    -- ========================================================

    DECLARE bronze_start_time DATETIME(3);
    DECLARE bronze_end_time DATETIME(3);

    DECLARE crm_start_time DATETIME(3);
    DECLARE crm_end_time DATETIME(3);

    DECLARE erp_start_time DATETIME(3);
    DECLARE erp_end_time DATETIME(3);


    -- ========================================================
    -- Error handling
    -- Captures SQL exceptions and displays the error message.
    -- ========================================================

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @error_message = MESSAGE_TEXT;

        SELECT CONCAT('ERROR OCCURRED: ', @error_message)
        AS error_message;
    END;


    -- ========================================================
    -- Load Bronze Layer
    -- ========================================================

    SET bronze_start_time = NOW(3);

    SELECT '========================================' AS message;
    SELECT 'LOADING BRONZE LAYER' AS message;
    SELECT '========================================' AS message;


    -- ========================================================
    -- Truncate Bronze Tables
    -- Remove existing records before loading fresh data.
    -- ========================================================

    TRUNCATE TABLE crm_cust_info;
    TRUNCATE TABLE crm_prd_info;
    TRUNCATE TABLE crm_sales_details;
    TRUNCATE TABLE erp_cust_az12;
    TRUNCATE TABLE erp_loc_a101;
    TRUNCATE TABLE erp_px_cat_g1v2;


    -- ========================================================
    -- Loading CRM Tables
    -- ========================================================

    SET crm_start_time = NOW(3);

    SELECT 'LOADING CRM TABLES' AS message;


    -- Load customer information
    LOAD DATA LOCAL INFILE
    'D:/DATA ANALTICS/SQL/New folder/sql-data-warehouse-project/sql-data-warehouse-project/01_datasets/source_crm/cust_info.csv'
    INTO TABLE crm_cust_info
    FIELDS TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'
    LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS;


    -- Load product information
    LOAD DATA LOCAL INFILE
    'D:/DATA ANALTICS/SQL/New folder/sql-data-warehouse-project/sql-data-warehouse-project/01_datasets/source_crm/prd_info.csv'
    INTO TABLE crm_prd_info
    FIELDS TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'
    LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS;


    -- Load sales transaction information
    LOAD DATA LOCAL INFILE
    'D:/DATA ANALTICS/SQL/New folder/sql-data-warehouse-project/sql-data-warehouse-project/01_datasets/source_crm/sales_details.csv'
    INTO TABLE crm_sales_details
    FIELDS TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'
    LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS;


    SET crm_end_time = NOW(3);


    -- Calculate CRM loading duration
    SELECT
        'CRM' AS process,
        crm_start_time AS start_time,
        crm_end_time AS end_time,
        TIMESTAMPDIFF(MICROSECOND, crm_start_time, crm_end_time) / 1000
        AS duration_milliseconds;


    -- ========================================================
    -- Loading ERP Tables
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


    SET erp_end_time = NOW(3);


    -- Calculate ERP loading duration
    SELECT
        'ERP' AS process,
        erp_start_time AS start_time,
        erp_end_time AS end_time,
        TIMESTAMPDIFF(MICROSECOND, erp_start_time, erp_end_time) / 1000
        AS duration_milliseconds;


    -- ========================================================
    -- Calculate Total Bronze Layer Loading Duration
    -- ========================================================

    SET bronze_end_time = NOW(3);

    SELECT
        'BRONZE' AS process,
        bronze_start_time AS start_time,
        bronze_end_time AS end_time,
        TIMESTAMPDIFF(MICROSECOND, bronze_start_time, bronze_end_time) / 1000
        AS duration_milliseconds;


    -- Display completion message
    SELECT 'BRONZE LOADING COMPLETED SUCCESSFULLY' AS message;

END $$

DELIMITER ;
