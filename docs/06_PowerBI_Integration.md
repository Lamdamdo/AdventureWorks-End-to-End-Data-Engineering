# Power BI Integration

## 1. Overview

Power BI was used as the final reporting and visualization layer of the AdventureWorks end-to-end data engineering project.

The curated Gold datasets were queried through Amazon Athena and imported into Power BI to build interactive business dashboards.

## 2. Data Source

The Power BI reports use the six Gold datasets exported from Snowflake to the curated S3 layer.

The datasets are:

| Dataset | Purpose |
|---|---|
| DIM_CUSTOMER | Customer information |
| DIM_DATE | Date dimension |
| DIM_PRODUCT | Product information |
| DIM_TERRITORY | Territory information |
| FACT_PURCHASES | Purchasing transactions |
| FACT_SALES | Sales transactions |

## 3. Amazon Athena Connection

An Athena database named `adventureworks_gold` was created to organize the six curated datasets.

The six external tables were created manually using `CREATE EXTERNAL TABLE`. Each table points to its corresponding folder in the S3 curated prefix.

Athena uses the AWS Glue Data Catalog to maintain database and table metadata.

The Athena ODBC driver was installed and configured to establish connectivity between Power BI and Amazon Athena.

## 4. IAM Configuration

A dedicated IAM user named `PowerBI_Athena_User` was configured for Power BI and Athena connectivity.

The associated IAM policy provided the required permissions for:

- Athena query execution and query results.
- Glue Data Catalog metadata access.
- Reading curated data from the project S3 bucket.
- Listing the project S3 bucket.
- Accessing the Athena query results location.

The IAM credentials were configured in the ODBC connection.

Sensitive credentials and access key information are excluded from this repository.

## 5. Power BI Connection

Power BI was connected to Amazon Athena using the configured ODBC data source.

The `adventureworks_gold` database was selected, and the six Gold tables were imported into Power BI.

The imported datasets were then used to build the Power BI data model and dashboards.

## 6. Import Mode

Power BI was configured to use **Import mode** instead of DirectQuery.

This approach was selected because:

- Data is loaded into the Power BI model.
- Dashboard interactions use the imported data rather than sending a new Athena query for every interaction.
- It reduces repeated query execution against Athena during dashboard usage.
- It provides a responsive reporting experience.

The imported datasets serve as the basis for the reporting layer.

## 7. Dashboard Development

Three Power BI dashboards were developed using the imported Gold datasets.

The dashboards provide business insights based on the analytical model created in Snowflake.

The Power BI report file and dashboard screenshots are included in the `powerbi/` directory of this repository.

## 8. End-to-End Reporting Flow

```text
Snowflake Gold Tables
          |
          v
    S3 Curated Layer
          |
          v
     Amazon Athena
          |
          v
    Athena ODBC Driver
          |
          v
   Power BI Import Mode
          |
          v
   Data Model and Dashboards
```

## 9. Key Implementation Decisions

- **Athena external tables:** Used to query the curated datasets directly from S3.
- **IAM-based access:** Configured a dedicated IAM user for Athena query execution and curated S3 access.
- **ODBC connectivity:** Used the Athena ODBC driver to connect Power BI.
- **Import mode:** Selected to avoid repeated Athena query execution during dashboard interactions.
- **Gold-layer reporting:** Used the six curated analytical datasets instead of querying raw source files.

## 10. Outcome

Power BI successfully connected to Amazon Athena and imported the six curated Gold datasets.

These datasets were used to develop three interactive dashboards, completing the reporting layer of the AdventureWorks end-to-end data engineering pipeline.
