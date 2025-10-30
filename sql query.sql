
DROP DATABASE IF EXISTS SalesDB;
CREATE DATABASE SalesDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE SalesDB;

 Create schema (Customers, Products, Orders, OrderItems);
DROP TABLE IF EXISTS OrderItems;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Products;
DROP TABLE IF EXISTS Customers;

CREATE TABLE Customers (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_name VARCHAR(150) NOT NULL,
  city VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Products (
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  product_name VARCHAR(150) NOT NULL,
  category VARCHAR(100),
  price DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Orders (
  order_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  order_date DATE NOT NULL,
  payment_method VARCHAR(50),
  status VARCHAR(30) DEFAULT 'Completed',
  FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

CREATE TABLE OrderItems (
  order_item_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (order_id) REFERENCES Orders(order_id),
  FOREIGN KEY (product_id) REFERENCES Products(product_id)
);


CREATE INDEX idx_orders_orderdate ON Orders(order_date);
CREATE INDEX idx_orderitems_product ON OrderItems(product_id);

-- Insert sample customers
INSERT INTO Customers (customer_name, city) VALUES
('Alice Johnson','New York'),
('Bob Smith','Chicago'),
('Clara Lee','San Francisco'),
('David Brown','New York'),
('Eve Martinez','Los Angeles');

--  Insert sample products
INSERT INTO Products (product_name, category, price) VALUES
('Laptop','Electronics',1200.00),
('Smartphone','Electronics',800.00),
('Desk Chair','Furniture',150.00),
('Monitor','Electronics',300.00),
('Table','Furniture',200.00),
('Wireless Mouse','Accessories',25.00),
('Keyboard','Accessories',45.00),
('Headphones','Accessories',120.00);

-- Insert sample orders
INSERT INTO Orders (customer_id, order_date, payment_method, status) VALUES
(1,'2025-10-01','Credit Card','Completed'),
(1,'2025-10-05','Credit Card','Completed'),
(2,'2025-10-06','PayPal','Completed'),
(3,'2025-10-08','Credit Card','Completed'),
(4,'2025-10-10','Debit Card','Completed'),
(2,'2025-10-12','PayPal','Completed'),
(5,'2025-10-12','Credit Card','Completed'),
(1,'2025-10-12','Credit Card','Completed'),
(3,'2025-10-13','Debit Card','Completed');

-- 5. Insert sample order items (order_id values 1..9)
INSERT INTO OrderItems (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 1200.00),
(2, 2, 2, 800.00),
(3, 3, 1, 150.00),
(4, 4, 3, 300.00),
(5, 5, 2, 200.00),
(6, 2, 1, 800.00),
(7, 7, 4, 45.00),
(8, 6, 3, 25.00),
(8, 8, 1, 120.00),
(9, 4, 1, 300.00);

--  Convenience view: order totals (order-level)
DROP VIEW IF EXISTS vw_order_totals;
CREATE VIEW vw_order_totals AS
SELECT
  o.order_id,
  o.order_date,
  o.customer_id,
  c.customer_name,
  ROUND(SUM(oi.quantity * oi.unit_price),2) AS order_total,
  SUM(oi.quantity) AS items_count
FROM Orders o
JOIN OrderItems oi USING(order_id)
JOIN Customers c ON o.customer_id = c.customer_id
GROUP BY o.order_id, o.order_date, o.customer_id, c.customer_name;

SELECT
  o.order_date AS report_date,
  COUNT(DISTINCT o.order_id) AS orders_count,
  ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_revenue,
  SUM(oi.quantity) AS total_items_sold,
  ROUND(SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM Orders o
JOIN OrderItems oi ON o.order_id = oi.order_id
GROUP BY o.order_date
ORDER BY o.order_date;
SELECT
  'Overall' AS scope,
  COUNT(*) AS total_orders,
  ROUND(AVG(order_total),2) AS avg_order_value,
  ROUND(SUM(order_total),2) AS total_revenue
FROM vw_order_totals;

--- REPORT B2: Average order value by customer (and total spent) 
SELECT
  customer_name,
  COUNT(order_id) AS orders_count,
  ROUND(AVG(order_total),2) AS avg_order_value,
  ROUND(SUM(order_total),2) AS total_spent
FROM vw_order_totals
GROUP BY customer_name
ORDER BY total_spent DESC;

/* REPORT C1: Top products by revenue */
SELECT
  p.product_id,
  p.product_name,
  p.category,
  ROUND(SUM(oi.quantity * oi.unit_price),2) AS revenue,
  SUM(oi.quantity) AS units_sold
FROM OrderItems oi
JOIN Products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue DESC
LIMIT 10;

/* REPORT C2: Top products by quantity sold */
SELECT
  p.product_id,
  p.product_name,
  SUM(oi.quantity) AS units_sold,
  ROUND(SUM(oi.quantity * oi.unit_price),2) AS revenue
FROM OrderItems oi
JOIN Products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC
LIMIT 10;

/* REPORT D: Monthly revenue trend (YYYY-MM) */
SELECT
  DATE_FORMAT(o.order_date, '%Y-%m') AS year_month,
  COUNT(DISTINCT o.order_id) AS orders_count,
  ROUND(SUM(oi.quantity * oi.unit_price),2) AS total_revenue
FROM Orders o
JOIN OrderItems oi USING(order_id)
GROUP BY year_month
ORDER BY year_month;

/* REPORT E: Top customers by spending (limit 10) */
SELECT
  c.customer_id,
  c.customer_name,
  COUNT(DISTINCT o.order_id) AS orders_count,
  ROUND(SUM(oi.quantity * oi.unit_price),2) AS total_spent
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN OrderItems oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC
LIMIT 10;
