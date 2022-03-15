----------------------------
--B. Data Analysis Questions
----------------------------

--How many customers has Foodie-Fi ever had?

SELECT count(distinct customer_id) as total_customers
FROM foodie_fi.subscriptions;

--What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

select to_char(start_date,'month'),count(customer_id)
from foodie_fi.subscriptions
where plan_id = 0
group by to_char(start_date,'month'),date_part('month',start_date)
order by date_part('month',start_date) ;

--What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

select s.plan_id,p.plan_name,count(case when date_part('year',s.start_date)=2020
then 1 end)as year_2020,
count(case when date_part('year',s.start_date)=2021
then 1
end) as Year_2021
FROM foodie_fi.subscriptions s
join foodie_fi.plans p on s.plan_id= p.plan_id
group by s.plan_id,p.plan_name
order by s.plan_id;

--What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

select count(s.customer_id) as no_of_churn, 
round(100*cast(count(s.customer_id) as numeric) /(select count(distinct customer_id)from foodie_fi.subscriptions),1) as churn_rate
from foodie_fi.subscriptions s
where plan_id =4;

--How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

with free_trial_churn as
(select customer_id,plan_id,dense_rank() over(partition by customer_id order by plan_id) as rank
from foodie_fi.subscriptions)

select count(plan_id), round(cast(count(plan_id)as numeric)/(select count(distinct customer_id) from free_trial_churn)*100,0) as percent_of_total 
from free_trial_churn
where plan_id=4 and rank =2 ;

--What is the number and percentage of customer plans after their initial free trial?

with free_trial_churn as
(select customer_id,plan_id,dense_rank() over(partition by customer_id order by plan_id) as rank
from foodie_fi.subscriptions)

select plan_id, count(plan_id), round(cast(count(plan_id)as numeric)/(select count(distinct customer_id) from free_trial_churn)*100,1) as percent_of_total 
from free_trial_churn
where plan_id !=0 and rank =2
group by plan_id;

--What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?


with next_date as 
(SELECT 
  customer_id, 
  plan_id, 
  start_date,
  LEAD(start_date, 1) OVER(PARTITION BY customer_id ORDER BY start_date) as next_date
FROM foodie_fi.subscriptions
WHERE start_date <= '2020-12-31')

select plan_id, count(plan_id),round(100*count(plan_id)::numeric/
(select count(*) from next_date
                where next_date is null),1) as perc
from next_date
where next_date is null
group by plan_id;


--How many customers have upgraded to an annual plan in 2020?

select count(customer_id)
from foodie_fi.subscriptions 
where plan_id = 3 and start_date <= '2020-12-31’;


--How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

with joined_date as 
(select customer_id,start_date as joined_date
from foodie_fi.subscriptions
where plan_id = 0),

annual_date as 
(select customer_id,start_date as annual_date
from foodie_fi.subscriptions
where plan_id = 3)

select  
round(avg(a.annual_date - j.joined_date)) as average_no_of_days
from joined_date j
join annual_date a on j.customer_id = a.customer_id;

--Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

WITH join_date AS 
(SELECT 
  customer_id, 
  start_date AS join_date
FROM foodie_fi.subscriptions
WHERE plan_id = 0
),
-- Filter results to customers at pro annual plan = 3
annual_date AS
(SELECT 
  customer_id, 
  start_date AS annual_date
FROM foodie_fi.subscriptions
WHERE plan_id = 3
),

bin as 
(SELECT 
WIDTH_BUCKET(a.annual_date - j.join_date, 0, 360, 12) AS avg_days_to_upgrade
FROM join_date j
JOIN annual_date a
  ON a.customer_id = j.customer_id)
  
SELECT 
  ((avg_days_to_upgrade - 1) * 30 || ' - ' || (avg_days_to_upgrade) * 30) || ' days' AS bins, 
  COUNT(*) AS customers
FROM bin
GROUP BY avg_days_to_upgrade
ORDER BY avg_days_to_upgrade;


--How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

with downgrade as 
(SELECT 
  customer_id, 
  plan_id, 
  start_date,
  LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY plan_id) as next_plan
FROM foodie_fi.subscriptions
WHERE start_date <= '2020-12-31')

select count(case when plan_id =2 and next_plan =1 then 1 end)as total_customers_who_downgraded
from downgrade;

