/*
DDL Script: Create Gold Views
Script Purpose:
    This script creates views for the Gold layer in the data warehouse.
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
*/

-- Create Dimension: gold.dim_customers
create or replace view gold.dim_customers as
select
    row_number() over (order by cst_id) customer_key, -- Surrogate key
    ci.cst_id customer_id,
    ci.cst_key customer_number,
    ci.cst_firstname first_name,
    ci.cst_lastname last_name,
    la.cntry country,
    ci.cst_marital_status marital_status,
    case
        when ci.cst_gndr <> 'n/a' then ci.cst_gndr -- CRM is the primary source for gender
        else coalesce(ca.gen, 'n/a') -- Fallback to ERP data
    end gender,
    ca.bdate birthdate,
    ci.cst_create_date create_date
from data_warehouse.silver.crm_cust_info ci
    left join silver.erp_cust_az12 ca
        on ci.cst_key = ca.cid
    left join silver.erp_loc_a101 la
        on ci.cst_key = la.cid;

-- Create Dimension: gold.dim_products
create or replace view gold.dim_products as
select
    row_number() over (order by pi.prd_start_dt, pi.prd_key) product_key, -- Surrogate key
    pi.prd_id product_id,
    pi.prd_key product_number,
    pi.prd_nm product_name,
    pi.cat_id category_id,
    pc.cat category,
    pc.subcat subcategory,
    pc.maitenance,
    pi.prd_cost cost,
    pi.prd_line product_line,
    pi.prd_start_dt start_date
from silver.crm_prd_info pi
    left join silver.erp_px_cat_g1v2 pc
        on pi.cat_id = pc.id
where pi.prd_end_dt is null; -- Filter out all historical data

-- Create Fact Table: gold.fact_sales
create or replace view gold.fact_sales as
select
    sd.sls_ord_num order_number,
    p.product_key,
    c.customer_key,
    sd.sls_order_dt order_date,
    sd.sls_ship_dt shipping_date,
    sd.sls_due_dt due_date,
    sd.sls_sales sales_amount,
    sd.sls_quantity quantity,
    sd.sls_price price
from silver.crm_sales_details sd
    left join gold.dim_products p
        on sd.sls_prd_key = p.product_number
    left join gold.dim_customers c
        on sd.sls_cust_id = c.customer_id;
