-- 1. What is the total amount each customer spent at the restaurant?
select sales.customer_id, sum(menu.price) AS Total_Sales
from sales
join menu on sales.product_id = menu.product_id
group by 1;

select * from sales;