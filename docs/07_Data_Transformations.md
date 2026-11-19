# Data Transformations

## 1. Overview

Data transformation was performed in Snowflake as part of the AdventureWorks end-to-end data engineering pipeline.

The objective was to convert the 35 raw source datasets into clean, validated, and structured analytical datasets suitable for business reporting.

The transformation process followed three layers:

- RAW
- CLEAN
- ANALYTICS

## 2. RAW Layer

The RAW schema contains the source datasets ingested from the AdventureWorks CSV files stored in Amazon S3.

A total of 35 datasets were loaded into Snowflake.

The RAW layer preserves the ingested source data and acts as the starting point for downstream transformations.

## 3. CLEAN Layer

The CLEAN schema contains the processed datasets.

Each dataset was examined and transformed according to its structure and business requirements.

### Data Cleaning Operations

The cleaning process included:

- Handling NULL and empty values where required.
- Trimming unnecessary spaces from text columns.
- Applying appropriate data types.
- Standardizing numerical precision.
- Rounding financial values to two decimal places.
- Validating dates and important identifiers.
- Checking duplicate records and data consistency.

### Example: Financial Data Standardization

Financial columns were rounded to two decimal places and converted to `NUMBER(18,2)`.

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

### Example: Text Standardization

Text columns were trimmed to remove unnecessary surrounding spaces. Empty text values were converted to NULL where required.

```sql
SELECT * REPLACE (
    TRIM("Name") AS "Name",
    TRIM("ProductNumber") AS "ProductNumber",
    NULLIF(TRIM("Color"), '') AS "Color"
)
FROM ADVENTUREWORKS_DB.RAW.PRODUCT;
```

## 4. Data Quality and Validation

Validation checks were performed to ensure that the cleaned datasets were suitable for analytical processing.

The checks included:

| Validation | Purpose |
|---|---|
| Row count checks | Verify dataset completeness. |
| Primary key uniqueness | Identify duplicate identifiers. |
| NULL checks | Find missing values in important columns. |
| Numeric validation | Identify invalid numerical values. |
| Date validation | Check date consistency. |
| Referential integrity | Verify relationships between related datasets. |
| Business rule checks | Identify inconsistent business values. |

### Example: Primary Key and NULL Validation

```sql
SELECT
    COUNT(*) AS TOTAL_ROWS,
    COUNT(DISTINCT "SalesOrderID") AS UNIQUE_ORDER_IDS,
    COUNT_IF("SalesOrderID" IS NULL) AS NULL_ORDER_IDS
FROM ADVENTUREWORKS_DB.RAW.SALESORDERHEADER;
```

### Example: Referential Integrity

```sql
SELECT COUNT(*) AS ORPHAN_ORDER_IDS
FROM ADVENTUREWORKS_DB.RAW.SALESORDERDETAIL D
LEFT JOIN ADVENTUREWORKS_DB.RAW.SALESORDERHEADER H
    ON D."SalesOrderID" = H."SalesOrderID"
WHERE H."SalesOrderID" IS NULL;
```

These checks helped identify data quality issues before analytical table creation.

## 5. ANALYTICS Layer

After cleaning and validation, the processed datasets were used to build the final Gold layer in the ANALYTICS schema.

The analytical model consists of six tables.

| Table | Type | Purpose |
|---|---|---|
| DIM_CUSTOMER | Dimension | Customer attributes |
| DIM_DATE | Dimension | Date-related attributes |
| DIM_PRODUCT | Dimension | Product attributes |
| DIM_TERRITORY | Dimension | Sales territory attributes |
| FACT_PURCHASES | Fact | Purchasing transactions |
| FACT_SALES | Fact | Sales transactions |

### Dimension Tables

The dimension tables provide descriptive information that supports filtering, grouping, and analysis.

They include customer, date, product, and territory information.

### Fact Tables

The fact tables contain transactional information used for measuring business performance.

- `FACT_SALES` supports sales-related analysis.
- `FACT_PURCHASES` supports purchasing-related analysis.

Together, these tables form the analytical model used by Power BI.

## 6. Final Data Flow

```text
35 Source CSV Datasets
          |
          v
      RAW Schema
          |
          v
 Data Cleaning and
   Standardization
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
     S3 Curated
          |
          v
       Athena
          |
          v
      Power BI
```

## 7. Transformation Summary

The transformation process converted the original AdventureWorks source datasets into a structured analytical model.

The main stages were:

1. Ingested all 35 CSV datasets into the RAW schema.
2. Cleaned and standardized the datasets in the CLEAN schema.
3. Performed data quality and validation checks.
4. Created four dimension tables and two fact tables in the ANALYTICS schema.
5. Exported the six Gold tables to the curated S3 layer.
6. Made the curated datasets available through Athena for Power BI reporting.

All major data cleaning, transformation, and analytical modeling operations were performed in Snowflake.
