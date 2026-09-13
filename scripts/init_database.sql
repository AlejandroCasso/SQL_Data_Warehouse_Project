/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'datawarehouse' after checking if it already exists.
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas
    within the database: 'bronze', 'silver', and 'gold'.

WARNING:
    Running this script will drop the entire 'datawarehouse' database if it exists.
    All data in the database will be permanently deleted. Proceed with caution
    and ensure you have proper backups before running this script.

NOTE (PostgreSQL-specific):
    Unlike SQL Server, PostgreSQL cannot switch the active database mid-script.
    Run STEP 1 while connected to 'postgres' (or any database other than 'datawarehouse'),
    then manually switch your connection/editor context to 'datawarehouse' before running STEP 2.
*/

-- ============ STEP 1: run while connected to 'postgres' ============

-- Terminate active connections to 'datawarehouse'
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'datawarehouse' AND pid <> pg_backend_pid();

-- Drop and recreate the 'datawarehouse' database
DROP DATABASE IF EXISTS datawarehouse;
CREATE DATABASE datawarehouse;

-- ============ STEP 2: run while connected to 'datawarehouse' ============

-- Create Schemas -- 
CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;
