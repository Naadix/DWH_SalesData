----------------------------------------
-- STORED PROCEDURE OF LOAD BRONZE  --
----------------------------------------
CREATE OR ALTER PROCEDURE silver.load_silver AS 
BEGIN 
	DECLARE @start_time DATETIME , @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME
	BEGIN TRY 
		SET @batch_start_time = GETDATE();
		PRINT'LOADING SILVER LAYER....'
		-- START CLEANING CRM TABLES --
		 
		-- CLEANING DATA OF CRM_CUST_INFO TABLE
		SET @start_time = GETDATE()	;
		TRUNCATE TABLE silver.crm_cust_info ;
		INSERT INTO silver.crm_cust_info (
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date
		)
		SELECT 
		cst_id,cst_key,
		TRIM(cst_firstname) AS cst_firstname , TRIM(cst_lastname) AS cst_lastname, 
		CASE 
			WHEN UPPER(cst_marital_status) = 'M' THEN 'Married'
			WHEN UPPER(cst_marital_status) = 'S' THEN 'Single'
			ELSE 'n/a'
		END AS cs_marital_status , -- Normalize marital status
		CASE
			WHEN UPPER(cst_gndr) = 'M' THEN 'Male' 
			WHEN UPPER(cst_gndr) = 'F' THEN 'Female'
			ELSE 'n/a'
		END AS cst_gndr, -- Normalize gender 
		cst_create_date
		FROM( 
		SELECT *,
		ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) origin_cst_id
		FROM bronze.crm_cust_info
		WHERE cst_id IS NOT NULL -- remove null cst_id
		) t
		WHERE origin_cst_id = 1 ;
		SET @end_time = GETDATE();
		PRINT 'THE TIME LOADED OF CRM_CUST_INFO TABLE IS : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' second';
		
		-- CLEANING DATA OF CRM_PRD_INFO TABLE
		SET @start_time = GETDATE()	;
		TRUNCATE TABLE silver.crm_prd_info ;
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
		SELECT prd_id,
        REPLACE(SUBSTRING(prd_key,1,5),'-','_') cat_id,-- extract category id from product key
        SUBSTRING(prd_key,7,LEN(prd_key)) prd_key, -- extract product key
        prd_nm,
        ISNULL(prd_cost,0) prd_cost, -- handle null product cost 
		CASE
			WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
			WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
			WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
			WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
			ELSE 'n/a'
		END prd_line,--  Normalize product line
		prd_start_dt,
		DATEADD(DAY,-1,LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) ) prd_end_dt -- calculate product end date based on next product start date
		FROM bronze.crm_prd_info
		SET @end_time = GETDATE();
		PRINT 'THE TIME LOADED OF CRM_PRD_INFO TABLE IS : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' second';
		
		-- CLEANING DATA OF CRM_SALES_DETAILS TABLE
		SET @start_time = GETDATE()	;
		TRUNCATE TABLE silver.crm_sales_details ;
		INSERT INTO silver.crm_sales_details(
			sls_ord_num  ,
			sls_prd_key ,
			sls_cust_id ,
			sls_order_dt ,
			sls_ship_dt ,
			sls_due_dt ,
			sls_sales ,
			sls_quantity ,
			sls_price 
		)
		SELECT 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE 
			WHEN sls_order_dt = 0 OR LEN(sls_order_dt)!= 8 THEN NULL
			ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
		END sls_order_dt, -- handle invalid order date
		CASE 
			WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt)!= 8 THEN NULL
			ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
		END sls_ship_dt, -- handle invalid ship date
		CASE 
			WHEN sls_due_dt = 0 OR LEN(sls_due_dt)!= 8 THEN NULL
			ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
		END sls_due_dt, -- handle invalid due date
		CASE 
			WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
			THEN sls_quantity * ABS(sls_price)
			ELSE sls_sales
		END sls_sales, -- handle invalid sales amount 
		sls_quantity, 
		CASE 
			WHEN sls_price IS NULL OR sls_price <= 0 
			THEN sls_sales / NULLIF(sls_quantity,0)
			ELSE sls_price
		END sls_price -- handle invalid price amount
		FROM bronze.crm_sales_details

		SET @end_time = GETDATE();
		PRINT 'THE TIME LOADED OF CRM_SALES_DETAILS TABLE IS : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' second';

		-- START CLEANING ERP TABLES --

		-- CLEANING DATA OF ERP_CUST_AZ12 TABLE
		SET @start_time = GETDATE()	;

		TRUNCATE TABLE silver.erp_cust_az12 ;
		INSERT INTO silver.erp_cust_az12(
			cid,
			bdate,
			gen
		)
		SELECT 
			SUBSTRING(cid,4,LEN(cid)) cid, -- extract customer id from cid
			CASE
				WHEN bdate > GETDATE() THEN NULL
				ELSE bdate
			END bdate, -- handle invalid birth date
			CASE
				WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
				WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
				ELSE 'n/a' -- Normalize gender
			END gen
		FROM bronze.erp_cust_az12
        SET @end_time = GETDATE();
		PRINT 'THE TIME LOADED OF ERP_CUST_AZ12 TABLE IS : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' second';
		
		-- CLEANING DATA OF ERP_LOC_A101 TABLE
		SET @start_time = GETDATE()	;
		TRUNCATE TABLE silver.erp_loc_a101 ;
		INSERT INTO silver.erp_loc_a101(
			cid,
			cntry
		)
		SELECT 
			REPLACE(cid,'-','') cid, -- replace '-' with empty string in cid
			CASE 
				WHEN TRIM(cntry) IN ('USA','US') THEN 'United States'
				WHEN TRIM(cntry) = 'DE' THEN 'Germany'
				WHEN cntry IS NULL OR TRIM(cntry) = '' THEN 'n/a'
				ELSE cntry
			END cntry -- Normalize country names
		FROM bronze.erp_loc_a101
		SET @end_time = GETDATE();
		PRINT 'THE TIME LOADED OF ERP_LOC_A101 TABLE IS : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' second';
        
		-- CLEANING DATA OF ERP_PX_CAT_G1V2 TABLE
		SET @start_time = GETDATE()	;
		TRUNCATE TABLE silver.erp_px_cat_g1v2 ;
		INSERT INTO silver.erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			MAINTENANCE
		)
		SELECT 
			id,
			cat,
			subcat,
			MAINTENANCE
		FROM bronze.erp_px_cat_g1v2
		SET @end_time = GETDATE();
		PRINT 'THE TIME LOADED OF ERP_PX_CAT_G1V2 TABLE IS : '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' second';
		SET @batch_end_time = GETDATE()
		PRINT'=========================================='
		PRINT'Loading Silver Layer is Completed';
		PRINT'   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT'==========================================';

	END TRY 
	BEGIN CATCH 
		PRINT'==========================';
		PRINT'ERROR MESSAGE : '+ERROR_MESSAGE() ;
		PRINT'ERROR NUMBER : '+CAST(ERROR_NUMBER() AS NVARCHAR) ;
		PRINT'==========================';
	END CATCH

END
