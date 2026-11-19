-- AdventureWorks: raw-file discovery, ingestion-generation experiments,
-- and initial RAW-layer validation queries.
-- This file contains the discovery/generation block retained from the setup script.
-- It is not required if the generated 33-table script above has already been run.

LIST @ADVENTUREWORKS_DB.PUBLIC.ADVENTUREWORKS_S3_STAGE;

SET LIST_QID = LAST_QUERY_ID();

DECLARE
    V_FILE STRING;
    V_FOLDER STRING;
    V_FILENAME STRING;
    V_TABLE STRING;
    V_SQL STRING;

BEGIN
    FOR REC IN (
        SELECT "name" AS FILE_NAME
        FROM TABLE(RESULT_SCAN($LIST_QID))
        WHERE "name" ILIKE '%.csv'
    )
    DO
        V_FILE := REC['FILE_NAME']::STRING;

        V_FOLDER := SPLIT_PART(V_FILE, '/', -2);
        V_FILENAME := SPLIT_PART(V_FILE, '/', -1);

        V_TABLE := SPLIT_PART(V_FILENAME, '.', 3);

        IF (UPPER(V_TABLE) NOT IN
            ('SALESORDERHEADER', 'SALESORDERDETAIL')) THEN

            V_SQL :=
                'CREATE TABLE IF NOT EXISTS ADVENTUREWORKS_DB.RAW.' ||
                V_TABLE ||
                ' USING TEMPLATE (
                    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
                    FROM TABLE(
                        INFER_SCHEMA(
                            LOCATION => ''@ADVENTUREWORKS_DB.PUBLIC.ADVENTUREWORKS_S3_STAGE/' ||
                            V_FOLDER || '/' || V_FILENAME ||
                            ''',
                            FILE_FORMAT => ''ADVENTUREWORKS_DB.PUBLIC.AW_CSV_FORMAT''
                        )
                    )
                )';

            EXECUTE IMMEDIATE V_SQL;

            V_SQL :=
                'COPY INTO ADVENTUREWORKS_DB.RAW.' || V_TABLE ||
                ' FROM @ADVENTUREWORKS_DB.PUBLIC.ADVENTUREWORKS_S3_STAGE/' ||
                V_FOLDER ||
                ' FILES = (''' || V_FILENAME || ''')' ||
                ' FILE_FORMAT = (FORMAT_NAME = ''ADVENTUREWORKS_DB.PUBLIC.AW_CSV_FORMAT'')' ||
                ' MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE';

            EXECUTE IMMEDIATE V_SQL;

        END IF;
    END FOR;

    RETURN 'RAW table ingestion completed';
END;




SELECT *
FROM TABLE(
    INFER_SCHEMA(
        LOCATION => '@ADVENTUREWORKS_DB.PUBLIC.ADVENTUREWORKS_S3_STAGE/Production/adventureworks.Production.Product.csv',
        FILE_FORMAT => 'ADVENTUREWORKS_DB.PUBLIC.AW_CSV_FORMAT'
    )
);



SELECT "name"
FROM TABLE(RESULT_SCAN($LIST_QID))
WHERE "name" ILIKE '%.csv';



WITH FILES AS (
    SELECT
        SPLIT_PART("name", '/', -2) AS FOLDER_NAME,
        SPLIT_PART("name", '/', -1) AS FILE_NAME,
        SPLIT_PART(SPLIT_PART("name", '/', -1), '.', 3) AS TABLE_NAME
    FROM TABLE(RESULT_SCAN($LIST_QID))
    WHERE "name" ILIKE '%.csv'
),
REMAINING AS (
    SELECT *
    FROM FILES
    WHERE UPPER(TABLE_NAME) NOT IN (
        'SALESORDERHEADER',
        'SALESORDERDETAIL'
    )
),
COMMANDS AS (
    SELECT
        'CREATE TABLE IF NOT EXISTS ADVENTUREWORKS_DB.RAW.' || TABLE_NAME ||
        ' USING TEMPLATE (SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*)) FROM TABLE(INFER_SCHEMA(LOCATION => ' ||
        '''@ADVENTUREWORKS_DB.PUBLIC.ADVENTUREWORKS_S3_STAGE/' ||
        FOLDER_NAME || '/' || FILE_NAME ||
        ''', FILE_FORMAT => ''ADVENTUREWORKS_DB.PUBLIC.AW_CSV_FORMAT'')));' ||
        CHR(10) ||
        'COPY INTO ADVENTUREWORKS_DB.RAW.' || TABLE_NAME ||
        ' FROM @ADVENTUREWORKS_DB.PUBLIC.ADVENTUREWORKS_S3_STAGE/' ||
        FOLDER_NAME || '/' ||
        ' FILES = (''' || FILE_NAME || ''')' ||
        ' FILE_FORMAT = (FORMAT_NAME = ''ADVENTUREWORKS_DB.PUBLIC.AW_CSV_FORMAT'')' ||
        ' MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;' AS SQL_SCRIPT
    FROM REMAINING
)
SELECT LISTAGG(SQL_SCRIPT, '\n')
       WITHIN GROUP (ORDER BY SQL_SCRIPT) AS COMPLETE_SCRIPT
FROM COMMANDS;


CREATE TABLE ADVENTUREWORKS_DB.RAW.VENDOR
USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(
        INFER_SCHEMA(
            LOCATION => '@ADVENTUREWORKS_DB.PUBLIC.ADVENTUREWORKS_S3_STAGE/Purchasing/adventureworks.Purchasing.Vendor.csv',
            FILE_FORMAT => 'ADVENTUREWORKS_DB.PUBLIC.AW_CSV_FORMAT'
        )
    )
);

COPY INTO ADVENTUREWORKS_DB.RAW.VENDOR
FROM @ADVENTUREWORKS_DB.PUBLIC.ADVENTUREWORKS_S3_STAGE/Purchasing/
FILES = ('adventureworks.Purchasing.Vendor.csv')
FILE_FORMAT = (FORMAT_NAME = 'ADVENTUREWORKS_DB.PUBLIC.AW_CSV_FORMAT')
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
SELECT COUNT(*) 
FROM ADVENTUREWORKS_DB.RAW.VENDOR;


SELECT
    TABLE_NAME,
    ROW_COUNT
FROM ADVENTUREWORKS_DB.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'RAW'
ORDER BY TABLE_NAME;





DESCRIBE TABLE ADVENTUREWORKS_DB.RAW.SALESORDERHEADER;

SELECT *
FROM ADVENTUREWORKS_DB.RAW.SALESORDERHEADER
LIMIT 20;

SELECT
    COUNT(*) AS TOTAL_ROWS,
    COUNT(DISTINCT "SalesOrderID") AS UNIQUE_ORDER_IDS,
    COUNT_IF("SalesOrderID" IS NULL) AS NULL_ORDER_IDS,

    COUNT_IF(
        ABS("TotalDue" - ("SubTotal" + "TaxAmt" + "Freight")) > 0.01
    ) AS INVALID_TOTALS,

    COUNT_IF(
        "ShipDate" < "OrderDate"
        OR "DueDate" < "OrderDate"
    ) AS INVALID_DATES

FROM ADVENTUREWORKS_DB.RAW.SALESORDERHEADER;
