USE db;

-- ==========================================
-- 1. CREATE THE TABLES (With Safe Data Types)
-- ==========================================

CREATE TABLE IF NOT EXISTS customers (
    `Customer ID` VARCHAR(255),
    `Customer Name` VARCHAR(255),
    `Segment` VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS products (
    `Product ID` VARCHAR(255),
    `Category` VARCHAR(255),
    `Sub-Category` VARCHAR(255),
    `Product Name` TEXT
);

CREATE TABLE IF NOT EXISTS orders (
    `Row ID` INT,
    `Order ID` VARCHAR(255),
    `Order Date` VARCHAR(255),
    `Ship Date` VARCHAR(255),
    `Ship Mode` VARCHAR(255),
    `Customer ID` VARCHAR(255),
    `Product ID` VARCHAR(255),
    `Sales` DOUBLE,
    `Quantity` INT,
    `Discount` DOUBLE,
    `Profit` DOUBLE
);

-- ==========================================
-- 2. INSERT DATA FROM SUPERSTORE
-- ==========================================

-- (Optional) Clear the tables just in case you run this script more than once
TRUNCATE TABLE customers;
TRUNCATE TABLE products;
TRUNCATE TABLE orders;

-- Insert unique customers
INSERT INTO customers (`Customer ID`, `Customer Name`, `Segment`)
SELECT DISTINCT `Customer ID`, `Customer Name`, `Segment`
FROM superstore
WHERE `Customer ID` IS NOT NULL;

-- Insert unique products
INSERT INTO products (`Product ID`, `Category`, `Sub-Category`, `Product Name`)
SELECT DISTINCT `Product ID`, `Category`, `Sub-Category`, `Product Name`
FROM superstore
WHERE `Product ID` IS NOT NULL;

-- Insert all orders
INSERT INTO orders (
    `Row ID`, `Order ID`, `Order Date`, `Ship Date`, `Ship Mode`, 
    `Customer ID`, `Product ID`, `Sales`, `Quantity`, `Discount`, `Profit`
)
SELECT 
    `Row ID`, `Order ID`, `Order Date`, `Ship Date`, `Ship Mode`, 
    `Customer ID`, `Product ID`, `Sales`, `Quantity`, `Discount`, `Profit`
FROM superstore;

SELECT c.`Customer Name`, COUNT(DISTINCT o.`Order ID`) as Total_Unique_Orders
FROM orders o
JOIN customers c ON o.`Customer ID` = c.`Customer ID`
GROUP BY c.`Customer Name`, o.`Customer ID`
HAVING COUNT(DISTINCT o.`Order ID`) = 1
ORDER BY c.`Customer Name` ASC;-- Point to your specific database
USE db;

-- ====================================================================
-- OBJECTIVE 1: SUBQUERIES (Filtering Data)
-- ====================================================================

-- 1A. Find Order Lines with Above-Average Sales
-- This compares every individual sale to the overall average sale amount.
SELECT `Order ID`, `Sales`
FROM orders
WHERE `Sales` > (
    SELECT AVG(`Sales`) FROM orders
)
ORDER BY `Sales` DESC;

-- 1B. Find the Highest Single Order Line per Customer
-- This shows the maximum amount each customer has spent in a single transaction.
SELECT c.`Customer Name`, MAX(o.`Sales`) as Highest_Purchase
FROM orders o
JOIN customers c ON o.`Customer ID` = c.`Customer ID`
GROUP BY c.`Customer Name`, o.`Customer ID`
ORDER BY Highest_Purchase DESC;


-- ====================================================================
-- OBJECTIVE 2: CTEs + WINDOW FUNCTIONS + JOINS (Advanced Analysis)
-- ====================================================================

-- Calculate Total Sales per Customer and generate a ranking
WITH CustomerSales AS (
    -- Step 1: CTE to aggregate total sales per customer
    SELECT `Customer ID`, SUM(`Sales`) as TotalSales
    FROM orders
    GROUP BY `Customer ID`
),
RankedCustomers AS (
    -- Step 2: Window functions to apply Rank and Row Number
    SELECT 
        c.`Customer Name`, 
        cs.TotalSales, 
        RANK() OVER(ORDER BY cs.TotalSales DESC) as SalesRank,
        ROW_NUMBER() OVER(ORDER BY cs.TotalSales DESC) as SalesRowNumber
    FROM CustomerSales cs
    JOIN customers c ON cs.`Customer ID` = c.`Customer ID`
)
-- Step 3: Retrieve the full ranked list
SELECT * FROM RankedCustomers;


-- ====================================================================
-- OBJECTIVE 3: SOLVING SPECIFIC BUSINESS QUERIES
-- ====================================================================

-- 3A. Top 5 Best Customers (Highest Total Sales)
WITH CustomerSales AS (
    SELECT `Customer ID`, SUM(`Sales`) as TotalSales
    FROM orders
    GROUP BY `Customer ID`
),
RankedCustomers AS (
    SELECT c.`Customer Name`, cs.TotalSales, RANK() OVER(ORDER BY cs.TotalSales DESC) as SalesRank
    FROM CustomerSales cs
    JOIN customers c ON cs.`Customer ID` = c.`Customer ID`
)
SELECT * FROM RankedCustomers 
WHERE SalesRank <= 5;


-- 3B. Lowest 5 Customers (Lowest Total Sales)
WITH CustomerSales AS (
    SELECT `Customer ID`, SUM(`Sales`) as TotalSales
    FROM orders
    GROUP BY `Customer ID`
)
SELECT c.`Customer Name`, cs.TotalSales
FROM CustomerSales cs
JOIN customers c ON cs.`Customer ID` = c.`Customer ID`
ORDER BY cs.TotalSales ASC 
LIMIT 5;


-- 3C. Single-Order Customers (Customers who only purchased once)
-- Useful for identifying customers who need a re-engagement marketing email.
SELECT c.`Customer Name`, COUNT(DISTINCT o.`Order ID`) as Total_Unique_Orders
FROM orders o
JOIN customers c ON o.`Customer ID` = c.`Customer ID`
GROUP BY c.`Customer Name`, o.`Customer ID`
HAVING COUNT(DISTINCT o.`Order ID`) = 1
ORDER BY c.`Customer Name` ASC;
