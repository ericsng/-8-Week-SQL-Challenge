------------------------------
C. Ingredient Optimisation
------------------------------

-What are the standard ingredients for each pizza?

with standard_ingredients as  
(SELECT r.pizza_id,
cast(regexp_split_to_table(r.toppings, ',')as int) AS toppings_id
from pizza_runner.pizza_recipes r)

select pizza_id, string_agg(t.topping_name,',') as standard_ingredients
from standard_ingredients
join pizza_runner.pizza_toppings t on toppings_id = t.topping_id
group by pizza_id
order by pizza_id;


--What was the most commonly added extra?

with common_ingredients as 
(SELECT r.pizza_id,
cast(regexp_split_to_table(r.toppings, ',')as int) AS toppings_id
from pizza_runner.pizza_recipes r)

select t.topping_name,count(toppings_id)
from common_ingredients 
join pizza_runner.pizza_toppings t on toppings_id = t.topping_id
group by topping_name 
order by count DESC;


--What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

with total_qty as
(select o.pizza_id,cast((regexp_split_to_table(rec.toppings, ',')) as int) AS toppings_id
from pizza_runner.customer_orders o
join pizza_runner.runner_orders r
on o.order_id = r.order_id 
join pizza_runner.pizza_recipes rec
on o.pizza_id = rec.pizza_id 
where r.pickup_time != 'null')

select t.topping_name, count(toppings_id) as most_frequent_used
from total_qty
join pizza_runner.pizza_toppings t
on toppings_id = t.topping_id 
group by t.topping_name
order by most_frequent_used DESC;

