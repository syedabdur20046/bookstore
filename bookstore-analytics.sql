-- ============================================
-- BOOKSTORE ANALYTICS SQL PROJECT
-- ============================================

-- 1. CREATE DATABASE
CREATE DATABASE IF NOT EXISTS bookstore;

USE bookstore;


-- ============================================
-- 2. BOOKS TABLE
-- ============================================

CREATE TABLE books (
    book_id INT PRIMARY KEY,
    title VARCHAR(200),
    genre VARCHAR(100),
    price DECIMAL(6,2),
    stock INT
);

-- Insert books
INSERT INTO books VALUES
(1, 'Data Science 101', 'Education', 29.99, 100),
(2, 'The Art of SQL', 'Technology', 34.50, 50),
(3, 'Mystery at the Bookstore', 'Fiction', 15.00, 20),
(4, 'Learn Python the Hard Way', 'Education', 40.00, 30),
(5, 'Fantasy World Chronicles', 'Fantasy', 22.50, 10);


-- ============================================
-- 3. CUSTOMERS TABLE
-- ============================================

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(150),
    city VARCHAR(100),
    signup_date DATE
);

-- Insert customers
INSERT INTO customers VALUES
(1, 'Alice', 'New York', '2023-01-10'),
(2, 'Bob', 'San Francisco', '2023-03-15'),
(3, 'Charlie', 'Austin', '2023-06-20'),
(4, 'Diana', 'New York', '2024-01-10'),
(5, 'Evan', 'Chicago', '2024-04-05');


-- ============================================
-- 4. ORDERS TABLE
-- ============================================

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    book_id INT,
    quantity INT,
    order_date DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id)
);

-- Insert orders
INSERT INTO orders VALUES
(1, 1, 1, 2, '2024-06-01'),
(2, 2, 2, 1, '2024-06-02'),
(3, 1, 3, 1, '2024-06-03'),
(4, 3, 1, 3, '2024-06-04'),
(5, 4, 5, 2, '2024-06-04'),
(6, 5, 2, 2, '2024-06-05'),
(7, 2, 4, 1, '2024-06-05'),
(8, 1, 1, 1, '2024-06-06');


-- ============================================
-- 5. MARKETING SPEND TABLE
-- ============================================

