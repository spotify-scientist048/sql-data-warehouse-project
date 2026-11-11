/*
Stored Procedure: Load Bronze Layer (Source -> Bronze)

Script Purpose:
  This stored procedure loads data into the 'bronze' schema from external csv files.
  It performs the following actions:
  - Truncates the bronze tables before loading data
  - Uses the 'copy' command to load data from csv files to bronxe tables

Parameters: none. This stored procedure does not accept any parameters or return any  values.

Usage example: call bronze.load_bronze()
*/

create or replace procedure bronze.load_bronze()
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
        raise notice 'Starting loading bronze layer...';
        v_start_time := clock_timestamp();
        raise notice 'Loading CRM tables';
        raise notice 'Truncating and loading bronze.crm_cust_info...';
truncate table bronze.crm_cust_info;
copy bronze.crm_cust_info
from 'E:\Downloads\sql-data-warehouse-project\01_datasets\source_crm\cust_info.csv'
with (
    format csv,
    header true,
    delimiter ','
    );
        v_end_time := clock_timestamp();
        v_duration = v_end_time - v_start_time;
        raise notice 'bronze.crm_cust_info successfully loaded in %', v_duration;

        v_start_time := clock_timestamp();
        raise notice 'Truncating and loading bronze.crm_prd_info...';
truncate table bronze.crm_prd_info;
copy bronze.crm_prd_info
from 'E:\Downloads\sql-data-warehouse-project\01_datasets\source_crm\prd_info.csv'
with (
    format csv,
    header true,
    delimiter ','
    );
        v_end_time := clock_timestamp();
        v_duration = v_end_time - v_start_time;
        raise notice 'bronze.crm_prd_info successfully loaded in %', v_duration;

        v_start_time := clock_timestamp();
        raise notice 'Truncating and loading bronze.crm_sales_details...';
truncate table bronze.crm_sales_details;
copy bronze.crm_sales_details
from 'E:\Downloads\sql-data-warehouse-project\01_datasets\source_crm\sales_details.csv'
with (
    format csv,
    header true,
    delimiter ','
    );
        v_end_time := clock_timestamp();
        v_duration = v_end_time - v_start_time;
        raise notice 'bronze.crm_sales_details successfully loaded in %', v_duration;

        v_start_time := clock_timestamp();
        raise notice 'Loading ERP tables';
        raise notice 'Truncating and loading bronze.erp_px_cat_g1v2...';
truncate table bronze.erp_px_cat_g1v2;
copy bronze.erp_px_cat_g1v2
from 'E:\Downloads\sql-data-warehouse-project\01_datasets\source_erp\px_cat_g1v2.csv'
with (
    format csv,
    header true,
    delimiter ','
    );
        v_end_time := clock_timestamp();
        v_duration = v_end_time - v_start_time;
        raise notice 'bronze.erp_px_cat_g1v2 successfully loaded in %', v_duration;

        v_start_time := clock_timestamp();
        raise notice 'Truncating and loading bronze.erp_cust_az12...';
truncate table bronze.erp_cust_az12;
copy bronze.erp_cust_az12
from 'E:\Downloads\sql-data-warehouse-project\01_datasets\source_erp\cust_az12.csv'
with (
    format csv,
    header true,
    delimiter ','
    );
        v_end_time := clock_timestamp();
        v_duration = v_end_time - v_start_time;
        raise notice 'bronze.erp_cust_az12 successfully loaded in %', v_duration;

        v_start_time := clock_timestamp();
        raise notice 'Truncating and loading bronze.erp_loc_a101...';
truncate table bronze.erp_loc_a101;
copy bronze.erp_loc_a101
from 'E:\Downloads\sql-data-warehouse-project\01_datasets\source_erp\loc_a101.csv'
with (
    format csv,
    header true,
    delimiter ','
    );
        v_end_time := clock_timestamp();
        v_duration = v_end_time - v_start_time;
        raise notice 'bronze.erp_loc_a101 successfully loaded in %', v_duration;
        v_batch_end_time = clock_timestamp();
        v_total_duration = v_batch_end_time - v_batch_start_time;
        raise notice 'Bronze layer successfully loaded!';
        raise notice 'Total load duration %', v_total_duration;

exception
    when others then
        raise notice 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
        raise notice 'Error Message: %', SQLERRM;
        raise notice 'Error State: %', SQLSTATE;
    end;
$$;
