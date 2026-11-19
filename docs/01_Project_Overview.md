# AdventureWorks – End-to-End Data Engineering Project

## Project Objective

Built an end-to-end cloud data engineering pipeline using the AdventureWorks dataset, integrating AWS S3, Snowflake, Amazon Athena and Power BI.

The project transforms raw operational CSV files into structured analytical datasets and makes them available for business intelligence reporting.

## Dataset

Source: https://adventureworks.demodb.dev/

- 35 CSV files downloaded locally.
- Five business domains:
  - HumanResources
  - Person
  - Production
  - Purchasing
  - Sales

## Technology Stack

| Technology | Purpose |
|---|---|
| AdventureWorks | Source dataset |
| AWS S3 | Raw and curated storage |
| AWS IAM | Access management |
| Snowflake | Data warehouse and transformations |
| Snowflake SQL | Ingestion, cleaning and modelling |
| Amazon Athena | Querying curated S3 data |
| AWS Glue Data Catalog | Athena metadata catalog |
| Athena ODBC | Power BI connectivity |
| Power BI | Business intelligence dashboards |

## Project Workflow

1. Downloaded 35 CSV files from AdventureWorks to the local machine.
2. Uploaded the source files to the RAW layer in Amazon S3.
3. Configured AWS IAM roles, permissions and Snowflake storage integration.
4. Connected Snowflake to S3 using an external stage and CSV file formats.
5. Ingested all 35 source files into Snowflake.
6. Cleaned and transformed the data into the CLEAN schema.
7. Created six analytical Gold tables in the ANALYTICS schema.
8. Exported the Gold tables back to S3 under the CURATED prefix.
9. Created an Athena database and six external tables over the curated datasets.
10. Configured Athena ODBC connectivity.
11. Imported the analytical datasets into Power BI.
12. Developed three dashboards.

## Snowflake Data Model

Database: `ADVENTUREWORKS_DB`

| Schema | Purpose |
|---|---|
| RAW | Source data |
| CLEAN | Cleaned and transformed data |
| ANALYTICS | Final analytical datasets |

Six Gold tables:

- DIM_CUSTOMER
- DIM_DATE
- DIM_PRODUCT
- DIM_TERRITORY
- FACT_SALES
- FACT_PURCHASES

## Power BI Dashboards

1. Executive Overview
2. Sales Performance
3. Purchasing Analysis

Power BI uses Import mode through the Athena ODBC connector.

## Key Engineering Concepts

- Cloud storage integration
- IAM role-based authentication
- Automated multi-file ingestion
- Data cleaning and validation
- Medallion-style layered processing
- Dimensional modelling
- Fact and dimension tables
- External tables
- SQL-based analytics
- ODBC connectivity

## Project Outcome

Successfully implemented an end-to-end data pipeline connecting AWS S3, Snowflake, Athena and Power BI, transforming 35 raw CSV files into six analytical datasets and three business intelligence dashboards.
