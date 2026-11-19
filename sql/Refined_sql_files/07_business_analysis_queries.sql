-- AdventureWorks: business analysis queries against the Gold layer
-- These queries are analytical examples and do not create or modify tables.

--Some Business Queries 

-- Q1 Business question: What is the total revenue generated each month, along with the number of orders and quantity sold?


-- QUERY 1: MONTHLY SALES PERFORMANCE

SELECT
    YEAR("OrderDate") AS SALES_YEAR,
    MONTH("OrderDate") AS SALES_MONTH,

    ROUND(SUM("LineTotal"), 2) AS TOTAL_REVENUE,

    COUNT(DISTINCT "SalesOrderID") AS TOTAL_ORDERS,

    SUM("OrderQty") AS TOTAL_QUANTITY_SOLD,

    ROUND(AVG("LineTotal"), 2) AS AVG_ORDER_LINE_VALUE

FROM ADVENTUREWORKS_DB.ANALYTICS.FACT_SALES

GROUP BY
    YEAR("OrderDate"),
    MONTH("OrderDate")

ORDER BY
    SALES_YEAR,
    SALES_MONTH;




-- Q2-Business question: Calculate monthly revenue and its percentage growth compared with the previous month.


-- QUERY 2: MONTH-OVER-MONTH REVENUE GROWTH

WITH MONTHLY_SALES AS (
    SELECT
        YEAR("OrderDate") AS SALES_YEAR,
        MONTH("OrderDate") AS SALES_MONTH,

        SUM("LineTotal") AS CURRENT_MONTH_REVENUE

    FROM ADVENTUREWORKS_DB.ANALYTICS.FACT_SALES

    GROUP BY
        YEAR("OrderDate"),
        MONTH("OrderDate")
),

PREVIOUS_MONTH AS (
    SELECT
        SALES_YEAR,
        SALES_MONTH,
        CURRENT_MONTH_REVENUE,

        LAG(CURRENT_MONTH_REVENUE) OVER (
            ORDER BY SALES_YEAR, SALES_MONTH
        ) AS PREVIOUS_MONTH_REVENUE

    FROM MONTHLY_SALES
)

SELECT
    SALES_YEAR,
    SALES_MONTH,

    ROUND(CURRENT_MONTH_REVENUE, 2) AS CURRENT_MONTH_REVENUE,

    ROUND(PREVIOUS_MONTH_REVENUE, 2) AS PREVIOUS_MONTH_REVENUE,

    ROUND(
        (
            CURRENT_MONTH_REVENUE - PREVIOUS_MONTH_REVENUE
        ) * 100.0 / NULLIF(PREVIOUS_MONTH_REVENUE, 0),
        2
    ) AS MOM_GROWTH_PERCENTAGE

FROM PREVIOUS_MONTH

ORDER BY SALES_YEAR, SALES_MONTH;







-- Q3 - Business question: Identify the top 5 products generating the highest revenue.

-- QUERY 3: TOP 5 PRODUCTS BY REVENUE

WITH CTE1 AS (
    SELECT
        dp."ProductID",
        dp."ProductName",
        dp."CategoryName",

        SUM(fs."OrderQty") AS TOTAL_UNITS_SOLD,
        SUM(fs."LineTotal") AS TOTAL_REVENUE

    FROM ADVENTUREWORKS_DB.ANALYTICS.DIM_PRODUCT dp

    INNER JOIN ADVENTUREWORKS_DB.ANALYTICS.FACT_SALES fs
        ON dp."ProductID" = fs."ProductID"

    GROUP BY
        dp."ProductID",
        dp."ProductName",
        dp."CategoryName"
)

SELECT
    *,
    DENSE_RANK() OVER (
        ORDER BY TOTAL_REVENUE DESC
    ) AS REVENUE_RANK

FROM CTE1

ORDER BY REVENUE_RANK
LIMIT 5;






-- Q4-Business question: How much revenue does each product category generate, and what percentage does it contribute to overall revenue?


WITH CATEGORY_SALES AS (
    SELECT
        dp."CategoryName",

        SUM(fs."OrderQty") AS TOTAL_UNITS_SOLD,
        SUM(fs."LineTotal") AS TOTAL_REVENUE

    FROM ADVENTUREWORKS_DB.ANALYTICS.FACT_SALES fs

    INNER JOIN ADVENTUREWORKS_DB.ANALYTICS.DIM_PRODUCT dp
        ON fs."ProductID" = dp."ProductID"

    GROUP BY dp."CategoryName"
)

