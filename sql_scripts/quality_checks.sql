use complete_journey
GO

-- ==================================================================
-- quality checks of bronze tables before loading into silver tables
-- =================================================================

-- Campaign table checks
SELECT *
FROM bronze.campaign_desc
ORDER BY campaign ASC; 
-- checking for nulls
SELECT count(*) AS total_rows,
    SUM(CASE WHEN campaign IS NULL THEN 1 ELSE 0 END) AS null_campaign,
    SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END) AS null_description,
    SUM(CASE WHEN start_day IS NULL OR end_day IS NULL THEN 1 ELSE 0 END) AS null_dates,
    SUM(CASE WHEN end_day < start_day THEN 1 ELSE 0 END) AS bad_day
FROM bronze.campaign_desc;
-- 30 distinct campaigns and no obvious data issues

-- checking for any NULL or duplicate values in the campaign_table
SELECT *
FROM bronze.campaign_table
SELECT count(*) AS total_rows,
    SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END) AS null_description,
    SUM(CASE WHEN household_key IS NULL THEN 1 ELSE 0 END) AS null_household_key,
    SUM(CASE WHEN campaign IS NULL THEN 1 ELSE 0 END) AS null_campaign       
FROM bronze.campaign_table

SELECT DISTINCT CAMPAIGN
FROM bronze.campaign_table;

SELECT DISTINCT description
FROM bronze.campaign_table;

SELECT household_key, campaign, count(*) as duplicate_count
FROM bronze.campaign_table
GROUP BY household_key, campaign
HAVING count(*) > 1;

--=================================================
/* Load campaign_desc and campaign_table into silver tables without any changes
 as there are no data issues */  
--================================================

--===============================================
-- Coupon table checks
-- checking for any NULL or duplicate values in the coupon table
SELECT *, count(*) as duplicate_count
FROM bronze.coupon
GROUP BY coupon_upc, product_id, campaign
ORDER BY duplicate_count DESC; -- many duplicates

-- ! drop duplicates from coupon table
SELECT DISTINCT coupon_upc, product_id, campaign
FROM bronze.coupon; 

-- coupon redemption table checks
SELECT COUNT(*) AS total_rows,
    SUM(CASE WHEN household_key IS NULL THEN 1 ELSE 0 END) AS null_household_key,
    SUM(CASE WHEN coupon_upc    IS NULL THEN 1 ELSE 0 END) AS null_coupon_upc,
    SUM(CASE WHEN day           IS NULL THEN 1 ELSE 0 END) AS null_day,
    SUM(CASE WHEN campaign      IS NULL THEN 1 ELSE 0 END) AS null_campaign
FROM bronze.coupon_redempt;

SELECT *, count(*) as duplicate_count
FROM bronze.coupon_redempt
GROUP BY household_key, day, coupon_upc, campaign
HAVING count(*) > 1; -- no duplicates

--===============================================================
-- Product table checks
-- checking for any NULL or duplicate values in the product table
SELECT *
FROM bronze.product;

SELECT COUNT(*) AS total_rows,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN manufacturer IS NULL THEN 1 ELSE 0 END) AS null_manufacturer,
    SUM(CASE WHEN department IS NULL THEN 1 ELSE 0 END) AS null_department,
    SUM(CASE WHEN brand IS NULL THEN 1 ELSE 0 END) AS null_brand,
    SUM(CASE WHEN commodity_desc IS NULL THEN 1 ELSE 0 END) AS null_commodity_desc,
    SUM(CASE WHEN sub_commodity_desc IS NULL THEN 1 ELSE 0 END) AS null_sub_commodity_desc,
    SUM(CASE WHEN curr_size_of_product IS NULL THEN 1 ELSE 0 END) AS null_curr_size_of_product
FROM bronze.product;

SELECT product_id, COUNT(*) AS duplicate_count
FROM bronze.product
GROUP BY product_id
HAVING COUNT(*) > 1; -- no duplicates in product_id as expected

SELECT DISTINCT department
FROM bronze.product -- empty rows

SELECT *
FROM bronze.product
WHERE department = ' ';

-- ! some columns have no information, replace with 'unknown'
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

-- ===============================================
-- Transaction table checks
SELECT *
FROM bronze.transaction_data;

