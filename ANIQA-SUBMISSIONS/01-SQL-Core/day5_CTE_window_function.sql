-- =========================================================
-- Course: Cloud Data Engineering
-- Module: Section 1 - SQL CTEs, PIVOT, EXPRESSIONS & WINDOW FUNCTIONS (EASY VERSION)
-- Assignment: Day 5 Homework Solution
-- Author: Aniqa Fatani
-- Date: 2 JUNE 2026
-- =========================================================
-- ================================================================================
-- SECTION A: CASE Expressions 
-- ================================================================================

-- Q1: Write a simple CASE that shows order_status as a word instead of number.
--     Show order_id, order_status (number), and status_description (word).
SELECT 
    order_id,
    order_status,
    CASE order_status
        WHEN 1 THEN 'Pending'
        WHEN 2 THEN 'Processing'
        WHEN 3 THEN 'Rejected'
        WHEN 4 THEN 'Completed'
        ELSE 'Unknown'
    END AS status_description
FROM orders;
-- Q2: Categorize products by price:
--     Under $500 = 'Budget'
--     $500 to $2000 = 'Standard' 
--     Over $2000 = 'Premium'
--     Show product_name, list_price, and price_category.
SELECT 
    product_name,
    list_price,
    CASE 
        WHEN list_price < 500 THEN 'Budget'
        WHEN list_price BETWEEN 500 AND 2000 THEN 'Standard'
        WHEN list_price > 2000 THEN 'Premium'
    END AS price_category
FROM products;
-- Q3: Using CASE with COUNT, count how many orders have status = 4 (Completed) 
--     vs non-completed for each store. Show store_id, completed_count, not_completed_count.
SELECT 
    store_id,
    COUNT(CASE WHEN order_status = 4 THEN 1 END) AS completed_count,
    COUNT(CASE WHEN order_status <> 4 THEN 1 END) AS not_completed_count
FROM orders
GROUP BY store_id;
-- Q4: Create a column called "year_label" that shows:
--     If model_year = 2024: 'New'
--     If model_year = 2023: 'Recent'
--     Else: 'Older'
--     Show product_name, model_year, year_label.
SELECT 
    product_name,
    model_year,
    CASE model_year
        WHEN 2024 THEN 'New'
        WHEN 2023 THEN 'Recent'
        ELSE 'Older'
    END AS year_label
FROM products;
-- Q5: For customers, show email and a column called "has_email" that says 'Yes' if email is not NULL, 'No' if NULL.
SELECT 
    email,
    CASE 
        WHEN email IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS has_email
FROM customers;
-- ================================================================================
-- SECTION B: CTEs (Common Table Expressions)
-- ================================================================================

-- Q6: Create a CTE called "high_value_products" that selects products with list_price > 3000.
--     Then SELECT from that CTE to show all those products.
WITH high_value_products AS (
    SELECT * FROM products
    WHERE list_price > 3000
)
SELECT * FROM high_value_products;
-- Q7: Write a CTE that calculates the average list_price of all products.
--     Then use it to find products that cost more than average.
WITH avg_price_cte AS (
    SELECT AVG(list_price) AS global_avg_price 
    FROM products
)
SELECT p.product_name, p.list_price
FROM products p
CROSS JOIN avg_price_cte a
WHERE p.list_price > a.global_avg_price;
-- Q8: Create a CTE called "customer_order_counts" that counts how many orders each customer has.
--     Then use it to find customers with more than 5 orders.
WITH customer_order_counts AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS total_orders
    FROM orders
    GROUP BY customer_id
)
SELECT * FROM customer_order_counts
WHERE total_orders > 5;

-- ================================================================================
-- SECTION C: ROW_NUMBER() and RANK() - EASY BEGINNER
-- ================================================================================

-- Q9: Use ROW_NUMBER() to number all products ordered by list_price from highest to lowest.
--      Show product_name, list_price, and row_number.
SELECT 
    product_name,
    list_price,
    ROW_NUMBER() OVER (ORDER BY list_price DESC) AS row_number
FROM products;
-- Q10: Use ROW_NUMBER() to rank products by price WITHIN each brand (partition by brand_id).
--      Show brand_id, product_name, list_price, and rank_in_brand.
SELECT 
    brand_id,
    product_name,
    list_price,
    ROW_NUMBER() OVER (PARTITION BY brand_id ORDER BY list_price DESC) AS rank_in_brand
FROM products;

-- Q11: Use RANK() instead of ROW_NUMBER() on products ordered by list_price.
--      See what happens when multiple products have the same price.
SELECT 
    product_name,
    list_price,
    RANK() OVER (ORDER BY list_price DESC) AS rank_val
FROM products;
/* Note on what happens: When multiple products share the identical price, 
they receive the same rank value, and the next rank number is skipped.
*/

-- ================================================================================
-- SECTION D: Window Functions - Running Totals and Averages
-- ================================================================================

-- Q12: Calculate a running total of daily orders (cumulative sum over time).
--      Show order_date, daily_order_count, and running_total.
SELECT 
    order_date,
    COUNT(order_id) AS daily_order_count,
    SUM(COUNT(order_id)) OVER (ORDER BY order_date) AS running_total
FROM orders
GROUP BY order_date;
-- Q13: For each product, show its list_price and the average list_price of its brand.
--      Use AVG() OVER (PARTITION BY brand_id).
SELECT 
    product_name,
    brand_id,
    list_price,
    AVG(list_price) OVER (PARTITION BY brand_id) AS brand_avg_price
FROM products;
-- Q14: Calculate a running total of quantity sold for each product over time.
--      Show product_id, order_date, quantity, and cumulative_quantity for that product.
SELECT 
    o.product_id,
    ord.order_date,
    o.quantity,
    SUM(o.quantity) OVER (PARTITION BY o.product_id ORDER BY ord.order_date) AS cumulative_quantity
