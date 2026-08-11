----------------------------------------
-- STORED PROCEDURE OF LOAD BRONZE  --
----------------------------------------

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN 
	DECLARE @start_time DATETIME , @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME
	BEGIN TRY 
		SET @batch_start_time = GETDATE();
		PRINT'LOADING BRONZE LAYER....'
		-- START LOAD CRM TABLES --

		-- LOAD CUST_INFO TABLES
		SET @start_time = GETDATE()	;
		TRUNCATE TABLE bronze.crm_cust_info ;
		BULK INSERT bronze.crm_cust_info 
		FROM 'D:\Data Engineering Project\DWH_SalesData\datasets\source_crm\cust_info.csv'
		WITH(
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'THE TIME LOADED OF CUST_INFO TABLE IS : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' second';
		

		-- LOAD PRD_INFO TABLES
		SET @start_time = GETDATE()	;
		TRUNCATE TABLE bronze.crm_prd_info ;
		BULK INSERT bronze.crm_prd_info 
		FROM 'D:\Data Engineering Project\DWH_SalesData\datasets\source_crm\prd_info.csv'
		WITH(
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'THE TIME LOADED OF PRD_INFO TABLE IS : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' second';
		

		-- LOAD SALES_DETAILS TABLES
		SET @start_time = GETDATE()	;
		TRUNCATE TABLE bronze.crm_sales_details ;
		BULK INSERT bronze.crm_sales_details
		FROM 'D:\Data Engineering Project\DWH_SalesData\datasets\source_crm\sales_details.csv'
		WITH(
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'THE TIME LOADED OF SALES_DETAILS TABLE IS : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' second';
		
		-- END LOAD CRM TABLES --

		-- START LOAD ERP TABLES --

		-- LOAD CUST_AZ12 TABLES
		SET @start_time = GETDATE()	;
		TRUNCATE TABLE bronze.erp_cust_az12 ;
		BULK INSERT bronze.erp_cust_az12 
		FROM 'D:\Data Engineering Project\DWH_SalesData\datasets\source_erp\CUST_AZ12.csv'
		WITH(
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'THE TIME LOADED OF CUST_AZ12 TABLE IS : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' second';
		

		-- LOAD LOC_A101 TABLES
		SET @start_time = GETDATE()	;
		TRUNCATE TABLE bronze.erp_loc_a101 ;
		BULK INSERT bronze.erp_loc_a101 
		FROM 'D:\Data Engineering Project\DWH_SalesData\datasets\source_erp\LOC_A101.csv'
		WITH(
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'THE TIME LOADED OF PRD_INFO TABLE IS : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' second';
		
		
		-- LOAD PX_CAT_G1V2 TABLES
		SET @start_time = GETDATE()	;
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'D:\Data Engineering Project\DWH_SalesData\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH(
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT 'THE TIME LOADED OF PX_CAT_G1V2 TABLE IS : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' second';
		SET @batch_end_time = GETDATE()
		PRINT'==========================';
		PRINT'THE TOTAL TIME OF LOADING DATA FROM BRONZE LAYER IS : '+CAST(DATEDIFF(second,@batch_start_time,@batch_end_time) AS NVARCHAR)+' second' ;
	   	PRINT'==========================';

		-- END LOAD ERP TABLES --
	END TRY 
	BEGIN CATCH
	    PRINT'==========================';
		PRINT'THE ERROR MESSAGE IS : '+ ERROR_MESSAGE();
		PRINT'THE NUMBER OF ERROR IS :'+ CAST(ERROR_NUMBER() AS NVARCHAR)
	    PRINT'==========================';
	END CATCH
END