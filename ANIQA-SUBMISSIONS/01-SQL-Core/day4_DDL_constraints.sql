-- =========================================================
-- Course: Cloud Data Engineering
-- Module: Section 1 - SQL MODIFYING DATA, DDL, DATA TYPES & CONSTRAINTS
-- Assignment: Day 4 Homework Solution
-- Author: Aniqa Fatani
-- Date: 30 May 2026
-- =========================================================
-- ================================================================================
-- SECTION A: DATA TYPES & CONSTRAINTS (Conceptual Questions)
-- ================================================================================

-- Q1: What data type would you use for a product's weight (e.g., 2.5 kg)?
DECIMAL(5,2) or DECIMAL(4,1) is ideal. It allows precise fractional values without the rounding issues of floating-point numbers.


-- Q2: In the sales.stores table, the zip_code is VARCHAR(5). Why not use INT?
Postal codes can contain leading zeros (e.g., 02138), which an INT data type would strip away. Additionally, zip codes are not used for mathematical calculations.

-- Q3: Look at sales.orders.order_status. The comment says 1=Pending,2=Processing,3=Rejected,4=Completed.
--     Is TINYINT a good choice? Why not use INT?
Yes, TINYINT is a great choice. It only uses 1 byte of storage (supporting values from 0 to 255), whereas an INT uses 4 bytes. Since the status values are tiny and finite, using TINYINT saves significant database storage.

--yes, tinyint is a good choice


-- Q4: If you add a CHECK constraint that rating must be BETWEEN 1 AND 5, what happens if you try to INSERT rating = 0?
The database engine will throw a constraint violation error and completely block/abort the INSERT statement.

-- Q5: Why does sales.staffs have UNIQUE constraint on email but not on phone?
Multiple staff members might share a store landline or a corporate phone number, but every employee must have a unique individual email address for logging in and receiving communications.


-- ================================================================================
-- SECTION B: DDL (CREATE, ALTER, DROP)
-- ================================================================================

-- Q6: Create a new table called sales.loyalty_programs with the following columns:
--     - program_id (INT, auto-increment starting 1, PRIMARY KEY)
--     - program_name (VARCHAR(100), NOT NULL, UNIQUE)
--     - discount_rate (DECIMAL(3,2), NOT NULL, DEFAULT 0.05, CHECK between 0.00 and 0.50)
--     - start_date (DATE, NOT NULL, DEFAULT GETDATE())
--     - end_date (DATE, NULL)
CREATE TABLE sales.loyalty_programs (
    program_id INT IDENTITY(1,1) PRIMARY KEY,
    program_name VARCHAR(100) NOT NULL UNIQUE,
    discount_rate DECIMAL(3,2) NOT NULL DEFAULT 0.05 CHECK (discount_rate BETWEEN 0.00 AND 0.50),
    start_date DATE NOT NULL DEFAULT GETDATE(),
    end_date DATE NULL
);


-- Q7: Add a new column 'loyalty_program_id' (INT, NULL) to the sales.customers table.
ALTER TABLE sales.customers
ADD loyalty_program_id INT NULL;
   


-- Q8: Add a FOREIGN KEY constraint to sales.customers.loyalty_program_id that references 
--     sales.loyalty_programs.program_id.
        ALTER TABLE sales.customers
ADD CONSTRAINT FK_customers_loyalty_programs
FOREIGN KEY (loyalty_program_id) 
REFERENCES sales.loyalty_programs(program_id);


-- Q9: Change the data type of sales.customers.zip_code from VARCHAR(5) to VARCHAR(10).
ALTER TABLE sales.customers
ALTER COLUMN zip_code VARCHAR(10);
   

