use foodie_fi;

-- A. Customer Journey
-- Based off 8 sample customers , write a brief description about each customer’s onboarding journey.
select s.customer_id, p.plan_id, p.plan_name, s.start_date
from plans p
join subscriptions s on p.plan_id = s.plan_id
where s.customer_id in (1,3,5,7,9,11,13,15);

-- Customer 1, 3, and 5: All started with the 1-week trial and then continued their subscription into the basic monthly plan
-- Customer 7, 13: Started with the 1-week trial, continued their subsciption with the basic monthly plan for 3 months and then transitioned into the pro monthly plan
-- Customer 9: Started with the 1-week trial and then got the annual pro plan
-- Customer 11: Only used the 1-week trial and didn't return
-- Customer 15: Started with the 1-week trial and continued their subscription with the pro monthly plan for only a month

-- B. Data Analysis Questions
-- 1. How many customers has Foodie-Fi ever had?
select count(distinct(customer_id))
from subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select extract(month from start_date) as month_date, 
	date_format(start_date, '%M') as month_name,
    count(*) as trial_subscriptions
from subscriptions s
join plans p on p.plan_id = s.plan_id
where s.plan_id = 0 
group by month_date, month_name
order by month_date;

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
select extract(year from start_date) as 'year', plan_name, count(customer_id) as events 
from plans p
join subscriptions s on s.plan_id = p.plan_id
where 'year' > 2020
group by p.plan_id, p.plan_name
order by p.plan_id;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
select count(*) as customer_count,
	round(count(*) * 100 / (
		select count(distinct(customer_id)) 
        from subscriptions),1)
	as churned_percentage
from subscriptions
where plan_id = 4;

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
with cte as(
	select customer_id, plan_name, p.plan_id,
		row_number() over(partition by customer_id order by p.plan_id) as plan_rank
	from plans p
    join subscriptions s on p.plan_id = s.plan_id
    )
select count(*) as customer_count,
	round(count(*) * 100 / (
		select count(distinct(customer_id)) 
        from subscriptions))
	as churned_percentage
from cte
where plan_id = 4 and plan_rank = 2;
    
-- 6. What is the number and percentage of customer plans after their initial free trial?
with next_plan_cte as(
	select customer_id, plan_id,
		lead(plan_id, 1) over(
			partition by customer_id
			order by plan_id) as next_plan
	from subscriptions)
select next_plan, count(*) as conversions,
	round(count(*) * 100 / (
		select count(distinct(customer_id)) 
        from subscriptions)) as conversion_percent
from next_plan_cte
where next_plan is not null and plan_id = 0
group by next_plan
order by next_plan;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
with next_plan as(
	select customer_id, plan_id, start_date,
		lead(start_date, 1) over (partition by customer_id order by start_date) as next_date
	from subscriptions
    where start_date <= '2020-12-31'),
    
    customer_breakdown as(
    select plan_id, count(distinct (customer_id)) as customers
    from next_plan
    where (next_date is not null and (start_date < '2020-12-31' and next_date > '2020-12-31'))
		or (next_date is null and start_date < '2020-12-31')
	group by plan_id)

select plan_id, customers,
	round(customers * 100 / (
		select count(distinct(customer_id)) 
        from subscriptions),1) as percentage
from customer_breakdown
group by plan_id, customers
order by plan_id;
    
-- 8. How many customers have upgraded to an annual plan in 2020?
select count(distinct(customer_id)) as customers
from subscriptions
where plan_id = 3 and start_date > '2020-12-31';

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
with trial_plan as(
	select customer_id, start_date as trial_date
    from subscriptions
    where plan_id = 0),
    
    annual_plan as(
	select customer_id, start_date as annual_date
    from subscriptions
    where plan_id = 3)
    
select round(avg(datediff(annual_date, trial_date)),0) as avg_days_to_upgrade
from trial_plan t
join annual_plan p on t.customer_id = p.customer_id;

-- 10. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
with next_plan_cte as(
	select customer_id, plan_id, start_date,
		lead(start_date, 1) over (partition by customer_id order by start_date) as next_plan
	from subscriptions
    where start_date <= '2020-12-31')

select count(*) as downgraded
from next_plan_cte
where start_date < '2020-12-31'
	and plan_id = 2
    and next_plan = 1;
