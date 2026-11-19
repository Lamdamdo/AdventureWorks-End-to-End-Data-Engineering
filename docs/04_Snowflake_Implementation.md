# Snowflake Implementation

## 1. Overview

Snowflake is the central data warehouse and transformation layer in the AdventureWorks end-to-end data engineering project.

It is responsible for ingesting the source CSV files from Amazon S3, organizing the data into structured layers, performing data cleaning and validation, building analytical tables, and exporting the final datasets back to S3 for downstream reporting.

**Database:** `ADVENTUREWORKS_DB`

**Storage Integration:** `ADVENTUREWORKS_S3_INT`

**AWS Region:** `ap-south-1`

## 2. Database and Schema Setup

Created the Snowflake database `ADVENTUREWORKS_DB` with three schemas to separate the different stages of data processing.

| Schema | Purpose |
|---|---|
| RAW | Stores the source datasets ingested from S3. |
| CLEAN | Contains cleaned and validated datasets. |
| ANALYTICS | Contains the final analytical tables used for reporting. |

```sql
CREATE DATABASE IF NOT EXISTS ADVENTUREWORKS_DB;

USE DATABASE ADVENTUREWORKS_DB;

CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CLEAN;
CREATE SCHEMA IF NOT EXISTS ANALYTICS;
```

## 3. AWS Storage Integration

Snowflake was connected to the AWS S3 bucket using a storage integration named `ADVENTUREWORKS_S3_INT`.

The integration uses the IAM role `AdventureWorksSnowflakeRole`, configured separately in AWS.

```sql
CREATE STORAGE INTEGRATION ADVENTUREWORKS_S3_INT
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = S3
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = '<AWS_IAM_ROLE_ARN>'
    STORAGE_ALLOWED_LOCATIONS = (
        's3://adventureworks-snowflake-2026/raw/',
        's3://adventureworks-snowflake-2026/curated/'
    );
```

### How the connection works

1. Created an IAM role in AWS with the required S3 permissions.
2. Created the Snowflake storage integration referencing that IAM role.
3. Retrieved the Snowflake-generated AWS principal and external ID using `DESC STORAGE INTEGRATION`.
4. Updated the IAM role's trust relationship to allow the Snowflake principal to assume the role through AWS STS.
5. Used the storage integration to create external stages in Snowflake.

This role-based authentication avoids storing permanent AWS access keys in Snowflake.

Sensitive account identifiers and external IDs are excluded from this repository.

## 4. External Stages

External stages provide Snowflake with a reusable reference to files stored in S3.

### Raw Stage

Created `ADVENTUREWORKS_S3_STAGE` to access the raw source files.

```sql
CREATE STAGE ADVENTUREWORKS_S3_STAGE
    URL = 's3://adventureworks-snowflake-2026/raw/'
    STORAGE_INTEGRATION = ADVENTUREWORKS_S3_INT;
```

The stage provides access to the five source folders:

- HumanResources
- Person
- Production
- Purchasing
- Sales

Verified the files available through the stage using:

```sql
LIST @ADVENTUREWORKS_S3_STAGE;
```

### Curated Stage

Created a separate external stage named `ADVENTUREWORKS_CURATED_STAGE` to reference the curated S3 location.

This stage is used when exporting the final analytical tables from Snowflake to S3.

## 5. CSV File Formats

Configured Snowflake file formats to handle CSV ingestion and export.

| File Format | Purpose |
|---|---|
| AW_CSV_FORMAT | Handles source CSV files during ingestion. |
| AW_EXPORT_FORMAT | Defines the CSV format used when exporting analytical datasets. |

The ingestion format includes configuration for:

- CSV file type.
- Header handling.
- Optional field enclosure using double quotes.
- NULL value handling.
- Empty fields treated as NULL.
- Trimming surrounding spaces.

These settings help maintain consistent parsing of source CSV files.

## 6. RAW Layer: Data Ingestion