CREATE TABLE marketing_spend (
    spend_id INT PRIMARY KEY,
    customer_id INT,
    spend_amount DECIMAL(7,2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Insert marketing spend
INSERT INTO marketing_spend VALUES
(1, 1, 50.00),
(2, 2, 75.00),
(3, 3, 40.00),
(4, 4, 60.00),
(5, 5, 35.00);


-- ============================================
-- BASIC TABLE CHECKS
-- ============================================

SHOW TABLES;

SELECT * FROM books;

SELECT * FROM customers;

SELECT * FROM orders;

SELECT * FROM marketing_spend;


-- ============================================
-- STEP 1: BOOK PERFORMANCE
-- Question: Which books generate the most revenue?
-- ============================================

SELECT 
    b.title,
    SUM(o.quantity) AS total_units_sold,
    SUM(o.quantity * b.price) AS total_revenue
FROM orders o
JOIN books b
    ON o.book_id = b.book_id
GROUP BY b.book_id, b.title
ORDER BY total_revenue DESC;


-- ============================================
-- STEP 2: INVENTORY ALERTS
-- Question: Which books have low stock?
-- ============================================

SELECT
    title,
    stock
FROM books
WHERE stock < 15;


-- ============================================
-- STEP 3: RFM ANALYSIS
-- Recency, Frequency, Monetary
-- ============================================

WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.name,
        MAX(o.order_date) AS last_order,
        COUNT(o.order_id) AS frequency,
        SUM(o.quantity * b.price) AS monetary
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN books b
        ON o.book_id = b.book_id
    GROUP BY c.customer_id, c.name
)
SELECT
    customer_id,
    name,
    last_order,
    frequency,
    monetary,
    DATEDIFF('2024-07-01', last_order) AS recency_days
FROM customer_metrics;


-- ============================================
-- STEP 4: MARKETING SPEND VS REVENUE
-- ============================================

WITH customer_spend AS (
    SELECT
        o.customer_id,
        SUM(o.quantity * b.price) AS total_revenue
    FROM orders o
    JOIN books b
        ON o.book_id = b.book_id
    GROUP BY o.customer_id
)
SELECT
    c.customer_id,
    c.name,
    ms.spend_amount,
    cs.total_revenue,
    ROUND(cs.total_revenue - ms.spend_amount, 2) AS profit
FROM customers c
JOIN marketing_spend ms
    ON c.customer_id = ms.customer_id
JOIN customer_spend cs
    ON c.customer_id = cs.customer_id;


-- ============================================
-- STEP 5: MONTHLY SALES TREND
-- ============================================

SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    SUM(o.quantity * b.price) AS total_revenue
FROM orders o
JOIN books b
    ON o.book_id = b.book_id
GROUP BY month
ORDER BY month;


-- ============================================
-- STEP 6: RETURNING CUSTOMERS
-- Question: Who placed more than one order?
-- ============================================

SELECT
    c.customer_id,
    c.name,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
HAVING COUNT(DISTINCT o.order_id) > 1;


-- ============================================
-- STEP 7: AVERAGE ORDER VALUE
-- ============================================

SELECT
    ROUND(
        SUM(o.quantity * b.price) /
        COUNT(DISTINCT o.order_id),
        2
    ) AS avg_order_value
FROM orders o
JOIN books b
    ON o.book_id = b.book_id;


-- ============================================
-- STEP 8: BOOKS BOUGHT TOGETHER
-- ============================================

SELECT
    o1.book_id AS book_1,
    o2.book_id AS book_2,
    COUNT(*) AS times_bought_together
FROM orders o1
JOIN orders o2
    ON o1.customer_id = o2.customer_id
    AND o1.order_id != o2.order_id
WHERE o1.book_id < o2.book_id
GROUP BY o1.book_id, o2.book_id
ORDER BY times_bought_together DESC
LIMIT 10;


-- ============================================
-- STEP 9: CHURNED CUSTOMERS
-- Customers with no purchase for more than 365 days
-- ============================================

SELECT
    c.customer_id,
    c.name,
    MAX(o.order_date) AS last_purchase,
    DATEDIFF(
        '2025-07-01',
        MAX(o.order_date)
    ) AS days_since_last_purchase
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
HAVING DATEDIFF(
    '2025-07-01',
    MAX(o.order_date)
) > 365;


-- ============================================
-- STEP 10: CUSTOMER LIFETIME VALUE
-- ============================================

SELECT
    c.customer_id,
    c.name,
    SUM(o.quantity * b.price) AS customer_lifetime_value
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN books b
    ON o.book_id = b.book_id
GROUP BY c.customer_id, c.name
ORDER BY customer_lifetime_value DESC;


-- ============================================
-- STEP 11: REVENUE BY CITY
-- ============================================

SELECT
    c.city,
    SUM(o.quantity * b.price) AS total_revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN books b
    ON o.book_id = b.book_id
GROUP BY c.city
ORDER BY total_revenue DESC;


-- ============================================
-- STEP 12: REVENUE BY GENRE
-- ============================================

SELECT
    b.genre,
    SUM(o.quantity * b.price) AS total_revenue
FROM books b
JOIN orders o
    ON b.book_id = o.book_id
GROUP BY b.genre
ORDER BY total_revenue DESC;


-- ============================================
-- STEP 13: STOCK VALUE BY BOOK
-- ============================================

SELECT
    title,
    stock,
    price,
    ROUND(stock * price, 2) AS stock_value
FROM books
ORDER BY stock_value DESC;


-- ============================================
-- STEP 14: TOTAL INVENTORY VALUE
-- ============================================

SELECT
    ROUND(SUM(stock * price), 2) AS total_inventory_value
FROM books;


-- ============================================
-- STEP 15: BEST-SELLING BOOK
-- ============================================

SELECT
    b.title,
    SUM(o.quantity) AS total_units_sold
FROM books b
JOIN orders o
    ON b.book_id = o.book_id
GROUP BY b.book_id, b.title
ORDER BY total_units_sold DESC
LIMIT 1;


-- ============================================
-- STEP 16: TOTAL ORDERS BY CUSTOMER
-- ============================================

SELECT
    c.customer_id,
    c.name,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_orders DESC;