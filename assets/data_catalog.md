# Data Catalog for Gold Layer

## Overview
The Gold Layer is the business-level data representation, structured to support analytical and reporting use cases.
---

### 1. **gold.transaction_data**
- **Purpose:** Stores transaction details of all products purchased by households within the dataset.
- **Columns:**

| Column Name                 | Data Type     | Description                                                      |
|-----------------------------|---------------|------------------------------------------------------------------|
| household_key               | INT           | Uniquely identifies each household.                              |
| basket_id                   | VARCHAR(50)   | Uniquely identifies a purchase occasion                          |
| product_id                  | INT           | Uniquely identifies each product.                                |
| store_id                    | INT           | Identifies unique stores                                         |
| day                         | INT           | Day when transaction occurred                                    |
| week_no                     | INT           | Week of the transaction. Ranges 1 – 102                          |
| quartal                     | INT           | Quartal of the transaction. Ranges 1 – 8                         |
| trans_time                  | INT           | Time of day when transaction occurred                            |
| quanitity                   | INT           | Number of the products purchased during the trip                 |
| retail_desc                 | DECIMAL(10, 2)| Discount applied due to retailer’s loyalty card programme        |
| coupon_desc                 | DECIMAL(10, 2)| Discount applied due to manufacturer coupon                      |
| coupon_match_desc           | DECIMAL(10, 2)| Discount applied due to retailer’s match of manufacturer coupon  |
| loyalty_discount_applied    | VARCHAR(50)   | If loyalty discount was applied to the item                      |
| shelf_price                 | DECIMAL(10, 2)| Shelf price in $                                                 |
| sales_value                 | DECIMAL(10, 2)| Amount of dollars retailer receives from the sales ($)           |
---

### 2. **gold.product**
- **Purpose:** Stores information on each product sold such as type of product, national or private label and a brand identifier.
- **Columns:**

| Column Name                 | Data Type     | Description                                                 |
|-----------------------------|---------------|-------------------------------------------------------------|
| product_id                  | INT           | Uniquely identifies each product.                           |
| manufacturer                | INT           | Code that links products with same manufacturer together    |
| department                  | NVARCHAR(50)  | Groups similar products together                            |
| brand                       | NVARCHAR(50)  | Indicates Private or National label brand                   |
| commodity_desc              | NVARCHAR(50)  | Groups similar products together at a lower level           |
| sub_commodity_desc          | NVARCHAR(50)  | Groups similar products together at the lowest level        |
| product_size                | NVARCHAR(50)  | Indicates package size (not available for all products)     |

### 3. **gold.hh_demographics** 
- **Purpose:** Stores information on demographic information for a portion of households
- **Columns:**

| Column Name                 | Data Type     | Description                                                            |
|-----------------------------|---------------|------------------------------------------------------------------------|
| household_key               | INT           |  Uniquely identifies each household.                                   |
| age_group                   | NVARCHAR(50)  | Ordered; Possible values: Group1 through to Group6.                    |
| classification 2            | NVARCHAR(50)  | Household level demographic segmentation. Values have meaningful order.|
| classification 3            | NVARCHAR(50)  | Household level demographic segmentation. Values have meaningful order.|
| classification 4            | NVARCHAR(50)  | Household level demographic segmentation. Values have meaningful order.|
| classification 5            | NVARCHAR(50)  |Household level demographic segmentation. Values have meaningful order. |
| home_ownership_status       | NVARCHAR(50)  | Indicates home ownership status                                        |
| kids_in_household           | NVARCHAR(50)  | values: 1,2,3+, and unknown                                            |

### 4. **gold.campaign**
- **Purpose:** Stores information on each campaigns by each household's and campaign periods
- **Columns:**

| Column Name        | Data Type     | Description                                       |
|--------------------|---------------|---------------------------------------------------|
| campaign           | INT           |  Uniquely identifies each campaign. Ranges 1-30   |
| description        | NVARCHAR(50)  | Type of campaign (TypeA, TypeB or TypeC)          |
| household_key      | INT           |  Uniquely identifies each household.              |
| start_day          | INT           | Start date of campaign                            |
| end_day            | INT           | End date of campaign                              |

### 5. **gold.coupon**
- **Purpose:** Stores infromation on coupons sent to customers as part of a campaign, as well as the products for which each coupon is  and if the coupo is redeemed.
- **Columns:**

| Column Name        | Data Type     | Description                                       |
|--------------------|---------------|---------------------------------------------------|
| copuon_upc         | VARCHAR(50)   | Uniquely identifies each coupon (unique to household and campaign)|
| product_id         | INT           | Uniquely identifies each product.                                 |
| campaign           | INT           | Uniquely identifies each campaign. Ranges 1-30                    |
| household_key      | INT           | Uniquely identifies each household.                               |
| day                | INT           | Day when the transaction occurred                                 |
| redemption_status  | VARCHAR(12)   | If the coupon was redeemed                                        |