A total of **35 CSV datasets** were loaded from the S3 raw prefix into the Snowflake RAW schema.

The ingestion process used Snowflake's schema inference and `COPY INTO` functionality.

### 6.1 Schema Inference with INFER_SCHEMA

Instead of manually defining the columns for every source table, Snowflake's `INFER_SCHEMA` function was used to inspect the CSV structure and identify column names and data types.

Example:

```sql
SELECT *
FROM TABLE(
    INFER_SCHEMA(
        LOCATION => '@ADVENTUREWORKS_S3_STAGE/Sales/adventureworks.Sales.SalesOrderHeader.csv',
        FILE_FORMAT => 'AW_CSV_FORMAT'
    )
);
```

### 6.2 Automatic Table Creation

The inferred schema was used with `CREATE TABLE ... USING TEMPLATE` to create the corresponding RAW table.

Example:

```sql
CREATE TABLE SALESORDERHEADER
USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(
        INFER_SCHEMA(
            LOCATION => '@ADVENTUREWORKS_S3_STAGE/Sales/adventureworks.Sales.SalesOrderHeader.csv',
            FILE_FORMAT => 'AW_CSV_FORMAT'
        )
    )
);
```

### 6.3 Loading Data with COPY INTO

After creating the table, the source CSV data was loaded using `COPY INTO`.

```sql
COPY INTO SALESORDERHEADER
FROM @ADVENTUREWORKS_S3_STAGE/Sales/
FILES = ('adventureworks.Sales.SalesOrderHeader.csv')
FILE_FORMAT = (FORMAT_NAME = AW_CSV_FORMAT)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
```

### 6.4 Scaling Ingestion to All 35 Datasets

The first two datasets, `SALESORDERHEADER` and `SALESORDERDETAIL`, were used to test the ingestion process.

After validating the approach, the remaining 33 datasets were handled through generated SQL statements.

The process used the S3 stage listing to identify:

- Source folder.
- CSV filename.
- Corresponding table name.

The generated statements created the RAW tables using inferred schemas and loaded the files using `COPY INTO`.

The remaining ingestion statements were maintained separately in `Raw_ingestion.sql`.

This reduced repetitive manual table creation and ingestion work.

## 7. CLEAN Layer: Data Cleaning and Validation

After ingestion, the source tables were examined and transformed into the CLEAN schema.

The cleaning process was performed according to the requirements of individual datasets.

### Data validation

The validation checks included:

- Total row counts.
- Primary key uniqueness.
- NULL values in important columns.
- Invalid numerical values.
- Date consistency.
- Referential integrity between related datasets.
- Duplicate records and business rule violations.

Example: checking order identifiers and NULL values.

```sql
SELECT
    COUNT(*) AS TOTAL_ROWS,
    COUNT(DISTINCT "SalesOrderID") AS UNIQUE_ORDER_IDS,
    COUNT_IF("SalesOrderID" IS NULL) AS NULL_ORDER_IDS
FROM ADVENTUREWORKS_DB.RAW.SALESORDERHEADER;
```

Example: validating order totals.

```sql
SELECT
    COUNT_IF(
        ABS("TotalDue" - ("SubTotal" + "TaxAmt" + "Freight")) > 0.01
    ) AS INVALID_TOTALS
FROM ADVENTUREWORKS_DB.RAW.SALESORDERHEADER;
```

Example: checking referential integrity between order details and order headers.

```sql
SELECT COUNT(*) AS ORPHAN_ORDER_IDS
FROM ADVENTUREWORKS_DB.RAW.SALESORDERDETAIL D
LEFT JOIN ADVENTUREWORKS_DB.RAW.SALESORDERHEADER H
    ON D."SalesOrderID" = H."SalesOrderID"
WHERE H."SalesOrderID" IS NULL;
```

### Data transformations

Transformations included:

