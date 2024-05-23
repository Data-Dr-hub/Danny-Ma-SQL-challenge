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



-- 6. Which item was purchased first by the customer after they became a member?

-- 7. Which item was purchased just before the customer became a member?

-- 8. What is the total items and amount spent for each member before they became a member?

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
