/*
============================================================================
Quality checks
============================================================================
Script Purpose:
  This script performs various quality checks for data consistency, accuracy,
  and standarization across the silver schema. It includes checks for
    - Null or duplicate primary keyss.
    - Unwanted spaces in string fields.
    - Data standarization and consistency.
    - Invalid date range and orders.

Usage Notes:
  - Run these checks after data loading silver layer.
  - Investigate and resolve any discrepances found during the checks.
============================================================================
*/

-- ============================
-- silver.crm_cust_info
-- ============================

-- Check for nulls or duplicates in primary key
select
	cci.cst_id,
	count(*)
from silver.crm_cust_info cci
group by cci.cst_id
having count(*) > 1 or cci.cst_id is null;

-- Check for unwanted spaces
select cci.cst_firstname
from silver.crm_cust_info cci
where cci.cst_firstname != TRIM(cci.cst_firstname);

select cci.cst_lastname
from silver.crm_cust_info cci
where cci.cst_lastname != TRIM(cci.cst_lastname);

-- Data standardization & consistency
select distinct cci.cst_marital_status
from silver.crm_cust_info cci;

select distinct cci.cst_gndr
from silver.crm_cust_info cci;


-- ============================
-- silver.crm_prd_info
-- ============================

-- Check for nulls or duplicates in primary key
select
	cpi.prd_id,
	count(*)
from silver.crm_prd_info cpi
group by cpi.prd_id
having count(*) > 1 or cpi.prd_id is null;

-- Check for unwanted spaces
select cpi.prd_nm
from silver.crm_prd_info cpi
where cpi.prd_nm != TRIM(cpi.prd_nm);

-- Check for nulls or negative numbers
select cpi.prd_cost
from silver.crm_prd_info cpi
where cpi.prd_cost < 0 or cpi.prd_cost is null;

-- Data standardization & consistency
select distinct cpi.prd_line
from silver.crm_prd_info cpi;

-- Check for invalid date orders (end date earlier than start date)
select *
from silver.crm_prd_info cpi
where cpi.prd_end_dt < cpi.prd_start_dt;


-- ============================
-- silver.crm_sales_details
-- ============================

-- Check for invalid or out-of-range dates
select
	csd.sls_order_dt
from silver.crm_sales_details csd
where csd.sls_order_dt < '1900-01-01' or csd.sls_order_dt > '2050-01-01';

-- Check for invalid date orders (order date later than ship/due date)
select *
from silver.crm_sales_details csd
where csd.sls_order_dt > csd.sls_ship_dt
   or csd.sls_order_dt > csd.sls_due_dt;

-- Check data consistency: sales = quantity * price
-- Values must not be null, zero, or negative
select distinct
	csd.sls_sales,
	csd.sls_quantity,
	csd.sls_price
from silver.crm_sales_details csd
where csd.sls_sales <> csd.sls_quantity * csd.sls_price
   or csd.sls_sales is null or csd.sls_quantity is null or csd.sls_price is null
   or csd.sls_sales <= 0 or csd.sls_quantity <= 0 or csd.sls_price <= 0
order by sls_sales, sls_quantity, sls_price;

-- Check referential integrity: sls_prd_key must exist in crm_prd_info
select csd.sls_prd_key
from silver.crm_sales_details csd
left join silver.crm_prd_info cpi
	on csd.sls_prd_key = cpi.prd_key
where cpi.prd_key is null;

-- Check referential integrity: sls_cust_id must exist in crm_cust_info
select csd.sls_cust_id
from silver.crm_sales_details csd
left join silver.crm_cust_info cci
	on csd.sls_cust_id = cci.cst_id
where cci.cst_id is null;


-- ============================
-- silver.erp_cust_az12
-- ============================

-- Check for out-of-range birth dates
select distinct eca.bdate
from silver.erp_cust_az12 eca
where eca.bdate < '1924-01-01' or eca.bdate > current_timestamp;

-- Data standardization & consistency
select distinct eca.gen
from silver.erp_cust_az12 eca;


-- ============================
-- silver.erp_loc_a101
-- ============================

-- Data standardization & consistency
select distinct ela.cntry
from silver.erp_loc_a101 ela
order by 1;


-- ============================
-- silver.erp_px_cat_g1v2
-- ============================

-- Check for unwanted spaces
select *
from silver.erp_px_cat_g1v2 epcgv
where epcgv.cat <> trim(epcgv.cat)
   or epcgv.subcat <> trim(epcgv.subcat)
   or epcgv.maintenance <> trim(epcgv.maintenance);
