use complete_journey;
GO

TRUNCATE TABLE silver.campaign_desc;
INSERT INTO silver.campaign_desc (campaign, description, start_day, end_day)
SELECT
    campaign,
    TRIM(description) AS description,
    start_day,
    end_day
FROM bronze.campaign_desc;

SELECT *
FROM silver.campaign_desc;


TRUNCATE TABLE silver.campaign_table;
INSERT INTO silver.campaign_table (campaign, description, household_key)
SELECT
    campaign,
    TRIM(description) AS description,
    household_key
FROM bronze.campaign_table;

SELECT *
FROM silver.campaign_table;
SELECT *
FROM silver.campaign_desc;

--=======================================
-- loading coupon tables into silver layer
--=======================================

TRUNCATE TABLE silver.coupon;
INSERT INTO silver.coupon (coupon_upc, product_id, campaign)
SELECT DISTINCT coupon_upc, product_id, campaign
FROM bronze.coupon; 

--- quick check for duplicates in silver.coupon table
SELECT coupon_upc, product_id, campaign, count(*) as duplicate_count
FROM silver.coupon
GROUP BY coupon_upc, product_id, campaign
HAVING count(*) > 1;

SELECT *
FROM silver.coupon

TRUNCATE TABLE silver.coupon_redempt;
INSERT INTO silver.coupon_redempt (household_key, day, coupon_upc, campaign)
SELECT household_key, day, coupon_upc, campaign 
FROM bronze.coupon_redempt;

SELECT *
FROM silver.coupon_redempt;

--=======================================
-- loading household demographics table into silver layer
--=======================================
TRUNCATE TABLE silver.hh_demographics;
INSERT INTO silver.hh_demographics (
    household_key,
    classification_1,
    classification_2, 
    classification_3, 
    classification_5, 
    classification_4, 
    homeowner_desc,
    kid_category_desc)
SELECT 
    household_key,
    classification_1,
    classification_2, 
    classification_3, 
    classification_5, 
    classification_4, 
    homeowner_desc,
    kid_category_desc
FROM bronze.hh_demographics;

--=======================================
-- loading product table into silver layer
--=======================================
TRUNCATE TABLE silver.product;
INSERT INTO silver.product (
    product_id,
    manufacturer,
    department, 
    brand, 
    commodity_desc,
    sub_commodity_desc,
    curr_size_of_product)
SELECT product_id, manufacturer, 
    CASE 
        WHEN TRIM(department) = ' ' THEN 'unknown' 
        ELSE TRIM(department) END AS department,
        brand,        
    CASE 
        WHEN TRIM(commodity_desc) = ' ' THEN 'NO COMMODITY DESCRIPTION' -- this has been used in other rows 
        ELSE TRIM(commodity_desc) END AS commodity_desc,
    CASE 
        WHEN TRIM(sub_commodity_desc) = ' ' THEN 'NO SUBCOMMODITY DESCRIPTION' -- this has been used in other rows
        ELSE TRIM(sub_commodity_desc) END AS sub_commodity_desc,
    CASE 
        WHEN TRIM(curr_size_of_product) = ' ' THEN 'unknown' 
        ELSE TRIM(curr_size_of_product) END AS curr_size_of_product
FROM bronze.product;
SELECT *
FROM silver.product;

--=============================================
-- loading transactions table into silver layer
--=============================================
TRUNCATE TABLE silver.transaction_data;
INSERT INTO silver.transaction_data (
    household_key,
    basket_id,
    product_id,
    store_id,
    day,
    week_no,
    trans_time,
    quantity,
    sales_value,
    retail_disc,
    coupon_disc,
    coupon_match_disc)
SELECT household_key,
    basket_id,
    product_id,
    store_id,
    day,
    week_no,
    trans_time,
    quantity,
    sales_value,
    retail_disc,
    coupon_disc,
    coupon_match_disc
FROM bronze.transaction_data
WHERE quantity > 0   
SELECT *
FROM silver.transaction_data;