SELECT
    "CategoryName",
    TOTAL_UNITS_SOLD,
    ROUND(TOTAL_REVENUE, 2) AS TOTAL_REVENUE,

    ROUND(
        TOTAL_REVENUE * 100.0 /
        NULLIF(SUM(TOTAL_REVENUE) OVER(), 0),
        2
    ) AS REVENUE_CONTRIBUTION_PCT,

    DENSE_RANK() OVER (
        ORDER BY TOTAL_REVENUE DESC
    ) AS REVENUE_RANK

FROM CATEGORY_SALES
ORDER BY REVENUE_RANK;







-- Q5-Business question: Identify the 10 customers who have generated the highest revenue.



WITH CUSTOMER_SALES AS (
    SELECT
        dc."CustomerID",
        dc."CustomerName",
        dc."StoreName",
        dc."CustomerType",

        COUNT(DISTINCT fs."SalesOrderID") AS TOTAL_ORDERS,
        SUM(fs."OrderQty") AS TOTAL_QUANTITY,
        ROUND(SUM(fs."LineTotal"), 2) AS TOTAL_SPENDING

    FROM ADVENTUREWORKS_DB.ANALYTICS.FACT_SALES fs

    INNER JOIN ADVENTUREWORKS_DB.ANALYTICS.DIM_CUSTOMER dc
        ON fs."CustomerID" = dc."CustomerID"

    GROUP BY
        dc."CustomerID",
        dc."CustomerName",
        dc."StoreName",
        dc."CustomerType"
),

RANKED_CUSTOMERS AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            ORDER BY TOTAL_SPENDING DESC
        ) AS CUSTOMER_RANK
    FROM CUSTOMER_SALES
)

SELECT *
FROM RANKED_CUSTOMERS
WHERE CUSTOMER_RANK <= 10
ORDER BY CUSTOMER_RANK;







-- Q6-Business question: Classify customers into spending categories based on their total revenue.


WITH CUSTOMER_SPENDING AS (
    SELECT
        dc."CustomerID",
        dc."CustomerName",
        dc."StoreName",
        dc."CustomerType",

        COUNT(DISTINCT fs."SalesOrderID") AS TOTAL_ORDERS,
        ROUND(SUM(fs."LineTotal"), 2) AS TOTAL_SPENDING

    FROM ADVENTUREWORKS_DB.ANALYTICS.FACT_SALES fs

    INNER JOIN ADVENTUREWORKS_DB.ANALYTICS.DIM_CUSTOMER dc
        ON fs."CustomerID" = dc."CustomerID"

    GROUP BY
        dc."CustomerID",
        dc."CustomerName",
        dc."StoreName",
        dc."CustomerType"
),

SEGMENTED_CUSTOMERS AS (
    SELECT
        *,
        CASE
            WHEN TOTAL_SPENDING > 10000 THEN 'High Value'
            WHEN TOTAL_SPENDING >= 5000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS CUSTOMER_SEGMENT

    FROM CUSTOMER_SPENDING
)

SELECT
    CUSTOMER_SEGMENT,
    COUNT(*) AS TOTAL_CUSTOMERS,
    ROUND(AVG(TOTAL_SPENDING), 2) AS AVG_CUSTOMER_SPENDING,
    ROUND(SUM(TOTAL_SPENDING), 2) AS SEGMENT_REVENUE

FROM SEGMENTED_CUSTOMERS

GROUP BY CUSTOMER_SEGMENT

ORDER BY SEGMENT_REVENUE DESC;






-- Q7-Business question: Calculate the average revenue generated per sales order, along with the total number of orders and total revenue.



WITH ORDER_LEVEL AS (
    SELECT
        "SalesOrderID",
        SUM("LineTotal") AS ORDER_REVENUE

    FROM ADVENTUREWORKS_DB.ANALYTICS.FACT_SALES

    GROUP BY "SalesOrderID"
)

SELECT
    COUNT(*) AS TOTAL_ORDERS,
    ROUND(SUM(ORDER_REVENUE), 2) AS TOTAL_REVENUE,
    ROUND(AVG(ORDER_REVENUE), 2) AS AVERAGE_ORDER_VALUE

FROM ORDER_LEVEL;