-- Q10: Drop the column 'birth_date' from sales.customers (first add it if it doesn't exist, then drop it).
-- Step 1: Add the column safely if missing
ALTER TABLE sales.customers ADD birth_date DATE NULL;
GO

-- Step 2: Drop the column
ALTER TABLE sales.customers DROP COLUMN birth_date;
GO
  

-- Q11: Create a new table production.product_reviews with appropriate columns and constraints:
--      - review_id (PK, auto-increment)
--      - product_id (FK to production.products)
--      - customer_id (FK to sales.customers)
--      - rating (TINYINT, 1-5)
--      - review_text (VARCHAR(1000))
--      - review_date (DATE, default today)
CREATE TABLE production.product_reviews (
    review_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL FOREIGN KEY REFERENCES production.products(product_id),
    customer_id INT NOT NULL FOREIGN KEY REFERENCES sales.customers(customer_id),
    rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text VARCHAR(1000) NULL,
    review_date DATE NOT NULL DEFAULT GETDATE()
);
-- ================================================================================
-- SECTION C: INSERT STATEMENTS
-- ================================================================================

-- Q12: Insert a new brand called 'Santa Cruz' into production.brands.
INSERT INTO production.brands (brand_name)
VALUES ('Santa Cruz');

-- Q13: Insert three new categories at once: 'Mountain', 'Road', 'Hybrid'.
INSERT INTO production.categories (category_name)
VALUES ('Mountain'), ('Road'), ('Hybrid');

-- Q14: Insert a new product with the following details:
--      product_name = 'Santa Cruz Bronson'
--      brand_id = (the brand_id of 'Santa Cruz' from Q12)
--      category_id = (category_id of 'Mountain' from Q13)
--      model_year = 2025
--      list_price = 4299.99
INSERT INTO production.products (product_name, brand_id, category_id, model_year, list_price)
VALUES (
    'Santa Cruz Bronson', 
    (SELECT brand_id FROM production.brands WHERE brand_name = 'Santa Cruz'), 
    (SELECT category_id FROM production.categories WHERE category_name = 'Mountain'), 
    2025, 
    4299.99
);
-- Q15: Copy all customers from California (state = 'CA') into a new table called sales.ca_customers_backup.
--      (Create the table first with the same structure as sales.customers)
-- This creates the table structure automatically and inserts the data at once
SELECT * INTO sales.ca_customers_backup
FROM sales.customers
WHERE state = 'CA';
-- ================================================================================
-- SECTION D: UPDATE STATEMENTS
-- ================================================================================

-- Q16: Update the phone number of customer with customer_id = 10 to '(555) 123-4567'.
UPDATE sales.customers
SET phone = '(555) 123-4567'
WHERE customer_id = 10;
-- Q17: Increase the list price of all products in the 'Road' category by 8%.
UPDATE production.products
SET list_price = list_price * 1.08
WHERE category_id = (SELECT category_id FROM production.categories WHERE category_name = 'Road');
-- Q18: Mark all orders that have status = 4 (Completed) and shipped_date IS NULL 
--      to set shipped_date = order_date + 3 days.
UPDATE sales.orders
SET shipped_date = DATEADD(day, 3, order_date)
WHERE order_status = 4 AND shipped_date IS NULL;
-- Q19: Set the manager_id of all staffs working at store_id = 1 to staff_id = 5 
--      (assume staff_id 5 is the manager of that store).
UPDATE sales.staffs
SET manager_id = 5
WHERE store_id = 1;
-- Q20: Update the discount for order_items where order_id = 100 and item_id = 2 to 0.15 (15%).
UPDATE sales.order_items
SET discount = 0.15
WHERE order_id = 100 AND item_id = 2;
-- ================================================================================
-- SECTION E: DELETE STATEMENTS
-- ================================================================================

-- Q21: Delete the brand 'Santa Cruz' you inserted in Q12.
DELETE FROM production.brands
WHERE brand_name = 'Santa Cruz';
-- Q22: Delete all order_items that have quantity = 0.
DELETE FROM sales.order_items
WHERE quantity = 0;
-- Q23: Delete all customers who have never placed an order (use subquery with NOT EXISTS).
DELETE FROM sales.customers
WHERE NOT EXISTS (
    SELECT 1 
    FROM sales.orders 
    WHERE sales.orders.customer_id = sales.customers.customer_id
);
-- Q24: Delete all products that have list_price > 10000 and model_year < 2020.
DELETE FROM production.products
WHERE list_price > 10000 AND model_year < 2020;
-- Q25: Delete the loyalty_programs table you created in Q6 (clean up).
-- First safely drop the referencing foreign key on customers to avoid conflicts
ALTER TABLE sales.customers DROP CONSTRAINT FK_customers_loyalty_programs;

DROP TABLE sales.loyalty_programs;
-- ================================================================================
-- SECTION F: COMBINED & CHALLENGE QUESTIONS
-- ================================================================================

-- Q26: Write a single transaction that:
--      1. Creates a new store called 'Downtown LA'
--      2. Adds 3 new staff members to that store
--      3. Inserts 100 units of product_id = 1 into stocks for that store
--      (ROLLBACK if any step fails)
BEGIN TRANSACTION;
BEGIN TRY
    -- 1. Create a new store
    INSERT INTO sales.stores (store_name, phone, email, street, city, state, zip_code)
    VALUES ('Downtown LA', '(213) 555-0199', 'la@bikestores.com', '700 S Flower St', 'Los Angeles', 'CA', '90017');
    
    DECLARE @NewStoreId INT = SCOPE_IDENTITY();

    -- 2. Adds 3 new staff members to that store
    INSERT INTO sales.staffs (first_name, last_name, email, phone, active, store_id, manager_id)
    VALUES 
    ('John', 'Doe', 'john.doe@bikestores.com', '(213) 555-0101', 1, @NewStoreId, 1),
    ('Jane', 'Smith', 'jane.smith@bikestores.com', '(213) 555-0102', 1, @NewStoreId, 1),
    ('Alex', 'Jones', 'alex.jones@bikestores.com', '(213) 555-0103', 1, @NewStoreId, 1);

    -- 3. Inserts 100 units of product_id = 1 into stocks for that store
    INSERT INTO production.stocks (store_id, product_id, quantity)
    VALUES (@NewStoreId, 1, 100);

    -- Commit if everything passes without issues
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    -- Rollback everything if any step encounters an error
    ROLLBACK TRANSACTION;
    THROW;
END CATCH;
-- Q27: Change the schema of sales.order_items: add a new column 'tax_amount' DECIMAL(8,2) DEFAULT 0.00,
--      then update it to be (list_price * quantity * discount * 0.08) for all existing rows.
-- Step 1: Add new column with a default configuration
ALTER TABLE sales.order_items
ADD tax_amount DECIMAL(8,2) NOT NULL DEFAULT 0.00;
GO

-- Step 2: Compute and update the values for existing entries
UPDATE sales.order_items
SET tax_amount = (quantity * list_price * (1 - discount) * 0.08);
-- Q28: Identify and delete duplicate email addresses in sales.customers (keeping the smallest customer_id).
WITH CTE_Duplicates AS (
    SELECT customer_id, email,
           ROW_NUMBER() OVER (PARTITION BY email ORDER BY customer_id ASC) AS row_num
    FROM sales.customers
    WHERE email IS NOT NULL
)
DELETE FROM CTE_Duplicates
WHERE row_num > 1;
-- Q29: Archive all orders from year 2020 or older: 
--      Insert them into a new table sales.orders_archive, then delete from sales.orders.
-- Step 1: Ensure the archive table exists with the historical records
SELECT * INTO sales.orders_archive
FROM sales.orders
WHERE YEAR(order_date) <= 2020;

-- Step 2: Delete related order items first due to Foreign Key rules
DELETE FROM sales.order_items
WHERE order_id IN (SELECT order_id FROM sales.orders_archive);

-- Step 3: Delete the orders from the main active table
DELETE FROM sales.orders
WHERE order_id IN (SELECT order_id FROM sales.orders_archive);
-- Q30: Add a CHECK constraint to production.products ensuring list_price >= 0 AND model_year BETWEEN 1900 AND YEAR(GETDATE())+1.
ALTER TABLE production.products
ADD CONSTRAINT CHK_product_price_year
CHECK (list_price >= 0 AND model_year BETWEEN 1900 AND (YEAR(GETDATE()) + 1));
-- ================================================================================
-- END OF HOMEWORK QUESTIONS
-- ================================================================================E