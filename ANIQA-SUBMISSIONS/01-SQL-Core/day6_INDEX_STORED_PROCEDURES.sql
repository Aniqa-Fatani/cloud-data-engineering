-- =========================================================
-- Course: Cloud Data Engineering
-- Module: Section 1 - SQL Indexes + Stored Procedures
-- Assignment: Day 6 Homework Solution
-- Author: Aniqa Fatani
-- Date: 6 JUNE 2026
-- =========================================================
-- ============================================================
--  PART A: INDEXES
-- ============================================================

-- Q1.
-- Write a query to create a non-clustered index on the
-- last_name column of sales.customers.
-- Then write a SELECT statement that would benefit from it.
-- Hint: Think about which queries filter by last name.

-- Your answer here:
-- Create the non-clustered index
CREATE NONCLUSTERED INDEX IX_Customers_LastName 
ON sales.customers (last_name);

-- SELECT statement that benefits from this index
SELECT customer_id, first_name, last_name, email
FROM sales.customers
WHERE last_name = 'saims';


-- Q2.
-- Create a composite index on sales.orders using
-- customer_id and order_date.
-- Write a query that filters on both columns and benefits
-- from this index.
-- Hint: Composite indexes work best when you filter on both columns.

-- Your answer here:
-- Create the composite index
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID_OrderDate 
ON sales.orders (customer_id, order_date);

-- SELECT statement filtering on both columns
SELECT order_id, customer_id, order_date, order_status
FROM sales.orders
WHERE customer_id = 105 
  AND order_date >= '2026-01-01';


-- Q3.
-- A teammate suggests adding a unique index on
-- sales.customers(phone_number).
-- What could go wrong with this?
-- What assumption must be true for this to be safe?
-- Hint: Think about duplicate or missing (NULL) values.

-- Your answer here (write as a comment):
/*
What could go wrong:
1. If multiple customers do not provide a phone number, SQL Server will throw a duplicate key error 
   on the second NULL value, because standard unique indexes only allow a single NULL value.
2. If multiple family members share the same landing line or phone number, the system will reject 
   the entry of the second family member.

Assumption that must be true to be safe:
Every single customer must have a completely unique, active phone number, and missing/NULL values 
must not be allowed (or a filtered unique index must be used to exclude NULLs).
*/


-- Q4.
-- Look at the columns below from a sales.orders table.
-- Decide which columns SHOULD have an index and which should NOT.
-- Explain your reasoning for each as a comment.
--
--   order_id     (Primary Key)
--   status       (only 3 values: Pending, Shipped, Delivered)
--   customer_id  (Foreign Key)
--   notes        (free text, rarely searched)

-- Your answer here (write as a comment):
/*
1. order_id (Primary Key): 
   SHOULD NOT manually index. SQL Server automatically creates a clustered index on the Primary Key.

2. status (Only 3 values: Pending, Shipped, Delivered): 
   SHOULD NOT index. This column has very low cardinality (low selectivity). The query optimizer 
   will usually prefer a full table scan over using an index for just 3 repeating values.

3. customer_id (Foreign Key): 
   SHOULD index. Foreign keys are heavily used in JOIN operations and filtering order histories, 
   making them excellent candidates for non-clustered indexes.

4. notes (free text, rarely searched): 
   SHOULD NOT index. Large text columns consume massive amounts of disk space in an index, 
   and standard indexes do not speed up complex text searches anyway (Full-Text Search would be needed instead).
*/


-- Q5.
-- Write the command to check existing indexes on production.products.
-- Then describe (as a comment) what the output columns tell you.
-- Hint: Use sp_helpindex.

-- Your answer here:
-- Command to check existing indexes
EXEC sp_helpindex 'production.products';

/*
What the output columns tell you:
1. index_name: The descriptive identifier assigned to the index (e.g., PK__Products__...).
2. index_description: Tells you the structural type of index (Clustered vs. Non-clustered), 
   whether it enforces uniqueness, and which filegroup it is physically stored on.
3. index_keys: The specific column or combination of columns that the index is built upon 
   and sorts by.
*/


