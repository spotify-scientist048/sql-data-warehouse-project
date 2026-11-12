/*
Stored Procedure: Load Silver Layer (Bronze -> Silver)
Script Purpose: 
  This stored procedure performs the ETL process to
  populate the 'silver' schema tables from the 'bronze' schema.
Action performed:
  - truncates silver tables
  - inserts transformed and cleansed tables data from Bronze into Silver tables.

Parameters: none.
  This stored procedure doesn't accept any parameters or return aby values.

Usage example: 
  call silver.load_silver();
*/

create or replace procedure silver.load_silver()
language plpgsql
as $$
    declare
        v_start_time timestamp;
        v_end_time timestamp;
        v_batch_start_time timestamp;
        v_batch_end_time timestamp;
        v_duration interval;
        v_total_duration interval;
    begin
        v_batch_start_time := clock_timestamp();
        raise notice 'Loading silver layer';
        v_start_time := clock_timestamp();
        raise notice 'Loading CRM tables';
        raise notice 'Loading silver.crm_cust_info';
truncate table silver.crm_cust_info;
insert into silver.crm_cust_info
    (cst_id,
     cst_key,
     cst_firstname,
     cst_lastname,
     cst_marital_status,
     cst_gndr,
     cst_create_date)
select
    cst_id,
    cst_key,
    trim(cst_firstname) cst_firstname,
    trim(cst_lastname) cst_lastname,
    case upper(trim(cst_marital_status))
        when 'M' then 'Married'
        when 'S' then 'Single'
        else 'n/a'
    end cst_marital_status,
    case upper(trim(cst_gndr))
        when 'M' then 'Male'
        when 'F' then 'Female'
        else 'n/a'
    end cst_gndr,
    cst_create_date
from (select
    *,
    row_number() over (partition by cst_id order by cst_create_date desc) flag_last
from bronze.crm_cust_info) t
where flag_last = 1;
        v_end_time :=clock_timestamp();
        v_duration = v_end_time - v_start_time;
        raise notice 'silver.crm_cust_info successfully loaded in %', v_duration;

        v_start_time := clock_timestamp();
        raise notice 'Starting loading silver.crm_prd_info';
truncate table silver.crm_prd_info;
insert into silver.crm_prd_info
    (prd_id,
     cat_id,
     prd_key,
     prd_nm,
     prd_cost,
     prd_line,
     prd_start_dt,
     prd_end_dt)
select
    prd_id,
    replace(substring(prd_key, 1, 5), '-', '_') cat_id,
    substring(prd_key, 7, length(prd_key)) prd_key,
    prd_nm,
    coalesce(prd_cost, 0) prd_cost,
    case upper(trim(prd_line))
        when 'R' then 'Road'
        when 'S' then 'Other sales'
        when 'M' then 'Mountain'
        when 'T' then 'Touring'
        else 'n/a'
    end prd_line,
    prd_start_dt,
    lead(prd_start_dt) over(partition by prd_key order by prd_start_dt) - interval '1 day' prd_end_dt
from bronze.crm_prd_info;
        v_end_time := clock_timestamp();
        v_duration = v_end_time - v_start_time;
        raise notice 'silver.crm_prd_info successfully loaded in %', v_duration;

        v_start_time := clock_timestamp();
        raise notice 'Starting loading silver.crm_sales_details';
truncate table silver.crm_sales_details;
insert into silver.crm_sales_details
    (sls_ord_num,
     sls_prd_key,
     sls_cust_id,
     sls_order_dt,
     sls_ship_dt,
     sls_due_dt,
     sls_sales,
     sls_quantity,
     sls_price)
select
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    case
        when length(sls_order_dt) <> 8 then null
        else to_date(sls_order_dt, 'yyyymmdd')
    end sls_order_dt,
    to_date(trim(sls_ship_dt), 'yyyymmdd') sls_ship_dt,
    to_date(trim(sls_due_dt), 'yyyymmdd') sls_due_dt,
    case
        when sls_sales is null
            or sls_sales <= 0
            or sls_sales <> sls_quantity * abs(sls_price) then sls_quantity * abs(sls_price)
        else sls_sales
    end sls_sales,
    sls_quantity,
    case
        when sls_price is null or sls_price <= 0 then sls_sales / nullif(sls_quantity, 0)
        else sls_price
    end sls_price
from bronze.crm_sales_details;
        v_end_time := clock_timestamp();
        v_duration = v_end_time - v_start_time;
        raise notice 'silver,crm_sales details successfully loaded in %', v_duration;
        raise notice 'CRM tables successfully loaded';

        v_start_time := clock_timestamp();
        raise notice 'Loading ERP tables';
        raise notice 'Starting loading silver.erp_cust_az12';
truncate table silver.erp_cust_az12;
insert into silver.erp_cust_az12
    (cid,
     bdate,
     gen)
select
    case
        when cid like 'NAS%' then substring(cid, 4, length(cid))
        else cid
    end cid,
    case
        when bdate > current_date then null
        else bdate
    end bdate,
   case
        when lower(trim(gen)) in ('f', 'female') then 'Female'
        when lower(trim(gen)) in ('m', 'male') then 'Male'
        else 'n/a'
    end gen
from bronze.erp_cust_az12;
        v_end_time := clock_timestamp();
        v_duration = v_end_time - v_start_time;
        raise notice 'silver.erp_cust_az12 successfully loaded in %', v_duration;

        v_start_time := clock_timestamp();
        raise notice 'Starting loading silver.erp_loc_a101';
truncate table silver.erp_loc_a101;
insert into silver.erp_loc_a101
    (cid,
     cntry)
select
    replace(cid, '-', ''),
    case
        when upper(trim(cntry)) = 'DE' then 'Germany'
        when upper(trim(cntry)) in ('US', 'USA') then 'United States'
        when trim(cntry) = '' or cntry is null then 'n/a'
        else trim(cntry)
    end cntry
from bronze.erp_loc_a101;
        v_end_time := clock_timestamp();
        v_duration = v_end_time - v_start_time;
        raise notice 'silver.erp_loc_a101 successfully loaded in %', v_duration;
        v_batch_end_time := clock_timestamp();
        v_total_duration = v_batch_end_time - v_batch_start_time;
        raise notice 'Silver layer loaded successfully in %', v_total_duration;
end;
$$;
