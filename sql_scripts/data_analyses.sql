/*
===============================================================================
Data Analysis
===============================================================================
*/

use complete_journey
GO

SELECT * FROM Information_Schema.Tables
WHERE Table_Schema IN ('bronze', 'silver', 'gold')

SELECT * FROM Information_Schema.COLUMNS
WHERE Table_Schema = 'gold'

--=====================================
-- 1. Business overview by key metrics 
--=====================================
/*
How large is the business?
Let's calculate some key metrics to understand the size of the business. I will calculate the following:

   - Number of clients
   - Number of products
   - Number of stores
   - Number of transactions
   - Total sales value
*/
SELECT *
FROM gold.transaction_data

SELECT 'Number of clients' AS Measure, count(DISTINCT household_key) as Measure_Value FROM gold.transaction_data
UNION ALL
SELECT 'Number of products', count(DISTINCT product_id) FROM gold.transaction_data 
UNION ALL
SELECT 'Number of stores', count(DISTINCT store_id) FROM gold.transaction_data 
UNION ALL
SELECT 'Number of transactions', count( DISTINCT basket_id) FROM gold.transaction_data
UNION ALL
SELECT 'Total sales value', SUM(sales_value) FROM gold.transaction_data

/*
Which departments and brands are the most popular among customers, 
and who are our top manufacturers by customer size and total sales value?
I will calculate the following metrics to answer these questions:
    - Total customers by product departments and brand types seperately.
    - Average sales value in each department and brand types seperately.
    - Total revenue generated for each department and brand types seperately.
    - Number of transactions for each department and brand types seperately.
    - Who are the top 10 manufacturers by customers size and total sales value?
*/
SELECT *
FROM gold.transaction_data

SELECT *
FROM gold.product

-- department level analysis
SELECT p.department, 
    COUNT(DISTINCT td.household_key) AS total_customers,
    AVG(td.sales_value) AS avg_sales_value,
    SUM(td.sales_value) AS total_revenue,
    count(DISTINCT td.basket_id) AS total_transactions
FROM gold.transaction_data td
JOIN gold.product p
    ON td.product_id = p.product_id
GROUP BY p.department
ORDER BY total_revenue DESC

/*
    Grocery department generates the highest revenue, followed by the Drug GM department.
    Average sales value is greated in DRUG GM department, followed by the Grocery department.
    As expected, average sales value is much greater in Kiosk-Gas department than in other departments.
*/

-- brand level analysis
SELECT p.brand, 
    COUNT(DISTINCT td.household_key) AS total_customers,
    AVG(td.sales_value) AS avg_sales_value,
    SUM(td.sales_value) AS total_revenue,
    count(DISTINCT td.basket_id) AS total_transactions
FROM gold.transaction_data td
JOIN gold.product p
    ON td.product_id = p.product_id
GROUP BY p.brand
ORDER BY total_revenue DESC
/* 
    Total revenue generated from natinal brands is double of that from private label brands.
    Total customer size is very similar for both brand types, indicating that consumers buy 
    both brand types in similar proportions. 
    However, the average sales value is higher for national brands, 
    indicating that consumers are willing to pay on average more for national brands than private label brands.
    Moreover, consumers buy national brands more frequently than private label brands.
*/

-- Who are the top 10 manufacturers by customers size and total sales value?
SELECT TOP 10 p.manufacturer, 
    COUNT(DISTINCT td.household_key) AS total_customers,
    SUM(td.sales_value) AS total_revenue
FROM gold.transaction_data td
JOIN gold.product p
    ON td.product_id = p.product_id
GROUP BY p.manufacturer
ORDER BY total_revenue DESC

--=====================================
-- 2. Overview of the sales performance 
--=====================================
/*
    - Which commodities are the most frequently purchased by customers?- 
    - Which commodities generate the most revenue? Let's identify their share in total sales value.
    - What percentage of products generates 80% of sales?
*/

select p.commodity_desc,
    Count(p.commodity_desc) as total_units_sold
from gold.transaction_data td
JOIN gold.product p
    ON td.product_id = p.product_id
