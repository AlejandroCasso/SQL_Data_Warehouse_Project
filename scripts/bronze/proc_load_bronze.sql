/*
============================================================================
Stored Procedure: Load Bronze Layer (Source ---> Bronze)
============================================================================
Script Purpose:
  This stored procedure loads data into the bronze schema from external csv
  files.
  It performs the following actions:
  - Truncates the bronze tables before loading data.
  - Uses the 'COPY' command to load data from csv files to bronze tables.

Parameters:
  None.
  This stored procedure does not accept any parameters or return any values.

Usage example:
  CALL bronze.load_bronze();
============================================================================
*/

create or replace procedure bronze.load_bronze()
language plpgsql
as $$
declare
	start_time TIMESTAMP;
	end_time TIMESTAMP;
	batch_start_time TIMESTAMP;
	batch_end_time TIMESTAMP;
begin
	batch_start_time := clock_timestamp();
	raise notice '==================================';
	raise notice 'Loading bronze layer';
	raise notice '==================================';

	raise notice '==================================';
	raise notice 'Loading CRM tables';
	raise notice '==================================';


	start_time := clock_timestamp();
	raise notice '>> Truncating table bronze.crm_cust_info';
	truncate table bronze.crm_cust_info;
	raise notice '>> Inserting data into table bronze.crm_cust_info';

	COPY bronze.crm_cust_info
	FROM 'C:\Proyectos\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
	WITH (
	    FORMAT csv,
	    HEADER true,
	    DELIMITER ','
	);
	end_time := clock_timestamp();
	raise notice '>> Load duration: % seconds', extract(second from end_time - start_time);
	raise notice '---------------------------------';

	-----
	start_time := clock_timestamp();
	raise notice '>> Truncating table bronze.crm_prd_info';
	truncate table bronze.crm_prd_info;
	raise notice '>> Inserting data into table bronze.crm_prd_info';

	COPY bronze.crm_prd_info
	FROM 'C:\Proyectos\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
	WITH (
	    FORMAT csv,
	    HEADER true,
	    DELIMITER ','
	);
	end_time := clock_timestamp();
	raise notice '>> Load duration: % seconds', extract(second from end_time - start_time);
	raise notice '---------------------------------';

	-----
	start_time := clock_timestamp();
	raise notice '>> Truncating table bronze.crm_sales_details';
	truncate table bronze.crm_sales_details;
	raise notice '>> Inserting data into table bronze.crm_sales_details';

	COPY bronze.crm_sales_details
	FROM 'C:\Proyectos\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
	WITH (
	    FORMAT csv,
	    HEADER true,
	    DELIMITER ','
	);
	end_time := clock_timestamp();
	raise notice '>> Load duration: % seconds', extract(second from end_time - start_time);
	raise notice '---------------------------------';

	raise notice '==================================';
	raise notice 'Loading ERP tables';
	raise notice '==================================';
	-----
	start_time := clock_timestamp();
	raise notice '>> Truncating table bronze.erp_cust_az12';
	truncate table bronze.erp_cust_az12;
	raise notice '>> Inserting data into table bronze.erp_cust_az12';

	COPY bronze.erp_cust_az12
	FROM 'C:\Proyectos\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
	WITH (
	    FORMAT csv,
	    HEADER true,
	    DELIMITER ','
	);
	end_time := clock_timestamp();
	raise notice '>> Load duration: % seconds', extract(second from end_time - start_time);
	raise notice '---------------------------------';

	-----
	start_time := clock_timestamp();
	raise notice '>> Truncating table bronze.erp_loc_a101';
	truncate table bronze.erp_loc_a101;
	raise notice '>> Inserting data into table bronze.erp_loc_a101';

	COPY bronze.erp_loc_a101
	FROM 'C:\Proyectos\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
	WITH (
	    FORMAT csv,
	    HEADER true,
	    DELIMITER ','
	);
	end_time := clock_timestamp();
	raise notice '>> Load duration: % seconds', extract(second from end_time - start_time);
	raise notice '---------------------------------';

	----
	start_time := clock_timestamp();
	raise notice '>> Truncating table bronze.erp_px_cat_g1v2';
	truncate table bronze.erp_px_cat_g1v2;
	raise notice '>> Inserting data into table bronze.erp_px_cat_g1v2';

	COPY bronze.erp_px_cat_g1v2
	FROM 'C:\Proyectos\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
	WITH (
	    FORMAT csv,
	    HEADER true,
	    DELIMITER ','
	);
	end_time := clock_timestamp();
	raise notice '>> Load duration: % seconds', extract(second from end_time - start_time);
	raise notice '---------------------------------';

	batch_end_time := clock_timestamp();
	raise notice '==================================';
	raise notice 'Bronze Layer Load Completed';
	raise notice '   - Total Load Duration: % seconds', extract(second from batch_end_time - batch_start_time);
	raise notice '==================================';

exception
	when others then
		raise notice '=========================================';
		raise notice 'ERROR OCURRED DURING LOADING BRONZE LAYER';
		raise notice 'Error message: %', SQLERRM;
		raise notice 'Error Code: %', SQLSTATE;
		raise notice '=========================================';
end;
$$;
