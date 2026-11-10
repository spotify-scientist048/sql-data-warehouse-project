/*
====================================================
Create Database and Schemas
====================================================
Script Purpose:
    This script creates a new database named 'data_warehouse' after checking if it already exists.
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas
    within the database: 'bronze', 'silver', and 'gold'.

WARNING:
    Running this script will drop the entire 'data_warehouse' database if it exists.
    All data in the database will be permanently deleted. Proceed with caution
    and ensure you have proper backups before running this script.
*/

-- drop and recreate a database

drop database if exists data_warehouse;
create database data_warehouse;

-- create schemas

create schema bronze;

create schema silver;

create schema gold;
