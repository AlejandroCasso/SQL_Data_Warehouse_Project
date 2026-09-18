/*
=====================================================================================
DDL Script: Create gold views
=====================================================================================
Script Purpose:
  This script creates views for the gold layer in the datawarehouse.
  The gold layer represents the final dimension and fact tables (Star schema)

  Each view performs tranformations and combines data from the silver layer
  to produce a clean, enriched and business-ready dataset.

Usage:
  - These views can be required directly for analytics and reporting.
===================================================================================
*/

-- ================================================================================
-- Create dimension: gold.dim_customers
-- ================================================================================
create view gold.dim_customers as
select
	row_number() over (order by cst_id) as customer_key,
	cci.cst_id as customer_id,
	cci.cst_key as customer_number,
	cci.cst_firstname as first_name,
	cci.cst_lastname as last_name,
	ela.cntry as country, 
	cci.cst_marital_status as marital_status,
	case when cci.cst_gndr <> 'n/a' then cci.cst_gndr
		 else coalesce(eca.gen, 'n/a')
	end as gender,
	eca.bdate as birthdate,
	cci.cst_create_date as create_date
from silver.crm_cust_info cci
left join silver.erp_cust_az12 eca on cci.cst_key = eca.cid  
left join silver.erp_loc_a101 ela on cci.cst_key = ela.cid ;

-- ================================================================================
-- Create dimension: gold.dim_products
-- ================================================================================
create view gold.dim_products AS
	select
	row_number() over (order by cpi.prd_start_dt, cpi.prd_key) as product_key,
	cpi.prd_id as product_id,
	cpi.prd_key as product_number,
	cpi.prd_nm as product_name,
	cpi.cat_id as category_id,
	epcgv.cat as category,
	epcgv.subcat as subcategory,
	epcgv.maintenance as maintenance,
	cpi.prd_cost as cost,
	cpi.prd_line as product_line, 
	cpi.prd_start_dt as start_date 
	from silver.crm_prd_info cpi 
	left join silver.erp_px_cat_g1v2 epcgv on cpi.cat_id = epcgv.id  
	where cpi.prd_end_dt is null;

-- ================================================================================
-- Create fact table: gold.fact_sales
-- ================================================================================
create view gold.fact_sales as
select
	csd.sls_ord_num as order_number,
	dp.product_key, 
	dc.customer_key,
	csd.sls_order_dt as order_date,
	csd.sls_ship_dt as shipping_date,
	csd.sls_due_dt as due_date,
	csd.sls_sales as sales_amount,
	csd.sls_quantity as quantity,
	csd.sls_price as price
from silver.crm_sales_details csd
left join gold.dim_products dp on csd.sls_prd_key = dp.product_number
left join gold.dim_customers dc on csd.sls_cust_id = dc.customer_id; 