GROUP BY p.commodity_desc
ORDER BY total_units_sold DESC;
-- Soft dinks, fluid milk , and bread/bun/rolls are the top 3 commodities purchased

WITH comm_sales AS (
    select p.commodity_desc,
        SUM(td.sales_value) as total_sales
    from gold.transaction_data td
    JOIN gold.product p
        ON td.product_id = p.product_id
    GROUP BY p.commodity_desc
)
select commodity_desc,
    total_sales,
    sum(total_sales) OVER() AS total,
    CONCAT(ROUND(CAST(total_sales/sum(total_sales) OVER() * 100 AS DECIMAL(5,2)),2), '%') AS sales_share
FROM comm_sales
ORDER BY sales_share DESC
/*
8% of the total revenue comes from Coupon/Misc items and 4% from soft drinks and beef each. 
*/

/* Let's look at cumulative sales share and commodity count to understand 
how many products are forming what percetage of the sales */

WITH comm_sales AS (
    select p.commodity_desc,
        SUM(td.sales_value) as total_sales
    from gold.transaction_data td
    JOIN gold.product p
        ON td.product_id = p.product_id
    GROUP BY p.commodity_desc
)
SELECT commodity_desc,
    sales_share,
    SUM(sales_share) OVER(ORDER BY Sales_share DESC) AS cumulative_sales_share,
    count(commodity_desc) OVER(ORDER BY Sales_share DESC) AS cumulative_commodity_count
FROM (
    select commodity_desc,
        total_sales,
        sum(total_sales) OVER() AS total,
        (total_sales/sum(total_sales) OVER() * 100) AS sales_share
    FROM comm_sales
    ) t;

-- What percentage of products generates 80% of sales?

WITH comm_sales AS (
    select p.commodity_desc,
        SUM(td.sales_value) as total_sales
    from gold.transaction_data td
    JOIN gold.product p
        ON td.product_id = p.product_id
    GROUP BY p.commodity_desc
),
share AS (
    select commodity_desc,
        total_sales,
        sum(total_sales) OVER() AS total,
        (total_sales/sum(total_sales) OVER() * 100) AS sales_share
    FROM comm_sales
),
cummulative AS (
    SELECT commodity_desc,
    sales_share,
    SUM(sales_share) OVER(ORDER BY Sales_share DESC) AS cumulative_sales_share,
    count(commodity_desc) OVER(ORDER BY Sales_share DESC) AS cumulative_commodity_count
    FROM share)
SELECT COUNT(commodity_desc) AS total_commodities_generating_80_percent_of_sales
FROM cummulative
WHERE cumulative_sales_share <= 80 -- 95 (out of 307) commodities generate 80% of the total sales value.


--=====================================
-- 3. Customer analytics 
--=====================================
/*
    - Calculate customer lifetime value (CLV) for the whole of the period available
     and average sales per transaction for each customer. Identify top 50 customers based on the CLV metric. 
    - Identify frequent, medium and low frequency shoppers. 
    - Customer recency: how much time has passed since their last purchase? 
    - 
*/

SELECT TOP 50
    household_key,
    SUM(sales_value) as CLV,
    FORMAT(
        ROUND(CAST(SUM(sales_value) / count(DISTINCT basket_id) AS DECIMAL(10,2)), 2),
             'C', 'en-US') AS avg_sales_value_per_transaction,
    ROW_NUMBER() OVER(ORDER BY SUM(sales_value) DESC) AS rank
FROM gold.transaction_data
GROUP BY household_key
ORDER BY CLV DESC;

WITH tot_transact AS(
        SELECT
        household_key,
        COUNT(DISTINCT basket_id) AS total_transactions
    FROM gold.transaction_data
    group by household_key
    ),
    ntile_seg AS (
        SELECT household_key,
        total_transactions,
        NTILE(3) OVER(ORDER BY total_transactions DESC) AS frequency_segment
FROM tot_transact
    )
SELECT household_key,
    total_transactions,
    CASE WHEN frequency_segment = 1 THEN 'Frequent'
         WHEN frequency_segment = 2 THEN 'Medium'
         WHEN frequency_segment = 3 THEN 'Low'
    END AS frequency_segment
