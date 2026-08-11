use complete_journey
GO

SELECT DB_NAME() AS current_database, @@SERVERNAME AS server_name;

TRUNCATE TABLE bronze.campaign_desc;
BULK INSERT bronze.campaign_desc
		FROM 'C:\Disk D\dunnhumby_The-Complete-Journey\dunnhumby_The-Complete-Journey\data\campaign_desc.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
			TABLOCK
		);   
SELECT *
FROM bronze.campaign_desc;

TRUNCATE TABLE bronze.campaign_table;
BULK INSERT bronze.campaign_table
		FROM 'C:\Disk D\dunnhumby_The-Complete-Journey\dunnhumby_The-Complete-Journey\data\campaign_table.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
			TABLOCK
		);   
SELECT *
FROM bronze.campaign_table;

TRUNCATE TABLE bronze.coupon;
BULK INSERT bronze.coupon
		FROM 'C:\Disk D\dunnhumby_The-Complete-Journey\dunnhumby_The-Complete-Journey\data\coupon.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
			TABLOCK
		);   
SELECT *
FROM bronze.coupon;

TRUNCATE TABLE bronze.coupon_redempt;
BULK INSERT bronze.coupon_redempt
		FROM 'C:\Disk D\dunnhumby_The-Complete-Journey\dunnhumby_The-Complete-Journey\data\coupon_redempt.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
			TABLOCK
		);   
SELECT *
FROM bronze.coupon_redempt;


TRUNCATE TABLE bronze.hh_demographics;
BULK INSERT bronze.hh_demographics
		FROM 'C:\Disk D\dunnhumby_The-Complete-Journey\dunnhumby_The-Complete-Journey\data\hh_demographic.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
			TABLOCK
		);   
SELECT *
FROM bronze.hh_demographics;

TRUNCATE TABLE bronze.product;
BULK INSERT bronze.product
		FROM 'C:\Disk D\dunnhumby_The-Complete-Journey\dunnhumby_The-Complete-Journey\data\product.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
			TABLOCK
		);   
SELECT *
FROM bronze.product;

TRUNCATE TABLE bronze.transaction_data;
BULK INSERT bronze.transaction_data
		FROM 'C:\Disk D\dunnhumby_The-Complete-Journey\dunnhumby_The-Complete-Journey\data\transaction_data.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
			TABLOCK
		);   
SELECT *
FROM bronze.transaction_data;





