/*
===============================================================================
    This script creates tables in the 'bronze' schema, dropping existing tables 
    if they already exist.
===============================================================================
*/

-- Campaign Description Table
USE complete_journey;
GO

IF OBJECT_ID('bronze.campaign_desc', 'U') IS NOT NULL
    DROP TABLE bronze.campaign_desc;
GO

CREATE TABLE bronze.campaign_desc (
    description NVARCHAR(50),
    campaign INT,
    start_day INT,
    end_day INT
);
GO

-- Campaign Table
IF OBJECT_ID('bronze.campaign_table', 'U') IS NOT NULL
    DROP TABLE bronze.campaign_table;
GO

CREATE TABLE bronze.campaign_table (

    description NVARCHAR(50),
    household_key INT,
    campaign  INT
);
GO

-- Coupon Table
IF OBJECT_ID('bronze.coupon', 'U') IS NOT NULL
    DROP TABLE bronze.coupon;
GO

CREATE TABLE bronze.coupon (

    coupon_upc  VARCHAR(50),
    product_id  INT,
    campaign  INT
);
GO

-- coupon redemption table
IF OBJECT_ID('bronze.coupon_redempt', 'U') IS NOT NULL
    DROP TABLE bronze.coupon_redempt;
GO

CREATE TABLE bronze.coupon_redempt (
    household_key INT,
    day INT,
    coupon_upc VARCHAR(50),
    campaign  INT
);
GO

-- household demographics table
IF OBJECT_ID('bronze.hh_demographics', 'U') IS NOT NULL
    DROP TABLE bronze.hh_demographics;
GO

CREATE TABLE bronze.hh_demographics (
    classification_1 NVARCHAR(50),
    classification_2 NVARCHAR(50),
    classification_3 NVARCHAR(50),
    homeowner_desc NVARCHAR(50),
    classification_5 NVARCHAR(50),
    classification_4 NVARCHAR(50),
    kid_category_desc NVARCHAR(50),
    household_key INT
);
GO

-- product table
IF OBJECT_ID('bronze.product', 'U') IS NOT NULL
    DROP TABLE bronze.product;
GO

CREATE TABLE bronze.product (
    product_id INT,
    manufacturer INT,
    department NVARCHAR(50),
    brand NVARCHAR(50),
    commodity_desc NVARCHAR(50),
    sub_commodity_desc NVARCHAR(50),
    curr_size_of_product NVARCHAR(50)
);
GO

-- transaction table
IF OBJECT_ID('bronze.transaction_data', 'U') IS NOT NULL
    DROP TABLE bronze.transaction_data ;
GO

CREATE TABLE bronze.transaction_data (
    household_key INT,
    basket_id VARCHAR(50),
    day INT,
    product_id INT,
    quantity INT,
    sales_value FLOAT,
    store_id INT,
    retail_disc FLOAT ,
    trans_time INT,
    week_no INT,
    coupon_disc DECIMAL(10, 2),
    coupon_match_disc DECIMAL(10, 2)   
);
GO