FROM ntile_seg;

-- customer recency
SELECT MAX(day) as last_purchase_date
FROM gold.transaction_data 
-- 711 is the last day of the dataset, so we can use this to calculate recency for each customer

SELECT household_key,
    count(DISTINCT basket_id) AS number_of_purchases,
    MIN(DAY) as first_purchase_date,
    MAX(DAY) as last_purchase_date,
    MAX(DAY) - MIN(DAY) AS days_between_first_and_last_purchase,
    (SELECT MAX(day) FROM gold.transaction_data ) - MAX(DAY) AS days_since_last_purchase
FROM gold.transaction_data
group by household_key
ORDER BY days_since_last_purchase DESC
/* some customers were one time shoppers,
 and some customers were around for a couple of weeks are left.
 This identifies inactive customers of the bussiness and one time shoppers*/


--=====================================
-- 4. Basket analyses 
--=====================================
/*
    - What is the average weekly basket size and value for each customer?
        - I cosnider basket size as product diversity and not the quantity of products purchased.
    - How does average basket size grow over time for each customer?
    - Which products are bought together most frequently? 
        - Let's identify the top 10 product pairs
    - Which departments' products are purhcased together most frequently? 
*/

SELECT household_key,
    week_no, 
    SUM(basket_size) AS total_basket_size,
    AVG(basket_size) AS average_basket_size,
    AVG(sales_value) AS average_basket_value
FROM (
    SELECT household_key,
        week_no, 
        basket_id,
        COUNT(DISTINCT product_id) AS basket_size,
        SUM(sales_value) AS sales_value -- will be unique anyways 
    FROM gold.transaction_data
    GROUP BY household_key, week_no, basket_id
    ) as basket_data
GROUP BY household_key, week_no
ORDER BY household_key, week_no
-- Most customers seem to make purchases once or twice a week. 
-- Let's investigate how the average basket size and sales grow over quartals. 

SELECT household_key,
    quartal, 
    AVG(basket_size) AS average_basket_size,
    AVG(sales_value) AS average_basket_value,
    SUM(sales_value) AS total_sales_value
FROM (
    SELECT household_key,
        quartal, 
        basket_id,
        COUNT(DISTINCT product_id) AS basket_size,
        SUM(sales_value) AS sales_value -- will be unique anyways
    FROM gold.transaction_data
    GROUP BY household_key, quartal, basket_id
    ) as basket_data
GROUP BY household_key, quartal
ORDER BY household_key, quartal
/* We can eyeball to investigate any patterns in the average basket size
 and sales value over quartals. Let's explore this further*/

WITH basket_data AS(
    SELECT household_key,
        quartal, 
        basket_id,
        COUNT(DISTINCT product_id) AS basket_size,
        SUM(sales_value) AS sales_value -- will be unique anyways
    FROM gold.transaction_data
    GROUP BY household_key, quartal, basket_id
),
averages AS (SELECT household_key,
    quartal, 
    AVG(basket_size) AS average_basket_size,
    AVG(sales_value) AS average_basket_value
    FROM basket_data
    GROUP BY household_key, quartal)
SELECT household_key,
    quartal, 
    average_basket_size,
    LEAD(average_basket_size) OVER(PARTITION BY household_key 
                            ORDER BY quartal) - average_basket_size AS Growth_in_basket_size
FROM averages

-- Which products are bought together most frequently?
SELECT TOP 10
    td.product_id AS product_1,
    td2.product_id AS product_2,
    COUNT(DISTINCT td.basket_id) AS number_of_times_bought_together
FROM gold.transaction_data td
JOIN gold.transaction_data td2
    ON td.basket_id = td2.basket_id
    AND td.product_id < td2.product_id -- to avoid duplicates
GROUP BY  td.product_id, td2.product_id
ORDER BY number_of_times_bought_together DESC;

-- Which departments' products are purhcased together most frequently?
with departments AS (
    SELECT td.basket_id, 
            p.department
    from gold.transaction_data td
    JOIN gold.product p
        ON td.product_id = p.product_id)
