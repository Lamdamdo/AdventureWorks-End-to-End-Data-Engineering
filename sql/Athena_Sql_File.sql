
CREATE EXTERNAL TABLE adventureworks_gold.dim_date (
    date_key INT,
    full_date STRING,
    day INT,
    day_name STRING,
    day_of_week INT,
    week_of_year INT,
    month INT,
    month_name STRING,
    quarter INT,
    year INT,
    year_month STRING,
    is_weekend STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = ',',
    'quoteChar' = '"',
    'escapeChar' = '\\'
)
LOCATION 's3://adventureworks-snowflake-2026/curated/DIM_DATE/'
TBLPROPERTIES ('skip.header.line.count'='1');


SELECT
    date_key,
    CAST(full_date AS DATE) AS full_date,
    month_name,
    quarter,
    year,
    is_weekend
FROM adventureworks_gold.dim_date
LIMIT 10;


DROP TABLE adventureworks_gold.dim_customer;



CREATE EXTERNAL TABLE adventureworks_gold.dim_customer (
    CustomerID INT,
    AccountNumber STRING,
    PersonID STRING,
    StoreID STRING,
    TerritoryID STRING,
    CustomerType STRING,
    CustomerName STRING,
    StoreName STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = ',',
    'quoteChar' = '"',
    'escapeChar' = '\\'
)
LOCATION 's3://adventureworks-snowflake-2026/curated/DIM_CUSTOMER/'
TBLPROPERTIES ('skip.header.line.count'='1');



SELECT *
FROM adventureworks_gold.dim_customer
LIMIT 10;




CREATE EXTERNAL TABLE adventureworks_gold.dim_product (
    ProductID INT,
    ProductName STRING,
    ProductNumber STRING,
    Color STRING,
    StandardCost DOUBLE,
    ListPrice DOUBLE,
    Size STRING,
    ProductLine STRING,
    Class STRING,
    Style STRING,
    SubcategoryName STRING,
    CategoryName STRING,
    ModelName STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = ',',
    'quoteChar' = '"',
    'escapeChar' = '\\'
)
LOCATION 's3://adventureworks-snowflake-2026/curated/DIM_PRODUCT/'
TBLPROPERTIES ('skip.header.line.count'='1');

SELECT *
FROM adventureworks_gold.dim_product
LIMIT 10;




CREATE EXTERNAL TABLE adventureworks_gold.dim_territory (
    TerritoryID INT,
    TerritoryName STRING,
    CountryRegionCode STRING,
    CountryName STRING,
    TerritoryGroup STRING,
    SalesYTD DOUBLE,
    SalesLastYear DOUBLE,
    CostYTD DOUBLE,
    CostLastYear DOUBLE
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = ',',
    'quoteChar' = '"',
    'escapeChar' = '\\'
)
LOCATION 's3://adventureworks-snowflake-2026/curated/DIM_TERRITORY/'
TBLPROPERTIES ('skip.header.line.count'='1');


SELECT *
FROM adventureworks_gold.dim_territory
LIMIT 10;




CREATE EXTERNAL TABLE adventureworks_gold.fact_sales (
    SalesOrderID INT,
    SalesOrderDetailID INT,
    CustomerID INT,
    ProductID INT,
    TerritoryID STRING,
    OrderDate STRING,
    DueDate STRING,
    ShipDate STRING,
    OrderStatus STRING,
    OrderQty INT,
    UnitPrice DOUBLE,
    UnitPriceDiscount DOUBLE,
    LineTotal DOUBLE,
    CustomerKey INT,
    ProductKey INT,
    TerritoryKey STRING,
    OrderDateKey INT,
    DueDateKey STRING,
    ShipDateKey STRING,
    DiscountAmount DOUBLE
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = ',',
    'quoteChar' = '"',
    'escapeChar' = '\\'
)
LOCATION 's3://adventureworks-snowflake-2026/curated/FACT_SALES/'
TBLPROPERTIES ('skip.header.line.count'='1');


SELECT *
FROM adventureworks_gold.fact_sales
LIMIT 10;



CREATE EXTERNAL TABLE adventureworks_gold.fact_purchases (
    PurchaseOrderID INT,
    PurchaseOrderDetailID INT,
    VendorID INT,
    ProductID INT,
    OrderDate STRING,
    ShipDate STRING,
    OrderStatus STRING,
    OrderQty INT,
    ReceivedQty INT,
    RejectedQty INT,
    StockedQty INT,
    UnitPrice DOUBLE,
    LineTotal DOUBLE,
    ProductKey INT,
    VendorKey INT,
    OrderDateKey INT,
    ShipDateKey STRING,
    ReceivedValue DOUBLE,
    RejectedValue DOUBLE,
    ReceiptStatus STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = ',',
    'quoteChar' = '"',
    'escapeChar' = '\\'
)
LOCATION 's3://adventureworks-snowflake-2026/curated/FACT_PURCHASES/'
TBLPROPERTIES ('skip.header.line.count'='1');

SELECT *
FROM adventureworks_gold.fact_purchases
LIMIT 10;


SHOW DATABASES;

SHOW TABLES IN adventureworks_gold;
