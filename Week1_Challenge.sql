-- Active: 1716123355991@@127.0.0.1@3306@dannys_dinner
-- 1. What is the total amount each customer spent at the restaurant?
select sales.customer_id, sum(menu.price) AS Total_Sales
from sales
join menu on sales.product_id = menu.product_id
group by 1;


-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS "Visiting Days"
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

-- SELECT customer
WITH order_ranked AS 
    (SELECT s.customer_id, s.order_date, m.product_name,
        DENSE_RANK() OVER (PARTITION BY s.customer_id
                    ORDER BY s.order_date) AS date_rank
    FROM sales AS s
    JOIN menu AS m ON s.product_id = m.product_id)
SELECT customer_id, product_name
FROM order_ranked
WHERE date_rank = 1
GROUP BY customer_id, product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name, COUNT(sales.product_id) AS order_count
FROM menu
INNER JOIN sales ON menu.product_id = sales.product_id
GROUP BY product_name
ORDER BY order_count DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?

SELECT customer_id, product_id AS "Most Popular Product"
FROM
    (select 
        customer_id, 
        product_id, 
        COUNT(product_id) as product_count,
        RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) as rnk
    FROM  sales
        GROUP BY customer_id, product_id) as a
WHERE rnk = 1;


-- 6. Which item was purchased first by the customer after they became a member?

SELECT customer_id, product_id
FROM
(select s.customer_id, s.order_date, s.product_id,
ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as rnk
FROM sales as s
JOIN members as m
ON s.order_date > m.join_date) AS a
WHERE rnk = 1;


-- 7. Which item was purchased just before the customer became a member?
with cte_a AS
    (select DISTINCT s.order_date, s.customer_id,  s.product_id,
    RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC) as rnk
    FROM sales as s
    JOIN members as m
    ON s.order_date < m.join_date)
SELECT 
    DISTINCT cte_a.product_id, 
    customer_id,
    menu.product_name AS "Item Purchased just Before Joining"
FROM cte_a
JOIN menu 
ON cte_a.product_id = menu.product_id
WHERE rnk = 1;


-- 8. What is the total items and amount spent for each member before they became a member?
SELECT sales.customer_id, 
        count(sales.product_id) AS TotalItems, 
        SUM(menu.price) AS TotalPrice
FROM sales
JOIN members
    ON sales.customer_id = members.customer_id
JOIN menu
    ON sales.product_id = menu.product_id
WHERE sales.order_date < members.join_date
GROUP BY 1

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH cte_points AS
(select *,
    CASE WHEN product_name = 'sushi' THEN price * 20
    ELSE price * 10
    END AS "points"
from menu)
SELECT customer_id, SUM(points) AS Total_Points
FROM sales
JOIN cte_points
ON sales.product_id = cte_points.product_id
GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

/* Let's do some analytical thinking here, and break down the problem:
1. The first week after a customer joins a program means 6 days after (inclusing the join date)
2. Then we calculate the points for each item bought, that is :

- During the first week of the membership, points = price*20 for all items,

- If Product is Sushi, and order_date is not within a week of membership, then points = price*20,
- If Product is Not Sushi and order_date is not within a week of membership, then points = price*10

3. How many points do Customer A and B have at the end of January:
Therefore, the order_date <= '2021-01-31' -> Order must be placed before 31st January 2021
and order_date >= join_date, Points awarded to only customers with a membership
*/

WITH program_last_day_cte AS
  (SELECT join_date,
          DATE_ADD(join_date, INTERVAL 6 DAY) AS program_last_date,
          customer_id
   FROM members)
SELECT s.customer_id,
       SUM(CASE
               WHEN order_date BETWEEN join_date AND program_last_date THEN price*10*2
               WHEN order_date NOT BETWEEN join_date AND program_last_date
                    AND product_name = 'sushi' THEN price*10*2
               WHEN order_date NOT BETWEEN join_date AND program_last_date
                    AND product_name != 'sushi' THEN price*10
           END) AS customer_points
FROM menu AS m
INNER JOIN sales AS s ON m.product_id = s.product_id
INNER JOIN program_last_day_cte AS mem ON mem.customer_id = s.customer_id
AND order_date <='2021-01-31'
AND order_date >=join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;


