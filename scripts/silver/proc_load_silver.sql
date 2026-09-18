/*
============================================================================
Stored Procedure: Load Silver Layer (Bronze ---> Silver)
============================================================================
Script Purpose:
  This stored procedure performs the ETL (Extract, Transform and Load) process to
  populate the silver schema tables from the bronze schema.
  Actions Performed:
    - Truncates Silver tables
    - Inserts transformed and cleansed data from bronze to silver tables.

Parameters:
  None.
  This stored procedure does not accept any parameters or return any values.

Usage example:
  CALL silver.load_silver();
============================================================================
*/


create or replace procedure silver.load_silver()
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
	raise notice 'Loading silver layer';
	raise notice '==================================';

	raise notice '==================================';
	raise notice 'Loading CRM tables';
	raise notice '==================================';

	-----
	start_time := clock_timestamp();
	raise notice '>> Truncating Table: silver.crm_cust_info';
	truncate table silver.crm_cust_info;
	raise notice '>> Inserting data into table silver.crm_cust_info';
	insert into silver.crm_cust_info (
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date
	)
	select
		f.cst_id ,
		f.cst_key,
		TRIM(f.cst_firstname) as cst_firstname,
		TRIM(f.cst_lastname) as cst_lastname,
		case when UPPER(TRIM(f.cst_marital_status )) = 'S' then 'Single'
			 when UPPER(TRIM(f.cst_marital_status )) = 'M' then 'Married'
			 else 'n/a'
		end as cst_marital_status,
		case when UPPER(TRIM(f.cst_gndr)) = 'F' then 'Female'
			 when UPPER(TRIM(f.cst_gndr)) = 'M' then 'Male'
			 else 'n/a'
		end as cst_gndr,
		f.cst_create_date
	from (
		select
			*,
			row_number() over (partition by cst_id order by cst_create_date DESC) as flag_last
		from bronze.crm_cust_info cci
		where cst_id is not null) f
	where f.flag_last = 1;
	end_time := clock_timestamp();
	raise notice '>> Load duration: % seconds', extract(second from end_time - start_time);
	raise notice '---------------------------------';

	-----
	start_time := clock_timestamp();
	raise notice '>> Truncating Table: silver.crm_prd_info';
	truncate table silver.crm_prd_info;
	raise notice '>> Inserting data into table silver.crm_prd_info';
	insert into silver.crm_prd_info(
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
	)
	select
		cpi.prd_id,
		REPLACE(SUBSTRING(cpi.prd_key, 1, 5), '-', '_') as cat_id,
		REPLACE(SUBSTRING(cpi.prd_key, 7, LENGTH(cpi.prd_key)), '-', '_') as prd_key,
		cpi.prd_nm,
		COALESCE(cpi.prd_cost, 0) as prd_cost,
		case UPPER(TRIM(prd_line))
			 when 'M' then 'Mountain'
			 when 'R' then 'Road'
			 when 'S' then 'Other Sales'
			 when 'T' then 'Touring'
			 else 'n/a'
		end as prd_line,
		cast(cpi.prd_start_dt as DATE) as prd_start_dt,
		cast(LEAD(prd_start_dt) over (partition by cpi.prd_key order by prd_start_dt) as DATE) - 1 as prd_end_dt
	from bronze.crm_prd_info cpi;
	end_time := clock_timestamp();
	raise notice '>> Load duration: % seconds', extract(second from end_time - start_time);
	raise notice '---------------------------------';

	-----
	start_time := clock_timestamp();
	raise notice '>> Truncating Table: silver.crm_sales_details';
	truncate table silver.crm_sales_details;
	raise notice '>> Inserting data into table silver.crm_sales_details';
	insert into silver.crm_sales_details(
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
	select
		csd.sls_ord_num,
		csd.sls_prd_key,
		csd.sls_cust_id,
		case when csd.sls_order_dt = 0 or LENGTH(cast(csd.sls_order_dt as text)) <> 8 then null
			 else CAST(CAST(sls_order_dt as VARCHAR) as DATE)
		end as sls_order_dt,
		case when csd.sls_ship_dt = 0 or LENGTH(cast(csd.sls_ship_dt as text)) <> 8 then null
			 else CAST(CAST(sls_ship_dt as VARCHAR) as DATE)
		end as sls_ship_dt,
		case when csd.sls_due_dt = 0 or LENGTH(cast(csd.sls_due_dt as text)) <> 8 then null
			 else CAST(CAST(sls_due_dt as VARCHAR) as DATE)
		end as sls_due_dt,
		case when csd.sls_sales is null or csd.sls_sales <= 0 or csd.sls_sales <> (csd.sls_quantity * abs(csd.sls_price))
			 then csd.sls_quantity * ABS(csd.sls_price)
		else csd.sls_sales
		end as sls_sales,
		csd.sls_quantity,
		case when csd.sls_price is null or csd.sls_price <= 0
			 then (case when csd.sls_sales is null or csd.sls_sales <= 0 or csd.sls_sales <> (csd.sls_quantity * abs(csd.sls_price))
						then csd.sls_quantity * abs(csd.sls_price)
						else csd.sls_sales
					end) / nullif(csd.sls_quantity, 0)
			 else csd.sls_price
		end as sls_price
	from bronze.crm_sales_details csd;
	end_time := clock_timestamp();
	raise notice '>> Load duration: % seconds', extract(second from end_time - start_time);
	raise notice '---------------------------------';

	raise notice '==================================';
	raise notice 'Loading ERP tables';
	raise notice '==================================';

	-----
	start_time := clock_timestamp();
	raise notice '>> Truncating Table: silver.erp_cust_az12';
	truncate table silver.erp_cust_az12;
	raise notice '>> Inserting data into table silver.erp_cust_az12';
	insert into silver.erp_cust_az12(
		cid,
		bdate,
		gen
	)
	select
		case when cid like 'NAS%' then SUBSTRING(cid, 4, length(cid))
			 else cid
		end as cid,
		case when bdate > current_timestamp then null
			 else bdate
		end as bdate,
		case when UPPER(TRIM(eca.gen)) in ('F', 'FEMALE') then 'Female'
			 when UPPER(TRIM(eca.gen)) in ('M', 'MALE') then 'Male'
			 else 'n/a'
		end as gen
	from bronze.erp_cust_az12 eca;
	end_time := clock_timestamp();
	raise notice '>> Load duration: % seconds', extract(second from end_time - start_time);
	raise notice '---------------------------------';

	-----
	start_time := clock_timestamp();
	raise notice '>> Truncating Table: silver.erp_loc_a101';
	truncate table silver.erp_loc_a101;
	raise notice '>> Inserting data into table silver.erp_loc_a101';
	insert into silver.erp_loc_a101(
		cid,
		cntry
	)
	select
		replace(cid, '-', '') as cid,
		case when TRIM(cntry) in ('US', 'USA') then 'United States'
			 when TRIM(cntry) = 'DE' then 'Germany'
			 when TRIM(cntry) = '' or cntry is null then 'n/a'
			 else TRIM(cntry)
		end as cntry
	from bronze.erp_loc_a101 ela;
	end_time := clock_timestamp();
	raise notice '>> Load duration: % seconds', extract(second from end_time - start_time);
	raise notice '---------------------------------';

	-----
	start_time := clock_timestamp();
	raise notice '>> Truncating Table: silver.erp_px_cat_g1v2';
	truncate table silver.erp_px_cat_g1v2;
	raise notice '>> Inserting data into table silver.erp_px_cat_g1v2';
	insert into silver.erp_px_cat_g1v2(
		id,
		cat,
		subcat,
		maintenance
	)
	select epcgv.id , epcgv.cat , epcgv.subcat, epcgv.maintenance
	from bronze.erp_px_cat_g1v2 epcgv;
	end_time := clock_timestamp();
	raise notice '>> Load duration: % seconds', extract(second from end_time - start_time);
	raise notice '---------------------------------';

	batch_end_time := clock_timestamp();
	raise notice '==================================';
	raise notice 'Silver Layer Load Completed';
	raise notice '   - Total Load Duration: % seconds', extract(second from batch_end_time - batch_start_time);
	raise notice '==================================';

exception
	when others then
		raise notice '=========================================';
		raise notice 'ERROR OCURRED DURING LOADING SILVER LAYER';
		raise notice 'Error message: %', SQLERRM;
		raise notice 'Error Code: %', SQLSTATE;
		raise notice '=========================================';
end;
$$;
