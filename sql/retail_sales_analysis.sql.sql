CREATE DATABASE ecommerce_analysis;
USE ecommerce_analysis;
CREATE TABLE customers (
customer_id INT PRIMARY KEY AUTO_INCREMENT,
customer_name VARCHAR(100),
city VARCHAR(50),
signup_date DATE 
);

CREATE TABLE products (
product_id INT PRIMARY KEY AUTO_INCREMENT,
product_name VARCHAR(100),
category VARCHAR(50),
price DECIMAL(10,2)
);

CREATE TABLE orders (
order_id INT PRIMARY KEY AUTO_INCREMENT,
customer_id INT,
product_id INT,
order_date DATE,
quantity INT,
sales DECIMAL(10,2),
profit DECIMAL(10,2),

FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
FOREIGN KEY (product_id) REFERENCES products(product_id)
); 

INSERT INTO customers (customer_name, city, signup_date) VALUES
('Rahul Sharma', 'Delhi', '2023-01-15'),
('Amit Verma', 'Mumbai', '2023-03-22'),
('Neha Singh', 'Bangalore', '2023-05-10'),
('Priya Kapoor', 'Delhi', '2023-07-19'),
('Karan Mehta', 'Pune', '2024-01-05');

INSERT INTO products (product_name, category, price) VALUES
('Laptop', 'Electronics', 55000),
('Mobile', 'Electronics', 30000),
('Tablet', 'Electronics', 25000),
('Headphones', 'Accessories', 5000),
('Smartwatch', 'Accessories', 8000);

INSERT INTO orders (customer_id, product_id, order_date, quantity, sales, profit) VALUES
(1, 1, '2023-02-10', 1, 55000, 8000),
(2, 2, '2023-04-05', 1, 30000, 5000),
(3, 3, '2023-06-12', 2, 50000, 7000),
(1, 4, '2023-08-20', 3, 15000, 3000),
(4, 1, '2024-01-15', 1, 55000, 9000),
(5, 5, '2024-02-18', 2, 16000, 4000);

/* City wise total Sales */
SELECT c.city, sum(o.sales) as total_sales
from customers c 
join orders o on c.customer_id = o.customer_id
group by c.city
order by total_sales desc;

/* Category wise sales */
select p.category, sum(o.sales) as total_sales
from products p 
join orders o on p.product_id = o.product_id
group by p.category
order by total_sales desc; 

/* Category wise Profit */
select p.category, sum(o.profit) as total_profit
from products p 
join orders o on p.product_id = o.product_id
group by p.category
order by total_profit desc;

/* Profit Margin */
select 
p.category,
sum(o.sales) as total_sales,
sum(o.profit) as total_profit,
(sum(o.profit) / sum(o.sales)) * 100 as profit_margin
from products p 
join orders o on p.product_id = o.product_id
group by p.category
order by profit_margin desc;

/* Top 5 customers by Revenue */
select c.customer_id, c.customer_name, sum(o.sales) as total_revenue
from customers c
join orders o on c.customer_id = o.customer_id
group by c.customer_id, c.customer_name
order by total_revenue desc
limit 5;

/* Top 5 customers by Profit */
select c.customer_id, c.customer_name, sum(o.profit) as total_profit
from customers c 
join orders o on c.customer_id = o.customer_id
group by c.customer_id, c.customer_name
order by total_profit desc
limit 5;

/* Repeat vs New Customers */

-- Count Orders per Customer --
select customer_id, count(order_id) as total_orders
from orders
group by customer_id;

-- Classify New vs Repeat --
select 
case
when total_orders = 1 then 'New Customer'
else 'Repeat Customer'
end as customer_type,
count(*) as total_customers
from (
select customer_id, count(order_id) as 
total_orders
from orders
group by customer_id
) as customer_orders
group by customer_type;

/* Monthly Sales Trend */
select 
date_format(order_date, '%Y-%m') as month,
sum(sales) as total_sales
from orders
group by month 
order by month; 

/* Customer Lifetime Value (CLV) */
select 
c.customer_id,
c.customer_name,
sum(o.sales) as lifetime_value
from customers c 
join orders o on c.customer_id = o.customer_id
group by c.customer_id, c.customer_name
order by lifetime_value desc;

/* Profit Margin by Category */
select 
p.category, round(sum(o.profit) / sum(o.sales) * 100,2) as profit_margin_percent
from products p 
join orders o on p.product_id = o.product_id
group by p.category
order by profit_margin_percent desc;

/* Cohort Analysis */

-- Find Signup Month --
select customer_id, 
date_format(signup_date, '%Y-%m') as signup_month
from customers;

-- Find Order Month --
select 
o.customer_id,
date_format(c.signup_date, '%Y-%m') as signup_month, 
date_format(o.order_date, '%Y-%m') as order_month
from orders o 
join customers c on o.customer_id = c.customer_id;

-- Basic Cohort Table --
select 
date_format(c.signup_date, '%Y-%m') as signup_month,
date_format(o.order_date, '%Y-%m') as order_month,
count(distinct o.customer_id) as active_customers
from orders o 
join customers c 
on o.customer_id = c.customer_id
group by signup_month, order_month
order by signup_month, order_month;

/* Repeat Purchase Rate */
select 
round(
sum(case when total_orders > 1 then 1 else 0 end) / count(*) * 100,2) as repeat_purchase_rate
from (
select customer_id, count(order_id) as total_orders
from orders
group by customer_id
) as customer_orders;

/* RFM ANALYSIS */

-- Basic RFM Table --
SELECT 
c.customer_id,
c.customer_name,

-- Recency --
DATEDIFF((select MAX(order_date) from orders),
MAX(o.order_date)) as recency_days,

-- Frequency --
COUNT(o.order_id) as frequency,

-- Monetary --
SUM(o.sales) as monetary_value

from customers c 
join orders o on c.customer_id = o.customer_id
group by c.customer_id, c.customer_name
order by monetary_value DESC;

/* RFM Scoring */
select *,
case
when recency_days <= 30 then 'Active'
else 'Inactive'
end as recency_status,

case
when frequency >= 3 then 'Loyal'
else 'Occasional'
end as frequency_status,

case
when monetary_value >= 50000 then 'High Value'
else 'Low Value'
end as monetary_status

from (
select c.customer_id, c.customer_name,
DATEDIFF((SELECT MAX(order_date) from orders),
MAX(o.order_date)) as recency_days,
COUNT(o.order_id) as frequency,
SUM(o.sales) as monetary_value
from customers c
join orders o on c.customer_id = o.customer_id
group by c.customer_id, c.customer_name
) as rfm_table;

CREATE TABLE rfm_analysis AS
SELECT *,
    CASE
        WHEN recency_days <= 30 THEN 'Active'
        ELSE 'Inactive'
    END AS recency_status,

    CASE
        WHEN frequency >= 3 THEN 'Loyal'
        ELSE 'Occasional'
    END AS frequency_status,

    CASE
        WHEN monetary_value >= 50000 THEN 'High Value'
        ELSE 'Low Value'
    END AS monetary_status

FROM (
    SELECT 
        c.customer_id,
        c.customer_name,
        DATEDIFF(
            (SELECT MAX(order_date) FROM orders),
            MAX(o.order_date)
        ) AS recency_days,
        COUNT(o.order_id) AS frequency,
        SUM(o.sales) AS monetary_value
    FROM customers c
    JOIN orders o 
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name
) AS rfm_table;

select * from rfm_analysis;













