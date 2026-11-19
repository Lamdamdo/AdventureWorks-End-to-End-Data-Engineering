# AWS S3 Setup and Configuration

## 1. Overview

Amazon S3 is used as the central cloud storage layer for the AdventureWorks data engineering project.

It stores the original source CSV files and the curated analytical datasets exported from Snowflake. Amazon Athena also uses S3 to query the curated datasets.

**AWS Region:** `ap-south-1`

**S3 Bucket:** `adventureworks-snowflake-2026`

## 2. S3 Bucket Structure

A dedicated S3 bucket was created for the project:

`adventureworks-snowflake-2026`

The bucket contains three main prefixes:

```text
adventureworks-snowflake-2026/
|
|-- raw/
|   |-- HumanResources/
|   |-- Person/
|   |-- Production/
|   |-- Purchasing/
|   |-- Sales/
|
|-- curated/
|   |-- DIM_CUSTOMER/
|   |-- DIM_DATE/
|   |-- DIM_PRODUCT/
|   |-- DIM_TERRITORY/
|   |-- FACT_PURCHASES/
|   |-- FACT_SALES/
|
|-- athena-results/
