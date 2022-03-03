--------------------------------
--Runner and Customer Experience
--------------------------------


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

update pizza_runner.runner_orders
set distance = trim('km' from distance)
where distance like '%km';

update pizza_runner.runner_orders
set distance = ''
where distance='null';

update pizza_runner.runner_orders
set duration = (case when duration like '%minutes' then trim ('minutes' from duration) 
                when duration like '%mins'  then trim ('mins' from duration)
                when duration like '%minute'  then trim ('minute' from duration)
                else duration
                end);     

           
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
--set beginning '2021-01-01'

select date_part('week', registration_date) as week,
count (runner_id) as sign_up
from pizza_runner.runners
group by (date_part('week', registration_date));
 

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

with time_diff as 
(select distinct(c.order_id), c.order_time :: timestamp :: time as order_time,
r.pickup_time :: timestamp :: time as pickup_time,
DATE_part('MINUTE',r.pickup_time :: timestamp :: time-c.order_time :: timestamp :: time)as diff
from pizza_runner.customer_orders c
join pizza_runner.runner_orders r on c.order_id =r.order_id
where r.pickup_time != ''
order by c.order_id)

select avg(diff) as runner_avg_time
from time_diff
where diff>1

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?

with relationship as 
(select c.order_id ,count(c.pizza_id) as pizza_count,
DATE_part('MINUTE',r.pickup_time :: timestamp :: time-c.order_time :: timestamp :: time)as diff
from pizza_runner.customer_orders c
join pizza_runner.runner_orders r on c.order_id =r.order_id 
where r.pickup_time != ''
group by c.order_id,r.pickup_time,c.order_time
order by c.order_id)

select pizza_count, avg(diff)
from relationship
where diff >1
group by pizza_count
order by pizza_count;

-- What was the average distance travelled for each customer?

with avg_dist as
(select c.customer_id,
cast(r.distance as DOUBLE PRECISION)
from pizza_runner.customer_orders c
join pizza_runner.runner_orders r on c.order_id =r.order_id 
where r.pickup_time != '')

select customer_id, avg(distance) as avg_dist
from avg_dist
group by customer_id
order by customer_id;

-- What was the difference between the longest and shortest delivery times for all orders?

select max(cast(duration as DOUBLE PRECISION))-min(cast(duration as DOUBLE PRECISION)) as time_diff_in_mins 
from pizza_runner.runner_orders
where pickup_time != '';

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?

with average_speed as 
(select runner_id, 
cast(distance as double precision),cast(duration as double precision)
from pizza_runner.runner_orders
where pickup_time != '')

select runner_id ,round(distance/duration *60) as speed_km_hr
from average_speed 
order by runner_id;

--runner 2 speed range from 35km/hr to 94km/hrthat seems unusual which probably needs further investigation into it. 

--What is the successful delivery percentage for each runner?
with successful_delivery as 
(select runner_id,count(runner_id) as order_taken,
sum(case when distance != '' then 1 
else 0 
end) as successful_order
from pizza_runner.runner_orders
group by runner_id)

select runner_id, cast(successful_order as float)/order_taken as success_percent
from successful_delivery
order by runner_id;