FROM order_items o
JOIN orders ord ON o.order_id = ord.order_id;

-- ================================================================================
-- SECTION E: LAG, LEAD (Previous and Next)
-- ================================================================================

-- Q15: For each customer, show their order date and the date of their previous order.
--      Use LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date).
SELECT 
    customer_id,
    order_date,
    LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date
FROM orders;
-- Q16: Calculate the number of days between a customer's consecutive orders.
--      (Use LAG and DATEDIFF)
WITH customer_orders_cte AS (
    SELECT 
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date
    FROM orders
)
SELECT 
    customer_id,
    order_date,
    prev_order_date,
    DATEDIFF(day, prev_order_date, order_date) AS days_between_orders
FROM customer_orders_cte;

-- ================================================================================
-- SECTION F: PIVOT (Rows to Columns)
-- ================================================================================

-- Q17: Create a simple pivot showing the count of orders for each order_status (1,2,3,4) 
--      as separate columns. Only need store_id and the 4 status columns.
SELECT store_id, [1] AS status_1, [2] AS status_2, [3] AS status_3, [4] AS status_4
FROM (
    SELECT store_id, order_status, order_id 
    FROM orders
) AS source_table
PIVOT (
    COUNT(order_id)
    FOR order_status IN ([1], [2], [3], [4])
) AS pivot_table;

-- ================================================================================
-- SECTION G: Mixed Practice (Putting It All Together)
-- ================================================================================

-- Q18: Use CASE to categorize customers by total spending:
--      Over $5000 = 'VIP'
--      $1000-$5000 = 'Regular'
--      Under $1000 = 'New'
--      Show customer_name and tier.
-- Assuming spending is calculated from order_items (quantity * list_price * (1 - discount))
WITH customer_spending AS (
    SELECT 
        o.customer_id,
        SUM(i.quantity * i.list_price * (1 - i.discount)) AS total_spent
    FROM orders o
    JOIN order_items i ON o.order_id = i.order_id
    GROUP BY o.customer_id
)
SELECT 
    c.customer_id,
    CASE 
        WHEN s.total_spent > 5000 THEN 'VIP'
        WHEN s.total_spent BETWEEN 1000 AND 5000 THEN 'Regular'
        ELSE 'New'
    END AS tier
FROM customers c
LEFT JOIN customer_spending s ON c.customer_id = s.customer_id;
-- Q19: Use ROW_NUMBER() and CASE together: Find top 3 products per category, 
--      and label them as 'Gold', 'Silver', 'Bronze'.
WITH ranked_products AS (
    SELECT 
        category_id,
        product_name,
        list_price,
        ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY list_price DESC) AS price_rank
    FROM products
)
SELECT 
    category_id,
    product_name,
    list_price,
    CASE price_rank
        WHEN 1 THEN 'Gold'
        WHEN 2 THEN 'Silver'
        WHEN 3 THEN 'Bronze'
    END AS medal_label
FROM ranked_products
WHERE price_rank <= 3;
-- Q20: Create a CTE that calculates monthly revenue, then use LAG to show month-over-month growth.
WITH monthly_revenue_cte AS (
    SELECT 
        DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1) AS revenue_month,
        SUM(i.quantity * i.list_price * (1 - i.discount)) AS current_month_revenue
    FROM orders o
    JOIN order_items i ON o.order_id = i.order_id
    GROUP BY YEAR(o.order_date), MONTH(o.order_date)
),
revenue_history_cte AS (
    SELECT 
        revenue_month,
        current_month_revenue,
        LAG(current_month_revenue) OVER (ORDER BY revenue_month) AS previous_month_revenue
    FROM monthly_revenue_cte
)
SELECT 
    revenue_month,
    current_month_revenue,
    previous_month_revenue,
    (current_month_revenue - previous_month_revenue) AS mom_growth_amount
FROM revenue_history_cte;
-- Q21: Write a query that shows each product, its price, its rank in its brand, 
--      and a CASE that says 'Top Product' if rank = 1, else 'Other'.
WITH brand_ranking_cte AS (
    SELECT 
        brand_id,
        product_name,
        list_price,
        RANK() OVER (PARTITION BY brand_id ORDER BY list_price DESC) AS rank_in_brand
    FROM products
)
SELECT 
    brand_id,
    product_name,
    list_price,
    rank_in_brand,
    CASE 
        WHEN rank_in_brand = 1 THEN 'Top Product'
        ELSE 'Other'
    END AS product_status
FROM brand_ranking_cte;
-- Q22: Create a pivot showing the count of customers by state and by customer tier 
--      (you'll need to create the tier using CASE first, then pivot).
WITH customer_tier_cte AS (
    SELECT 
        c.state,
        c.customer_id,
        CASE 
            WHEN SUM(i.quantity * i.list_price * (1 - i.discount)) > 5000 THEN 'VIP'
            WHEN SUM(i.quantity * i.list_price * (1 - i.discount)) BETWEEN 1000 AND 5000 THEN 'Regular'
            ELSE 'New'
        END AS tier
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    LEFT JOIN order_items i ON o.order_id = i.order_id
    GROUP BY c.state, c.customer_id
)
SELECT state, [VIP], [Regular], [New]
FROM (
    SELECT state, tier, customer_id 
    FROM customer_tier_cte
) AS base_data
PIVOT (
    COUNT(customer_id)
    FOR tier IN ([VIP], [Regular], [New])
) AS final_pivot;
-- ================================================================================
-- END OF HOMEWORK - ALL QUESTIONS ARE BEGINNER-FRIENDLY
-- ================================================================================