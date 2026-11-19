-- AdventureWorks: Snowflake environment and S3 access setup
-- Review placeholders and account-specific settings before execution.
-- Original source statements are retained; exploratory LIST/DESC statements remain
-- where useful for setup verification.

CREATE DATABASE IF NOT EXISTS ADVENTUREWORKS_DB;

USE DATABASE ADVENTUREWORKS_DB;

CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CLEAN;
CREATE SCHEMA IF NOT EXISTS ANALYTICS;


CREATE STORAGE INTEGRATION ADVENTUREWORKS_S3_INT
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = S3
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN =
        'arn:aws:iam::<AWS_ACCOUNT_ID>:role/AdventureWorksSnowflakeRole'
    STORAGE_ALLOWED_LOCATIONS = (
        's3://adventureworks-snowflake-2026/raw/',
        's3://adventureworks-snowflake-2026/curated/'
    );


DESC STORAGE INTEGRATION ADVENTUREWORKS_S3_INT;


USE DATABASE ADVENTUREWORKS_DB;
USE SCHEMA RAW;

CREATE STAGE ADVENTUREWORKS_S3_STAGE
    URL = 's3://adventureworks-snowflake-2026/raw/'
    STORAGE_INTEGRATION = ADVENTUREWORKS_S3_INT;


LIST @ADVENTUREWORKS_S3_STAGE;


CREATE OR REPLACE FILE FORMAT AW_CSV_FORMAT
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null')
    EMPTY_FIELD_AS_NULL = TRUE
    TRIM_SPACE = TRUE;

    CREATE OR REPLACE FILE FORMAT AW_CSV_FORMAT
    TYPE = CSV
    PARSE_HEADER = TRUE
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null')
    EMPTY_FIELD_AS_NULL = TRUE
    TRIM_SPACE = TRUE;

SELECT *
FROM TABLE(
    INFER_SCHEMA(
        LOCATION => '@ADVENTUREWORKS_S3_STAGE/Sales/adventureworks.Sales.SalesOrderHeader.csv',
        FILE_FORMAT => 'AW_CSV_FORMAT'
    )
);
