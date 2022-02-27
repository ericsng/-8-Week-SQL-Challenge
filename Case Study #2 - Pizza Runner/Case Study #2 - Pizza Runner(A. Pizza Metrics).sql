--A. Pizza Metrics


-----------------------
--Cleaning the dataset
-----------------------

-- replacing the null values with ''

update pizza_runner.customer_orders
set exclusions = ''
where exclusions = 'null';

update pizza_runner.customer_orders
set extras = ''
where extras is null ;

update pizza_runner.customer_orders
set extras = ''
where extras = 'null';

update pizza_runner.runner_orders
set pickup_time = ''
where pickup_time = 'null';

-----------------------

-----------------------

--How many pizzas were ordered?

select Count(order_id) as Pizza_ordered
from pizza_runner.customer_orders;

--How many unique customer orders were made?

select count(distinct(order_id)) as No_of_Customers
from pizza_runner.customer_orders;
          
--How many successful orders were delivered by each runner?

select runner_id,
count(order_id) as orders_completed 
from pizza_runner.runner_orders
where distance != 'null'
group by runner_id
order by runner_id;


--How many of each type of pizza was delivered?

select p.pizza_name, 
count(c.pizza_id) as delivered 
from pizza_runner.customer_orders c
join pizza_runner.runner_orders r on c.order_id =r.order_id
join pizza_runner.pizza_names p on c.pizza_id=p.pizza_id
where r.distance != 'null'
group by p.pizza_name;

--How many Vegetarian and Meatlovers were ordered by each customer?

select c.customer_id,
p.pizza_name, count(p.pizza_name) as no_ordered
from pizza_runner.customer_orders c
join pizza_runner.pizza_names p on c.pizza_id = p.pizza_id
group by c.customer_id,p.pizza_name
order by c.customer_id;

--What was the maximum number of pizzas delivered in a single order?
with maximum_pizza_per_order as 
(select c.order_id, 
count(c.order_id) as Total_Pizza_delivered,
dense_rank() over(order by count(c.order_id)desc) as rank
from pizza_runner.customer_orders c
join pizza_runner.runner_orders r on c.order_id =r.order_id
join pizza_runner.pizza_names p on c.pizza_id=p.pizza_id
where r.distance != 'null'
group by c.order_id)

select order_id, Total_Pizza_delivered
from maximum_pizza_per_order
where rank =1;

--For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

select c.customer_id, 
sum(case when c.exclusions <>'' or c.extras <> ''
then 1
else 0
end) as at_least_1_change ,
sum(case when c.exclusions = '' and c.extras = ''
then 1
else 0
end) as no_change 

from pizza_runner.customer_orders c
join pizza_runner.runner_orders r on c.order_id= r.order_id
where r.pickup_time != ''
group by customer_id
order by customer_id; 


--How many pizzas were delivered that had both exclusions and extras?

select 
count(case when c.exclusions <>'' and c.extras <> ''
then 1
end) as Pizzas_delivered_with_changes
from pizza_runner.customer_orders c
join pizza_runner.runner_orders r on c.order_id= r.order_id
where r.pickup_time != ''


--What was the total volume of pizzas ordered for each hour of the day?


SELECT extract(hour from order_time) AS hour_of_the_day, COUNT(order_id) AS total_pizzas_ordered
FROM pizza_runner.customer_orders c
GROUP BY extract(hour from order_time)
order by hour_of_the_day ;

--What was the volume of orders for each day of the week?

SELECT extract(ISODOW from order_time) as day_of_the_week, COUNT(order_id) AS total_pizzas_ordered
FROM pizza_runner.customer_orders c
GROUP BY extract(ISODOW from order_time);





