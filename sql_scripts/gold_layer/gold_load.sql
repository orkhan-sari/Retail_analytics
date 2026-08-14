/*
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents tables created for the analytics.
===============================================================================
*/

use complete_journey;
GO
--=========
-- campaign
--=========
IF OBJECT_ID('gold.campaign', 'V') IS NOT NULL
    DROP VIEW gold.campaign;
GO

CREATE VIEW gold.campaign AS
SELECT ct.campaign, ct.description, ct.household_key, cs.start_day, cs.end_day
FROM silver.campaign_table ct
LEFT JOIN silver.campaign_desc cs 
    ON ct.campaign = cs.campaign;
GO

SELECT *
FROM gold.campaign;
--=======
-- coupon
--=======
SELECT *
FROM silver.coupon
WHERE NOT EXISTS (
    SELECT 1
    FROM silver.coupon_redempt cr
    WHERE cr.coupon_upc = silver.coupon.coupon_upc
); -- 12697 copons sent have not been redeemed

SELECT *
FROM silver.coupon
WHERE EXISTS (
    SELECT 1
    FROM silver.coupon_redempt cr
    WHERE cr.coupon_upc = silver.coupon.coupon_upc
); -- 106687 copons sent have been redeemed on some products within campaigns 

IF OBJECT_ID('gold.coupon', 'V') IS NOT NULL
    DROP VIEW gold.coupon;

CREATE VIEW gold.coupon AS
WITH cte AS (
    SELECT cc.coupon_upc, cc.product_id, cc.campaign, cr.household_key, cr.day
    FROM silver.coupon cc
    LEFT JOIN silver.coupon_redempt cr 
        ON cc.coupon_upc = cr.coupon_upc AND cc.campaign = cr.campaign
)
SELECT *,
CASE 
        WHEN household_key IS NULL THEN 'Not Redeemed'
        ELSE 'Redeemed'
    END AS redemption_status
FROM cte;
GO

SELECT *
from gold.coupon
-- HHs have redeemped their copuons on some or all products but not necessarily on all products within the campaign.
SELECT *
FROM gold.campaign
--================
-- hh_demographics
--================
IF OBJECT_ID('gold.hh_demographics', 'V') IS NOT NULL
    DROP VIEW gold.hh_demographics;

CREATE VIEW gold.hh_demographics AS
SELECT 
    household_key,
    classification_1 AS age_group,
    classification_2,
    classification_3,
    classification_4,
    classification_5,
    homeowner_desc AS home_ownership_status,
    kid_category_desc AS kids_in_household
FROM silver.hh_demographics;
GO

SELECT *
FROM gold.hh_demographics

--=================
-- product
--=================
IF OBJECT_ID('gold.product', 'V') IS NOT NULL
    DROP VIEW gold.product;

CREATE VIEW gold.product AS
SELECT product_id,
    manufacturer,
    department, 
    brand, 
    commodity_desc,
    sub_commodity_desc,
    curr_size_of_product AS product_size
FROM silver.product;

SELECT *
FROM gold.product;

--=============
-- transaction
--=============

SELECT *
FROM silver.transaction_data
/* In some cases, the sales value is equal to zero for purhcased pruducts.
 This is porbably because the product was purchased using a coupon and the customer paid nothing for it.
 Let's check if there is a retail_disc or coupon_match_disc for these products */     
SELECT *
FROM silver.transaction_data
WHERE sales_value = 0 AND retail_disc = 0 AND coupon_match_disc = 0
/* there are 702 rows with sales_value = 0 and no retail_disc or coupon_match_disc.
As business rule, I will assume that these products were purchased for free and 
the customer paid nothing for them.
I will set the customer paid per unit to zero for these products. */

/* for some cases, there are copupon_disc but no purchase resuntin gin negative customer paid.
This is because the coupon_disc is not applied to the product purchased 
but maybe to some other product purchased in the same transaction. */
IF OBJECT_ID('gold.transaction_data', 'V') IS NOT NULL
    DROP VIEW gold.transaction_data;

CREATE VIEW gold.transaction_data AS
WITH cte AS (
SELECT *,
    CASE WHEN retail_disc<0
        THeN 'YES'
        ELSE 'NO'
    END AS loyalty_discount_applied,
    sales_value - (retail_disc + coupon_match_disc)/quantity AS shelf_price
FROM silver.transaction_data)
SELECT 
    household_key,
    basket_id,
    product_id,
    store_id,
    day,
    week_no,
    CEILING(week_no / 13.0) AS quartal,
    trans_time,
    quantity,
    retail_disc,
    coupon_disc,
    coupon_match_disc,
    loyalty_discount_applied, 
    shelf_price,
    sales_value
FROM cte;

SELECT *
FROM gold.transaction_data