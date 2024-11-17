-- Retrieve the total count of all orders placed

SELECT COUNT(*) Total_Orders
FROM orders;


-- Calculate the overall revenue generated from pizza sales

SELECT ROUND(SUM(od.quantity * p.price),2) Revenue 
FROM pizzas p 
INNER JOIN order_details od ON od.pizza_id = p.pizza_id;


-- Identify the pizza with the highest price(top 3)

SELECT TOP 3 pt.name Pizza_Name, MAX(p.price) Price 
FROM pizzas p 
INNER JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id 
GROUP BY pt.name ORDER BY 2 DESC;


-- Find the most frequently ordered pizza size

SELECT TOP 1 p.size, COUNT(DISTINCT order_id) 'No of Orders', 
SUM(od.quantity) 'Total Quantity Ordered'
FROM pizzas p 
INNER JOIN order_details od ON od.pizza_id = p.pizza_id 
GROUP BY p.size ORDER BY 2 DESC;


-- List the top 5 most popular pizza types, along with their corresponding order quantities

SELECT TOP 5 pt.name Pizza_Name, SUM(od.quantity) Order_Quantity 
FROM order_details od 
INNER JOIN pizzas p ON p.pizza_id = od.pizza_id 
INNER JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id 
GROUP BY pt.name ORDER BY 2 DESC;


-- Determine the total number of pizzas ordered for each category

SELECT TOP 5 pt.category Pizza_Category, SUM(od.quantity) Order_Quantity 
FROM order_details od 
INNER JOIN pizzas p ON p.pizza_id = od.pizza_id 
INNER JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id 
GROUP BY pt.category ORDER BY 2 DESC;


-- Analyze the distribution of orders by hour of the day

SELECT FORMAT(CAST(time AS DATETIME2), N'hh:00 tt') Order_Hour, 
COUNT(*) Order_Count FROM orders o 
GROUP BY FORMAT(CAST(time AS DATETIME2), N'hh:00 tt');

-- OR
-- Without Formatting

SELECT DATEPART(HOUR, o.time) Order_Hour, 
COUNT(*) Order_Count FROM orders o 
GROUP BY DATEPART(HOUR, o.time) ORDER BY 2 DESC;


-- Examine the category-wise distribution of pizzas

SELECT pt.category Pizza_Category, COUNT(*) Pizza_Count FROM order_details od 
INNER JOIN pizzas p ON p.pizza_id = od.pizza_id 
INNER JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id 
GROUP BY pt.category ORDER BY 2 DESC;


-- Group the orders by date and calculate the average number of pizzas ordered per day

WITH CTE AS
(
SELECT 
    o.date Order_Date, 
    SUM(od.quantity) Order_Quantity 
FROM orders o 
INNER JOIN order_details od 
ON od.order_id = o.order_id 
GROUP BY o.date
) 
SELECT 
    AVG(Order_Quantity) Avg_Order_Per_Day 
FROM CTE;


-- Identify the top 3 pizza types in terms of revenue

SELECT 
    TOP 3 pt.name Pizza, 
    CEILING(SUM(p.price * od.quantity)) Revenue 
FROM pizzas p 
INNER JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id 
INNER JOIN order_details od ON od.pizza_id = p.pizza_id 
GROUP BY pt.name ORDER BY 2 DESC;


-- Calculate the percentage contribution of each pizza type to total revenue

SELECT 
    pt.name Pizza, 
    ROUND(SUM(p.price * od.quantity)/(SELECT SUM(od.quantity * p.price) 
											FROM pizzas p 
											INNER JOIN order_details od 
											ON od.pizza_id = p.pizza_id)*100,1) Revenue_Contribution
FROM pizzas p 
INNER JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id 
INNER JOIN order_details od ON od.pizza_id = p.pizza_id 
GROUP BY pt.name ORDER BY 2 DESC;


-- Analyze the cumulative revenue generated over time

WITH CTE AS
(
SELECT 
    o.date Order_Date,
    ROUND(SUM(od.quantity * p.price),2) Revenue
FROM order_details od 
INNER JOIN pizzas p ON p.pizza_id = od.pizza_id 
INNER JOIN orders o ON o.order_id = od.order_id 
GROUP BY o.date
)
SELECT 
    Order_Date, 
    Revenue, 
    SUM(Revenue) OVER 
                (ORDER BY Order_Date 
                ASC) Cumulative_Revenue
FROM CTE;


-- Determine the top 3 highest-revenue pizza types for each category

WITH TOP_3 AS
(
    SELECT 
        pt.name Pizza, 
        pt.category Category,
        CAST(SUM(od.quantity * p.price) AS DECIMAL(10,2)) Revenue
    FROM order_details od
    INNER JOIN pizzas p ON p.pizza_id = od.pizza_id 
    INNER JOIN pizza_types pt ON pt.pizza_type_id = p.pizza_type_id 
    GROUP BY pt.name, pt.category
),
Ranking AS
(
    SELECT 
        Pizza, 
        Category,
        Revenue,
        DENSE_RANK() OVER(PARTITION BY Category ORDER BY Revenue DESC) rnk
    FROM TOP_3
)

SELECT Pizza, Category, Revenue 
FROM Ranking WHERE rnk IN (1,2,3)
ORDER BY Revenue DESC;
