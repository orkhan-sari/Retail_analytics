use complete_journey
GO

SELECT *
FROM bronze.campaign_desc
ORDER BY campaign ASC;

SELECT *
FROM bronze.campaign_table
ORDER BY campaign ASC;

SELECT *
FROM bronze.coupon;

SELECT *
FROM bronze.coupon_redempt;

SELECT *
FROM bronze.hh_demographics;

SELECT *
FROM bronze.product;

SELECT *
FROM bronze.transaction_data







 /*       
SELECT DISTINCT(sales_value)
FROM bronze.transaction_data
ORDER BY sales_value ASC*/