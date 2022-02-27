-- 1. What is the total amount each customer spent at the restaurant?

select 
s.customer_id,
sum(m.price) as total_spent 
from dannys_diner.sales s 
join dannys_diner.menu m on s.product_id = m.product_id
group by s.customer_id
order by s.customer_id;

-- 2. How many days has each customer visited the restaurant?

select customer_id, 
count(distinct order_date) as no_of_days_visited
from dannys_diner.sales
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?

with rank_first_item as 
(select s.customer_id, 
s.order_date,m.product_name,
dense_rank() over(partition by s.customer_id order by s.order_date) as rank
from dannys_diner.sales s 
join dannys_diner.menu m on m.product_id = s.product_id
group by s.customer_id, 
s.order_date,m.product_name)

select customer_id,
product_name 
from rank_first_item
where rank =1; 


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select
m.product_name,
count(s.product_id) as most_purchased
from dannys_diner.sales s
join dannys_diner.menu m on s.product_id = m.product_id
group by m.product_name
order by most_purchased desc
limit 1;

-- 5. Which item was the most popular for each customer?
with popular_item_table as 
(select s.customer_id,
m.product_name,
count(s.product_id) as no_of_purchased,
dense_rank() over(partition by s.customer_id order by  count(s.product_id)desc) as rank
from dannys_diner.sales s
join dannys_diner.menu m on s.product_id = m.product_id
group by s.customer_id,
s.product_id,
m.product_name
order by s.customer_id)

select customer_id,
product_name, no_of_purchased as most_popular
from popular_item_table
where rank =1 ;


-- 6. Which item was purchased first by the customer after they became a member
with first_item_purcased as
(select s.customer_id, 
s.order_date, m.product_name,
dense_rank() over(partition by s.customer_id order by s.order_date) as rank
from dannys_diner.sales s
join dannys_diner.menu m on s.product_id = m.product_id
join dannys_diner.members mm on s.customer_id = mm.customer_id
where s.order_date >= mm.join_date 
group by s.customer_id, 
s.order_date, m.product_name
order by s.order_date)

select customer_id,product_name as first_purchased
from first_item_purcased
where rank =1;


-- 7. Which item was purchased just before the customer became a member?
with purchased_before_member as 
(select s.customer_id , 
s.order_date, m.product_name,
dense_rank() over(partition by s.customer_id order by s.order_date desc) as rank
from dannys_diner.sales s
join dannys_diner.menu m on s.product_id = m.product_id
join dannys_diner.members mm on s.customer_id = mm.customer_id
where s.order_date < mm.join_date
group by s.customer_id, 
s.order_date, m.product_name
order by s.order_date)

select customer_id ,order_date,product_name 
from purchased_before_member
where rank =1 ;

-- 8. What is the total items and amount spent for each member before they became a member?

select s.customer_id,
count(m.product_name) as total_items,
sum(m.price) as total_spent 
from dannys_diner.sales s
join dannys_diner.menu m on s.product_id = m.product_id
join dannys_diner.members mm on s.customer_id = mm.customer_id
where s.order_date < mm.join_date
group by s.customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select s.customer_id,
sum(case when m.product_name = 'sushi'
then (m.price*20)
else (m.price *10)
end )as points 
from dannys_diner.sales s
join dannys_diner.menu m on s.product_id = m.product_id
group by s.customer_id
order by customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

select s.customer_id,
sum(case when s.order_date between mm.join_date and mm.join_date +interval '6 day'
then (m.price*20)
when m.product_name = 'sushi'
then (m.price*20)
else (m.price *10)
end)as points
from dannys_diner.sales s
join dannys_diner.menu m on s.product_id = m.product_id
join dannys_diner.members mm on s.customer_id = mm.customer_id 
where s.order_date < '2021-02-01' 
group by s.customer_id
order by s.customer_id;

--------------------
--Bonus Questions
--------------------

--Join All The Things
--The following questions are related creating basic data tables that Danny and his team can use to quickly 
--derive insights without needing to join the underlying tables using SQL.

-- Recreate the following table output using the available data: Customer_id, order_date, product_name, price , member (Y/N)


select s.customer_id,
s.order_date,
m.product_name,
m.price,
case when s.order_date < mm.join_date 
then 'N'
when s.order_date >= mm.join_date
then 'Y'
when s.customer_id not in (select customer_id from dannys_diner.members)
then 'N'
else 'N'
end as member
from dannys_diner.sales s
left join dannys_diner.menu m on s.product_id = m.product_id
left join dannys_diner.members mm on s.customer_id = mm.customer_id 
order by s.customer_id, s.order_date;


-- Recreate the following table output using the available data: Customer_id, order_date, product_name, price , member (Y/N), Ranking (Null, 1,2,3)

with summary as
(select s.customer_id,
s.order_date,
m.product_name,
m.price,
case when s.order_date < mm.join_date 
then 'N'
when s.order_date >= mm.join_date
then 'Y'
when s.customer_id not in (select customer_id from dannys_diner.members)
then 'N'
else 'N'
end as member 
from dannys_diner.sales s
left join dannys_diner.menu m on s.product_id = m.product_id
left join dannys_diner.members mm on s.customer_id = mm.customer_id 
order by s.customer_id, s.order_date)

SELECT *,
case when member = 'N' then NUll
else 
dense_rank () over(partition by customer_id,member order by order_date) end as ranking
from summary;












