IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL DROP VIEW gold.dim_customers;

GO
    CREATE VIEW gold.dim_customers AS (
        SELECT
            ROW_NUMBER() OVER (
                ORDER BY
                    cst_id
            ) AS customer_key,
            -- customer_key is surrogate key
            ci.cst_id AS customer_id,
            ci.cst_key AS customer_number,
            ci.cst_firstname AS first_name,
            ci.cst_lastname AS last_name,
            la.cntry AS country,
            ci.cst_marital_status AS marital_status,
            CASE
                WHEN ci.cst_gndr = 'n/a' THEN COALESCE(ca.gen, 'n/a') 
                ELSE ci.cst_gndr  -- CRM is the primary source for gender
            END AS gender,
            ca.bdate AS birthdate,
            ci.cst_create_date AS create_date
        FROM
            silver.crm_cust_info ci
            LEFT JOIN silver.erp_cust_az12 ca ON ci.cst_key = ca.cid
            LEFT JOIN silver.erp_loc_a101 la ON ci.cst_key = la.cid
    )
GO
    IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL DROP VIEW gold.dim_products;

GO
    CREATE VIEW gold.dim_products AS (
        SELECT
            ROW_NUMBER() OVER(
                ORDER BY
                    cpi.prd_id
            ) AS product_key,
            -- product_key is surrogate key
            cpi.prd_id AS product_id,
            cpi.cat_id AS category_id,
            cpi.prd_key AS product_number,
            epg.cat AS categroy,
            epg.subcat,
            cpi.prd_nm AS product_num,
            cpi.prd_cost AS product_costs,
            cpi.prd_line AS product_line,
            cpi.prd_start_dt AS product_start_date,
            epg.MAINTENANCE AS maintenance
        FROM
            silver.crm_prd_info cpi
            LEFT JOIN silver.erp_px_cat_g1v2 epg ON epg.id = cpi.cat_id
    )
GO
    IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL DROP VIEW gold.fact_sales;

GO
    CREATE VIEW gold.fact_sales AS(
        SELECT
            sdt.sls_ord_num AS order_number,
            dp.product_key AS product_key,
            -- foreign key to dim_products
            dc.customer_key AS customer_key,
            -- foreign key to dim_customers
            sdt.sls_order_dt AS order_date,
            sdt.sls_ship_dt AS shipping_date,
            sdt.sls_due_dt AS due_dt,
            sdt.sls_sales AS sales_amount,
            sdt.sls_quantity AS quantity,
            sdt.sls_price AS price
        FROM
            silver.crm_sales_details sdt
            LEFT JOIN gold.dim_customers dc ON dc.customer_id = sdt.sls_cust_id
            LEFT JOIN gold.dim_products dp ON dp.product_number = sdt.sls_prd_key
    )
GO