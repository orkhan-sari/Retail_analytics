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
    - 
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
-- Soft dinks, fluid milk , and bread/bun/rolls are the top 3 commodities purchsed

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
WHERE cumulative_sales_share <= 80 -- 95 commudities generate 80% of the total sales value.


--=====================================
-- 3. Customer analytics 
--=====================================
/*
    - Calculate customer lifetime value (CLV) for the whole of the period available
     and average sales per transaction for each customer. Identify top 50 customers based on the CLV metric. 
    - Identify frequent, medium and low frequency shoppers. 
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

