---------------------------------
--A. Customer Nodes Exploration
---------------------------------

-- 1) How many unique nodes are there on the Data Bank system?

select count(distinct node_id) 
from data_bank.customer_nodes;

-- 2) What is the number of nodes per region?

select c.region_id,r.region_name, count(c.node_id) as nodes_per_region
from data_bank.customer_nodes c
join data_bank.regions r on c.region_id = r.region_id
group by c.region_id,r.region_name
order by region_id;

--3) How many customers are allocated to each region?

select region_id, count(customer_id)
from data_bank.customer_nodes
group by region_id
order by region_id

--4) How many days on average are customers reallocated to a different node?

WITH node_diff AS (
select  
customer_id, node_id,
end_date - start_date AS diff
from data_bank.customer_nodes
where end_date != '9999-12-31'
group by customer_id, node_id, start_date, end_date
order by customer_id, node_id
),

sum_of_diff as 
(select 
customer_id, node_id, SUM(diff) AS sum_diff
FROM node_diff
GROUP BY customer_id, node_id)

select 
round(avg(sum_diff)) as avg_days
from sum_of_diff

--5) What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

WITH node_diff AS (
select  
customer_id,region_id, node_id,
end_date - start_date AS diff
from data_bank.customer_nodes
where end_date != '9999-12-31'
group by customer_id,region_id, node_id, start_date, end_date
order by customer_id, node_id
),

sum_diff as 
(select
customer_id, region_id,node_id, SUM(diff) AS sum_diff
FROM node_diff
GROUP BY customer_id,region_id, node_id
order by region_id)

select region_id,
percentile_disc(0.5) WITHIN GROUP (ORDER BY sum_diff) as _50th,
percentile_disc(0.8) WITHIN GROUP (ORDER BY sum_diff) as _80th,
percentile_disc(0.9) WITHIN GROUP (ORDER BY sum_diff) as _90th
from sum_diff
group by region_id