SELECT count(*) AS total_rows,
    SUM(CASE WHEN household_key IS NULL THEN 1 ELSE 0 END) AS null_household_key,
    SUM(CASE WHEN basket_id IS NULL THEN 1 ELSE 0 END) AS null_basket_id,
    SUM(CASE WHEN day IS NULL THEN 1 ELSE 0 END) AS null_day,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS null_quantity,
    SUM(CASE WHEN sales_value IS NULL THEN 1 ELSE 0 END) AS null_sales_value,
    SUM(CASE WHEN store_id IS NULL THEN 1 ELSE 0 END) AS null_store_id,
    SUM(CASE WHEN retail_disc IS NULL THEN 1 ELSE 0 END) AS null_retail_disc,
    SUM(CASE WHEN trans_time IS NULL THEN 1 ELSE 0 END) AS null_trans_time,
    SUM(CASE WHEN week_no IS NULL THEN 1 ELSE 0 END) AS null_week_no,
    SUM(CASE WHEN coupon_disc IS NULL THEN 1 ELSE 0 END) AS null_coupon_disc,
    SUM(CASE WHEN coupon_match_disc IS NULL THEN 1 ELSE 0 END) AS null_coupon_match_disc
FROM bronze.transaction_data;

SELECT *
FROM bronze.transaction_data                
WHERE sales_value < 0; -- no negative sales values
SELECT *
FROM bronze.transaction_data                
WHERE week_no > 102; -- all in range

SELECT retail_disc
FROM bronze.transaction_data                
WHERE retail_disc> 0 AND retail_disc < 0.005; -- floating point nouse in both retiald_desc and sales_value
-- check in other columns
SELECT TOP 100 *
FROM bronze.transaction_data

SELECT coupon_disc
FROM bronze.transaction_data                
WHERE coupon_disc> 0 AND coupon_disc < 0.005;

SELECT coupon_match_disc
FROM bronze.transaction_data                
WHERE coupon_match_disc > 0 AND coupon_match_disc < 0.005;

SELECT sales_value, quantity, retail_disc, LEN(sales_value)
FROM bronze.transaction_data
WHERE LEN(sales_value) > 9;
/* 
All data with scientific notations on sales_value has 0 sales quantitty, 
so we can ignore these rows or replace with 0 for now. */       

--! The rows with floating point noises are basically 0; let's replace them with 0 in the silver table.
SELECT household_key, basket_id, day, product_id, quantity,
    CASE WHEN sales_value > 0 AND sales_value < 0.005 THEN 0 ELSE sales_value END AS sales_value,
     store_id, 
    CASE WHEN retail_disc > 0 AND retail_disc < 0.005 THEN 0 ELSE retail_disc END AS retail_disc,
    trans_time, week_no, coupon_disc, coupon_match_disc
FROM bronze.transaction_data   

--===============================================
-- Household demographics table checks
SELECT COUNT(*) AS total_rows,
    SUM(CASE WHEN household_key IS NULL THEN 1 ELSE 0 END) AS null_household_key,
    SUM(CASE WHEN classification_1 IS NULL THEN 1 ELSE 0 END) AS null_classification_1,
    SUM(CASE WHEN classification_2 IS NULL THEN 1 ELSE 0 END) AS null_classification_2,
    SUM(CASE WHEN classification_3 IS NULL THEN 1 ELSE 0 END) AS null_classification_3,
    SUM(CASE WHEN homeowner_desc IS NULL THEN 1 ELSE 0 END) AS null_homeowner_desc,
    SUM(CASE WHEN classification_4 IS NULL THEN 1 ELSE 0 END) AS null_classification_4,
    SUM(CASE WHEN classification_5 IS NULL THEN 1 ELSE 0 END) AS null_classification_5,
    SUM(CASE WHEN kid_category_desc IS NULL THEN 1 ELSE 0 END) AS null_kid_category_desc
FROM bronze.hh_demographics;
-- No null

SELECT COUNT(*) AS total_rows,
    SUM(CASE WHEN LEN(TRIM(classification_1)) <> LEN(classification_1) THEN 1 ELSE 0 END) AS null_classification_1,
    SUM(CASE WHEN LEN(TRIM(classification_2)) <> LEN(classification_2) THEN 1 ELSE 0 END) AS null_classification_2,
    SUM(CASE WHEN LEN(TRIM(classification_3)) <> LEN(classification_3) THEN 1 ELSE 0 END) AS null_classification_3,
    SUM(CASE WHEN LEN(TRIM(homeowner_desc)) <> LEN(homeowner_desc) THEN 1 ELSE 0 END) AS null_homeowner_desc,
    SUM(CASE WHEN LEN(TRIM(classification_4)) <> LEN(classification_4) THEN 1 ELSE 0 END) AS null_classification_4,
    SUM(CASE WHEN LEN(TRIM(classification_5)) <> LEN(classification_5) THEN 1 ELSE 0 END) AS null_classification_5,
    SUM(CASE WHEN LEN(TRIM(kid_category_desc)) <> LEN(kid_category_desc) THEN 1 ELSE 0 END) AS null_kid_category_desc
FROM bronze.hh_demographics;
-- No leading or trailing spaces in any of the columns, so no need to trim the values.

SELECT kid_category_desc, COUNT(*) AS count
FROM bronze.hh_demographics
GROUP BY kid_category_desc

SELECT *
FROM bronze.hh_demographics