-- ============================================================
--  PART B: STORED PROCEDURES
-- ============================================================

-- Q6.
-- Create a stored procedure called sp_GetCustomerOrders
-- that accepts a @CustomerID parameter and returns all orders
-- for that customer showing: order_id, order_date, order_status.
-- Test it using EXEC after you create it.

-- Your answer here:
-- Create the stored procedure
CREATE PROCEDURE sp_GetCustomerOrders
    @CustomerID INT
AS
BEGIN
    SELECT order_id, order_date, order_status
    FROM sales.orders
    WHERE customer_id = @CustomerID;
END;
GO

-- Test the procedure
EXEC sp_GetCustomerOrders @CustomerID = 1;


-- Q7.
-- Modify sp_GetCustomerOrders from Q6 so that if no orders
-- are found for the given customer, it returns the message:
-- 'No orders found for this customer'
-- Hint: Use IF EXISTS or check @@ROWCOUNT.

-- Your answer here:
-- Modify the stored procedure using ALTER
ALTER PROCEDURE sp_GetCustomerOrders
    @CustomerID INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM sales.orders WHERE customer_id = @CustomerID)
    BEGIN
        SELECT order_id, order_date, order_status
        FROM sales.orders
        WHERE customer_id = @CustomerID;
    END
    ELSE
    BEGIN
        PRINT 'No orders found for this customer';
    END
END;
GO


-- Q8.
-- Create a stored procedure sp_ProductsByCategory that accepts:
--   @CategoryID  INT
--   @MaxPrice    DECIMAL(10,2)  with a default value of 9999
-- It should return all matching products ordered by price (low to high).
-- Hint: Use a default parameter value like you saw with @threshold.

-- Your answer here:
CREATE PROCEDURE sp_ProductsByCategory
    @CategoryID INT,
    @MaxPrice DECIMAL(10,2) = 9999
AS
BEGIN
    SELECT product_id, product_name, category_id, list_price
    FROM production.products
    WHERE category_id = @CategoryID
      AND list_price <= @MaxPrice
    ORDER BY list_price ASC;
END;
GO


-- ============================================================
--  PART C: MIXED / THINK QUESTIONS
-- ============================================================

-- Q9.
-- You have a sales.orders table with 2 million rows.
-- A stored procedure filters by store_id and order_date.
-- It runs very slowly.
-- What TWO things would you do to fix it, and why?
-- Hint: Think about both indexes and procedure logic.

-- Your answer here (write as a comment):
/*
1. Create a Composite Non-Clustered Index:
   I would build a composite index on (store_id, order_date) or (order_date, store_id). This allows 
   the query optimizer to perform an efficient index seek directly to the matching rows instead of scanning 
   all 2 million rows.

2. Check for Parameter Sniffing or implement WITH RECOMPILE:
   If the index already exists but execution is still sluggish, the database engine might be caching 
   a bad execution plan based on the first parameter used. Adding "WITH RECOMPILE" to the procedure 
   ensures it recalculates the best plan dynamically for large analytical variations.
*/


-- Q10.
-- A junior developer creates indexes on EVERY column of a table
-- to "make everything faster".
-- Write a short explanation (3-5 sentences) of why this is
-- actually a bad idea.
-- Hint: Think about how INSERT, UPDATE, and DELETE are affected.

-- Your answer here (write as a comment):
/*
Indexing every single column is highly counterproductive for two main reasons:
1. It drastically slows down write performance (INSERT, UPDATE, and DELETE operations). Every time 
   a row is added, modified, or removed, SQL Server is forced to update every single index on that table 
   simultaneously, leading to severe disk write bottlenecks.
2. It wastes enormous amounts of system memory and storage space. These excess indexes bloat the database, 
   clog up the data cache with unnecessary index pages, and can confuse the query optimizer into choosing 
   inefficient execution routes.
*/


-- ============================================================
--  END OF HOMEWORK
-- ============================================================