- Rounding financial values to two decimal places.
- Applying appropriate numeric precision using `NUMBER(18,2)`.
- Trimming unnecessary spaces from text fields.
- Converting empty text values to NULL where required.
- Preserving source records where no transformation was necessary.

Example: creating the cleaned Sales Order Header table.

```sql
CREATE OR REPLACE TABLE ADVENTUREWORKS_DB.CLEAN.SALESORDERHEADER AS
SELECT * REPLACE (
    ROUND("SubTotal", 2)::NUMBER(18,2) AS "SubTotal",
    ROUND("TaxAmt", 2)::NUMBER(18,2) AS "TaxAmt",
    ROUND("Freight", 2)::NUMBER(18,2) AS "Freight",
    ROUND("TotalDue", 2)::NUMBER(18,2) AS "TotalDue"
)
FROM ADVENTUREWORKS_DB.RAW.SALESORDERHEADER;
```

Example: standardizing product text and financial columns.

```sql
SELECT * REPLACE (
    ROUND("StandardCost", 2)::NUMBER(18,2) AS "StandardCost",
    ROUND("ListPrice", 2)::NUMBER(18,2) AS "ListPrice",
    TRIM("Name") AS "Name",
    TRIM("ProductNumber") AS "ProductNumber",
    NULLIF(TRIM("Color"), '') AS "Color"
)
FROM ADVENTUREWORKS_DB.RAW.PRODUCT;
```

The cleaned datasets were stored in the CLEAN schema for downstream analytical modeling.

## 8. ANALYTICS Layer: Gold Tables

After cleaning and validating the source datasets, six analytical Gold tables were created in the ANALYTICS schema.

| Gold Table | Purpose |
|---|---|
| DIM_CUSTOMER | Customer-related analytical attributes. |
| DIM_DATE | Date dimension for time-based analysis. |
| DIM_PRODUCT | Product-related analytical attributes. |
| DIM_TERRITORY | Sales territory information. |
| FACT_PURCHASES | Purchasing-related transactional data. |
| FACT_SALES | Sales-related transactional data. |

These tables provide a structured analytical model for reporting and business analysis.

The dimension tables provide descriptive business attributes, while the fact tables contain transactional measures.

## 9. Exporting Gold Tables to S3

Once the analytical tables were ready, the six Gold datasets were exported from Snowflake to the curated S3 prefix.

**Destination:**

`s3://adventureworks-snowflake-2026/curated/`

Each table was exported into its own folder.

```text
curated/
├── DIM_CUSTOMER/
├── DIM_DATE/
├── DIM_PRODUCT/
├── DIM_TERRITORY/
├── FACT_PURCHASES/
└── FACT_SALES/
```

The exported CSV files were subsequently made available to Amazon Athena for querying.

## 10. Final Snowflake Workflow

```text
Amazon S3 - Raw CSV Files
          |
          v
Storage Integration
          |
          v
External Stage
          |
          v
RAW Schema
          |
          v
Data Cleaning and Validation
          |
          v
CLEAN Schema
          |
          v
Analytical Transformations
          |
          v
ANALYTICS Schema
          |
          v
Six Gold Tables
          |
          v
Amazon S3 - Curated Layer
```

## 11. Key Implementation Decisions

- **IAM role-based access:** Used a Snowflake storage integration instead of permanent AWS credentials.
- **External stages:** Created reusable references to raw and curated S3 locations.
- **Schema inference:** Used `INFER_SCHEMA` and `USING TEMPLATE` to reduce manual schema definition.
- **COPY INTO:** Used for loading CSV files into RAW tables.
- **Generated ingestion SQL:** Scaled ingestion from two initial test datasets to all 35 datasets.
- **Layered architecture:** Separated ingestion, cleaning, and analytical modeling.
- **Data validation:** Performed quality checks before creating the final analytical tables.
- **Curated exports:** Exported the Gold datasets to S3 for downstream Athena and Power BI reporting.

---
