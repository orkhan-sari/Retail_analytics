/*
=============================================================
Create Database and Schemas
=============================================================
    This script creates a new database named 'complete_journey' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas 
    within the database: 'bronze', 'silver', and 'gold'.
*/

USE master;
GO

-- Drop and recreate the database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'complete_journey')
BEGIN
    ALTER DATABASE complete_journey SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE complete_journey;
END;
GO

-- Create the database
CREATE DATABASE complete_journey;
GO

USE complete_journey;
GO

-- Create Schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO