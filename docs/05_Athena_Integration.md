# Amazon Athena Integration

## 1. Overview

Amazon Athena was used as the query layer for the curated Gold datasets stored in Amazon S3.

The six analytical tables created in Snowflake were exported to the S3 curated layer. Athena was then configured to query these datasets directly from S3 without moving the data into another database.

## 2. S3 Curated Data

The Gold datasets were stored in the following S3 location:

`s3://adventureworks-snowflake-2026/curated/`

Each dataset was exported into its own folder:

```text
curated/
├── DIM_CUSTOMER/
├── DIM_DATE/
├── DIM_PRODUCT/
├── DIM_TERRITORY/
├── FACT_PURCHASES/
└── FACT_SALES/
```

## 3. Athena Database Setup

Created an Athena database named `adventureworks_gold` to organize the external tables.

```sql
CREATE DATABASE adventureworks_gold;
```

## 4. External Table Creation

Six external tables were manually created in Athena using `CREATE EXTERNAL TABLE`.

Each table points to the corresponding S3 folder containing its curated CSV data.

The tables created were:

- `dim_customer`
- `dim_date`
- `dim_product`
- `dim_territory`
- `fact_purchases`
- `fact_sales`

The table definitions included:

- Explicit column names and data types.
- S3 location for each dataset.
- CSV SerDe configuration using `OpenCSVSerde`.
- Comma as the field separator.
- Double quotes as the quote character.
- Header row skipping using `skip.header.line.count = 1`.

Example table definition:

```sql
CREATE EXTERNAL TABLE adventureworks_gold.dim_customer (
    -- Column definitions
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = ',',
    'quoteChar' = '"',
    'escapeChar' = '\\'
)
STORED AS TEXTFILE
LOCATION 's3://adventureworks-snowflake-2026/curated/DIM_CUSTOMER/'
TBLPROPERTIES (
    'skip.header.line.count' = '1'
);
```

The actual table definitions, including all six schemas, are maintained in `Athena_Sql_File.sql` under the `sql/` directory.

## 5. Glue Data Catalog

Athena uses the AWS Glue Data Catalog to store database and table metadata.

A Glue Crawler was attempted for automatic schema discovery, but the operation encountered an account-level `AccessDenied` error.

Since the schemas were already known from the Snowflake Gold tables, the six external tables were created manually in Athena.

No Glue ETL jobs were required because the cleaning and transformation work had already been completed in Snowflake.

## 6. Querying the Curated Data

After creating the external tables, SQL queries were executed in Athena to verify that the datasets were accessible.

Examples:

```sql
SHOW DATABASES;

SHOW TABLES IN adventureworks_gold;

SELECT *
FROM adventureworks_gold.dim_customer
LIMIT 10;

SELECT *
FROM adventureworks_gold.fact_sales
LIMIT 10;
```

These queries helped verify the database, table creation, and access to the curated datasets.

## 7. IAM Permissions

A dedicated IAM user named `PowerBI_Athena_User` was configured for Athena and Power BI connectivity.

The associated policy included permissions for:

- Athena query execution and query results.
- Glue Data Catalog metadata access.
- Reading objects from the S3 curated prefix.
- Listing the project S3 bucket.
- Accessing the Athena query results location.

The Athena query results were configured to use the project's `athena-results/` S3 prefix.

Sensitive credentials and access key information are excluded from this repository.

## 8. Athena Integration Workflow

```text
Snowflake Gold Tables
          |
          v
    S3 Curated Layer
          |
          v
   Glue Data Catalog
          |
          v
   Athena Database
          |
          v
 Six External Tables
          |
          v
    SQL Queries
          |
          v
   Power BI via ODBC
```

## 9. Key Implementation Decisions

- **External tables:** Used to query CSV datasets directly from S3.
- **Manual schema definition:** Created the six tables using known Gold-layer schemas after the Glue Crawler encountered an access error.
- **Glue Data Catalog:** Used to maintain Athena database and table metadata.
- **IAM permissions:** Configured a dedicated IAM user for Athena query execution and curated S3 access.
- **No Glue ETL:** Kept transformations in Snowflake instead of introducing another ETL layer.

## 10. Outcome

Amazon Athena successfully provided a SQL query layer over the six curated Gold datasets stored in S3.

These tables were subsequently accessed through the Athena ODBC driver to connect Power BI to the analytical data.