SELECT TOP 10
    d.department as department_1,
    d2.department as department_2,
    COUNT(DISTINCT d.basket_id) AS number_of_times_bought_together
FROM departments d
JOIN departments d2
    ON d.basket_id = d2.basket_id
    AND d.department < d2.department -- to avoid duplicates
GROUP BY  d.department, d2.department
ORDER BY number_of_times_bought_together DESC;

--=====================================
-- 5. Coupon analyses 
--=====================================
/*
- How important are loyalty discounts to total sales? Compare sales with discount and without discount.
- Which campaign generated the most redemptions?
- Which customer segments respond most to coupons?
- Do promotions increase basket size?
*/

SELECT loyalty_discount_applied,
     count(loyalty_discount_applied) AS total_transactions,
    sum(sales_value) AS total_sales_value,
    AVG(sales_value) AS average_sales_value
FROM gold.transaction_data
GROUP BY loyalty_discount_applied
-- similar number of transactions with and without loyalty discount applied.
-- higher total sales value when loyalty discount is applied than when not applied.


/* Let's explore if customers are more likely to spend more when 
they redeem a loyalty discount for any product during the shopping instance*/
SELECT 
    sales_with_discount,
    count(sales_with_discount) AS total_transactions,
    SUM(sales_value) AS total_sales_value,
    AVG(sales_value) AS average_sales_value
FROM(
    select basket_id, loyalty_discount_applied, sales_value,
        MAX(CASE WHEN loyalty_discount_applied = 'Yes' THEN  1 ELSE 0 END) OVER(
            PARTITION BY basket_id) AS sales_with_discount
    from gold.transaction_data
) t
GROUP BY sales_with_discount

/* 
Indeed at instances where customers redeem a loyalty discount for any product,
    they have spent more in total.
However, on average terms, they spend less than when they do not redeem a loyalty discount 
    during the shopping instance instance. This interesting and counterintuitive finding
    worth exploring for outliers. 
*/

-- Which campaign generated the most redemptions?

WITH campaign_table AS (
    SELECT campaign,
        redemption_status,
        COUNT(redemption_status) AS count
    FROM gold.coupon
    GROUP BY campaign, redemption_status
    ),
coupon_table AS(
    SELECT campaign_table.*, gc.description
    FROM campaign_table
    LEFT JOIN gold.campaign gc
        ON campaign_table.campaign = gc.campaign
)
SELECT description, redemption_status,
    count(description) as count
FROM coupon_table
GROUP BY description, redemption_status
ORDER BY description, redemption_status
/* Type A campaign had more coupons and exactly half were redeemed.  
 More of Type C campaings were redeemed which indicates better targeting.
*/

-- Which customer segments respond most to coupons?
/* NOTE: data only provides information for the portion of clients and does not provide information on specific coupons sent to customers. 
Thus we only have information about clients who redeemed their coupons and not those who did not redeem their coupons. 
This is not possible to retreive from the data provided*/


SELECT gc.household_key, gc.campaign, gc.redemption_status,
        gh.age_group,
        gh.home_ownership_status, -- some missing due to the portion of clients covered
        gh.kids_in_household
INTO #temp_customer_analytics
FROM gold.coupon gc
LEFT JOIN gold.hh_demographics gh
    ON gc.household_key = gh.household_key
WHERE redemption_status = 'Redeemed'

SELECT age_group,
    COUNT(age_group) AS count
FROM #temp_customer_analytics
GROUP BY age_group
ORDER BY count DESC
-- Most of the redeemed coupons were redeemed by customers in Age group 4

SELECT home_ownership_status, 
    COUNT(home_ownership_status) AS count
FROM #temp_customer_analytics
GROUP BY home_ownership_status
ORDER BY count DESC
-- Most of the redeemed coupons were redeemed by hoemowners

SELECT kids_in_household,
    COUNT(kids_in_household) AS count
FROM #temp_customer_analytics
GROUP BY kids_in_household
ORDER BY count DESC
-- Most of the redeemed coupons were redeemed by customers with no or unknown kids 