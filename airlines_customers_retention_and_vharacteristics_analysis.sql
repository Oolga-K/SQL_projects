-- Dataset consists of 2 tables: customers_data and flights_data (flights made by customers in 2017-2018). I'm using Tableau only as a support.

 -- What's the average CLV in dataset? Almost 8k
select avg(clv) from `test-project-23112023.Demo_set.customers_data`;

-- CLV and booked flights for different card types
select a.Loyalty_Card, count(a.Loyalty_Number) as group_size, ROUND(avg(a.CLV),2) as average_clv, min(a.CLV) as min_CLV, max(a.CLV) as max_CLV, sum(b.Total_Flights) as total_flights_booked
from `test-project-23112023.Demo_set.customers_data` a join `test-project-23112023.Demo_set.flights_per_customer` b
        on a.Loyalty_Number = b.Loyalty_Number
group by 1; 

-- Basic exploration
SELECT count(Loyalty_Number) as num_clients,
        count(distinct Loyalty_Number) as unique_clients
FROM `test-project-23112023.Demo_set.customers_data`;


SELECT count(a.Loyalty_Number) as num_clients, avg(CLV) as avg_CLV, avg(b.Total_Flights) as avg_bookings
FROM `test-project-23112023.Demo_set.customers_data` a JOIN 
                (SELECT distinct loyalty_number, sum(total_flights) total_flights from `test-project-23112023.Demo_set.flights_data` GROUP BY 1) b 
                ON a.Loyalty_Number=b.Loyalty_Number;

-- Saving query outcome as separate table for further re-use. Name: flights_per_customer
SELECT distinct loyalty_number, sum(total_flights) total_flights from `test-project-23112023.Demo_set.flights_data` GROUP BY 1;

SELECT Year, 
        count(Loyalty_Number) as total_bookings, 
        sum(Total_Flights) as total_flights,
        sum(Flights_Booked) as individual_flights,
        sum(Flights_with_Companions) as accompanied_flights
FROM `test-project-23112023.Demo_set.flights_data`
GROUP BY 1;

-- Checking if we have returning customers
select Loyalty_Number, count(Enrollment_Year) as check
FROM `test-project-23112023.Demo_set.customers_data`
group by 1
having check >1;


-- WHat's the % of each card type group in the set? Let's also show avg CLV of each group as % of avg CLV for the whole set.
select a.loyalty_card, a.total_clients, a.card_type_clients, ROUND((a.card_type_clients/a.total_clients)*100,0) as prct_of_total_clients,
total_avg_CLV, card_type_CLV, ROUND((a.card_type_CLV/a.total_avg_CLV)*100,0) as prct_of_total_avg_CLV
from (select distinct Loyalty_Card,
        count(Loyalty_Number) OVER () as total_clients,
        count(Loyalty_Number) OVER (PARTITION BY Loyalty_Card) as card_type_clients,
        avg(CLV) over () as total_avg_CLV,
        avg(CLV) over (PARTITION BY loyalty_card) as card_type_CLV
from `test-project-23112023.Demo_set.customers_data`) a;


-- TOP average CLV and most flights booked in 2017-2018 - exploring different categories
-- Marital status and gender
SELECT aa.marital_status, aa.gender, 
        aa.avg_clv, aa.total_avg_CLV, ROUND(aa.avg_clv/aa.total_avg_CLV,2) as prct_of_total_avg_clv,
        aa.booked_flights, aa.total_flights, ROUND(aa.booked_flights/aa.total_flights,2) as prct_of_total_bookings
FROM (SELECT a.Marital_Status, 
        a.gender,
        sum(b.Total_Flights) as booked_flights,
        ROUND(avg(a.CLV),2) as avg_clv,
        (SELECT sum(total_flights) FROM `test-project-23112023.Demo_set.flights_per_customer`) as total_flights,
        (SELECT ROUND(avg(CLV),2) FROM `test-project-23112023.Demo_set.customers_data`) as total_avg_CLV
FROM `test-project-23112023.Demo_set.customers_data` a JOIN `test-project-23112023.Demo_set.flights_per_customer` b 
                ON a.Loyalty_Number=b.Loyalty_Number
GROUP BY 1, 2) aa
ORDER BY 1, 2;
-- TOP avg CLV: Divorced group (both men and women)
-- Most flights booked: Married group

-- Education and gender
SELECT aa.education, aa.gender, 
        aa.avg_clv, aa.total_avg_CLV, ROUND(aa.avg_clv/aa.total_avg_CLV,2) as prct_of_total_avg_clv,
        aa.booked_flights, aa.total_flights, ROUND(aa.booked_flights/aa.total_flights,2) as prct_of_total_bookings
FROM (SELECT a.Education, 
        a.gender,
        sum(b.Total_Flights) as booked_flights,
        ROUND(avg(a.CLV),2) as avg_clv,
        (SELECT sum(total_flights) FROM `test-project-23112023.Demo_set.flights_per_customer`) as total_flights,
        (SELECT ROUND(avg(CLV),2) FROM `test-project-23112023.Demo_set.customers_data`) as total_avg_CLV
FROM `test-project-23112023.Demo_set.customers_data` a JOIN `test-project-23112023.Demo_set.flights_per_customer` b 
                ON a.Loyalty_Number=b.Loyalty_Number
GROUP BY 1, 2) aa
ORDER BY 1, 2;
-- TOP avg CLV: Men at High School or Below and both men and women with Bachelor level
-- Most flights booked: Bachelor (both men and women)

-- Loyalty Card
SELECT aa.loyalty_card,
        aa.avg_clv, aa.total_avg_CLV, ROUND(aa.avg_clv/aa.total_avg_CLV,2) as prct_of_total_avg_clv,
        aa.booked_flights, aa.total_flights, ROUND(aa.booked_flights/aa.total_flights,2) as prct_of_total_bookings
FROM (SELECT a.Loyalty_Card, 
        sum(b.Total_Flights) as booked_flights,
        ROUND(avg(a.CLV),2) as avg_clv,
        (SELECT sum(total_flights) FROM `test-project-23112023.Demo_set.flights_per_customer`) as total_flights,
        (SELECT ROUND(avg(CLV),2) FROM `test-project-23112023.Demo_set.customers_data`) as total_avg_CLV
FROM `test-project-23112023.Demo_set.customers_data` a JOIN `test-project-23112023.Demo_set.flights_per_customer` b 
                ON a.Loyalty_Number=b.Loyalty_Number
GROUP BY 1) aa
ORDER BY 1, 2;
-- TOP avg CLV: Aurora card owners
-- Most flights booked: Star card owners

-- Province
SELECT aa.province,
        aa.avg_clv, aa.total_avg_CLV, ROUND(aa.avg_clv/aa.total_avg_CLV,2) as prct_of_total_avg_clv,
        aa.booked_flights, aa.total_flights, ROUND(aa.booked_flights/aa.total_flights,2) as prct_of_total_bookings
FROM (SELECT a.province, 
        sum(b.Total_Flights) as booked_flights,
        ROUND(avg(a.CLV),2) as avg_clv,
        (SELECT sum(total_flights) FROM `test-project-23112023.Demo_set.flights_per_customer`) as total_flights,
        (SELECT ROUND(avg(CLV),2) FROM `test-project-23112023.Demo_set.customers_data`) as total_avg_CLV
FROM `test-project-23112023.Demo_set.customers_data` a JOIN `test-project-23112023.Demo_set.flights_per_customer` b 
                ON a.Loyalty_Number=b.Loyalty_Number
GROUP BY 1) aa
ORDER BY 4 desc;
-- TOP avg CLV: citizens of New Brunswick and Quebec
-- Most flights booked: Ontario and British Columbia

-- Salary group and Gender
SELECT aa.salary_group, 
        aa.gender, 
        aa.avg_clv, aa.total_avg_CLV, ROUND(aa.avg_clv/aa.total_avg_CLV,2) as prct_of_total_avg_clv,
        aa.booked_flights, aa.total_flights, ROUND(aa.booked_flights/aa.total_flights,2) as prct_of_total_bookings
FROM (SELECT CASE
      WHEN a.salary < 100000 THEN 'Below $100k'
      WHEN a.salary <= 200000 THEN 'Between $100k and $200K'
      WHEN a.salary <= 300000 THEN 'Between $200k and $300k'
      ELSE 'More than $300k'
      END as salary_group, 
        a.gender,
        sum(b.Total_Flights) as booked_flights,
        ROUND(avg(a.CLV),2) as avg_clv,
        (SELECT sum(total_flights) FROM `test-project-23112023.Demo_set.flights_per_customer`) as total_flights,
        (SELECT ROUND(avg(CLV),2) FROM `test-project-23112023.Demo_set.customers_data`) as total_avg_CLV
FROM `test-project-23112023.Demo_set.customers_data` a JOIN `test-project-23112023.Demo_set.flights_per_customer` b 
                ON a.Loyalty_Number=b.Loyalty_Number
GROUP BY 1, 2) aa
ORDER BY 1, 2;
-- TOP avg CLV: customers with salary below $100
-- Most flights booked: customers with salary below $100


-- Cohort analysis
-- Creating additional table with dates
select generate_date_array('2012-12-31', '2019-12-31', INTERVAL 1 YEAR) as `end_date`;

-- Creating additional table with enrollment start date and end date (if NULL it will be replaced with 2019-12-31 - date outside of dataset period)
SELECT Loyalty_Number, date(Enrollment_Year, Enrollment_Month,1) as enrollment_start,
       coalesce(date(Cancellation_Year,Cancellation_Month,28),'2019-12-31') as enrollment_end
FROM `test-project-23112023.Demo_set.customers_data`;	

-- Creating periods for cohorts
SELECT a.loyalty_number, a.enrollment_start, a.enrollment_end,
        b.end_date, date_diff(b.end_date,a.enrollment_start, YEAR)  as period
FROM `test-project-23112023.Demo_set.start_end` a LEFT JOIN `test-project-23112023.Demo_set.year_dates` b ON b.end_date between a.enrollment_start and a.enrollment_end
order by 1,4;

-- Cohort's retention
SELECT aa.period,
    first_value(aa.cohort_retained) over (order by aa.period) as cohort_size,
    aa.cohort_retained,
    aa.cohort_retained*100/first_value(aa.cohort_retained) over (order by aa.period) as pct_retained
FROM (SELECT coalesce(a.period,0) as period, count(distinct a.loyalty_number) as cohort_retained,
FROM (SELECT a.loyalty_number, a.enrollment_start, a.enrollment_end,
        b.end_date, date_diff(b.end_date,a.enrollment_start, YEAR)  as period
FROM `test-project-23112023.Demo_set.start_end` a LEFT JOIN `test-project-23112023.Demo_set.year_dates` b ON b.end_date between a.enrollment_start and a.enrollment_end
order by 1,4) a
GROUP BY 1) aa;

-- Cohort size per year start
SELECT extract(YEAR from a.enrollment_start) as first_year, coalesce(a.period,0) as period, count(distinct a.loyalty_number) as cohort_retained,
FROM (SELECT a.loyalty_number, a.enrollment_start, a.enrollment_end,
        b.end_date, date_diff(b.end_date,a.enrollment_start, YEAR)  as period
FROM `test-project-23112023.Demo_set.start_end` a LEFT JOIN `test-project-23112023.Demo_set.year_dates` b ON b.end_date between a.enrollment_start and a.enrollment_end
order by 1,4) a
GROUP BY 1,2
order by 1,2;

-- Cohort analysis: enrollment year
SELECT aa.first_year, aa.period, first_value(aa.cohort_retained) over (partition by aa.first_year order by period) as cohort_size,
aa.cohort_retained,
aa.cohort_retained*100/first_value(aa.cohort_retained) over (partition by aa.first_year order by period) as pct_retained
FROM (SELECT extract(YEAR from a.enrollment_start) as first_year, coalesce(a.period,0) as period, count(distinct a.loyalty_number) as cohort_retained
FROM (SELECT a.loyalty_number, a.enrollment_start, a.enrollment_end,
        b.end_date, date_diff(b.end_date,a.enrollment_start, YEAR)  as period
FROM `test-project-23112023.Demo_set.start_end` a LEFT JOIN `test-project-23112023.Demo_set.year_dates` b ON b.end_date between a.enrollment_start and a.enrollment_end
order by 1,4) a
GROUP BY 1,2
order by 1,2) aa;
-- The enrollment year definitely affects retention curve. Customers who joined the club in 2012 still remain in the program. People who joined in subsequent years have a lower retention level. 
-- After just 1 year, the size of cohort group decreases by 6% and 10% for 2013 and 2014 and by over 10% for the following enrollment years.

-- Cohort analysis: gender
SELECT aa.gender, aa.period, first_value(aa.cohort_retained) over (partition by aa.gender order by period) as cohort_size,
aa.cohort_retained,
aa.cohort_retained*100/first_value(aa.cohort_retained) over (partition by aa.gender order by period) as pct_retained
FROM (SELECT c.gender, coalesce(a.period,0) as period, count(distinct a.loyalty_number) as cohort_retained
FROM (SELECT a.loyalty_number, a.enrollment_start, a.enrollment_end,
        b.end_date, date_diff(b.end_date,a.enrollment_start, YEAR)  as period
FROM `test-project-23112023.Demo_set.start_end` a LEFT JOIN `test-project-23112023.Demo_set.year_dates` b ON b.end_date between a.enrollment_start and a.enrollment_end
order by 1,4) a JOIN `test-project-23112023.Demo_set.customers_data` c ON c.Loyalty_Number=a.loyalty_number
GROUP BY 1,2
order by 1,2) aa;
-- There are no significant differences in retention level between men and women. In both cases we have around 25% decrease after the first year of enrollment. In the subsequent periods the valuse are similar to each other.

-- Cohort analysis: marital status
SELECT aa.marital_status, aa.period, first_value(aa.cohort_retained) over (partition by aa.marital_status order by period) as cohort_size,
aa.cohort_retained,
aa.cohort_retained*100/first_value(aa.cohort_retained) over (partition by aa.marital_status order by period) as pct_retained
FROM (SELECT c.marital_status, coalesce(a.period,0) as period, count(distinct a.loyalty_number) as cohort_retained
FROM (SELECT a.loyalty_number, a.enrollment_start, a.enrollment_end,
        b.end_date, date_diff(b.end_date,a.enrollment_start, YEAR)  as period
FROM `test-project-23112023.Demo_set.start_end` a LEFT JOIN `test-project-23112023.Demo_set.year_dates` b ON b.end_date between a.enrollment_start and a.enrollment_end
order by 1,4) a JOIN `test-project-23112023.Demo_set.customers_data` c ON c.Loyalty_Number=a.loyalty_number
GROUP BY 1,2
order by 1,2) aa;
-- We can infer that the retention level is likely to be higher for singles and married customers than for divorced individuals.

-- Cohort analysis: card type
SELECT aa.loyalty_card, aa.period, first_value(aa.cohort_retained) over (partition by aa.loyalty_card order by period) as cohort_size,
aa.cohort_retained,
aa.cohort_retained*100/first_value(aa.cohort_retained) over (partition by aa.loyalty_card order by period) as pct_retained
FROM (SELECT c.loyalty_card, coalesce(a.period,0) as period, count(distinct a.loyalty_number) as cohort_retained
FROM (SELECT a.loyalty_number, a.enrollment_start, a.enrollment_end,
        b.end_date, date_diff(b.end_date,a.enrollment_start, YEAR)  as period
FROM `test-project-23112023.Demo_set.start_end` a LEFT JOIN `test-project-23112023.Demo_set.year_dates` b ON b.end_date between a.enrollment_start and a.enrollment_end
order by 1,4) a JOIN `test-project-23112023.Demo_set.customers_data` c ON c.Loyalty_Number=a.loyalty_number
GROUP BY 1,2
order by 1,2) aa;
-- As we can see, card type does not significantly impact the retention curve.

-- Cohort analysis: province.
SELECT aa.province, aa.period, first_value(aa.cohort_retained) over (partition by aa.province order by period) as cohort_size,
aa.cohort_retained,
aa.cohort_retained*100/first_value(aa.cohort_retained) over (partition by aa.province order by period) as pct_retained
FROM (SELECT c.province, coalesce(a.period,0) as period, count(distinct a.loyalty_number) as cohort_retained
FROM (SELECT a.loyalty_number, a.enrollment_start, a.enrollment_end,
        b.end_date, date_diff(b.end_date,a.enrollment_start, YEAR)  as period
FROM `test-project-23112023.Demo_set.start_end` a LEFT JOIN `test-project-23112023.Demo_set.year_dates` b ON b.end_date between a.enrollment_start and a.enrollment_end
order by 1,4) a JOIN `test-project-23112023.Demo_set.customers_data` c ON c.Loyalty_Number=a.loyalty_number
GROUP BY 1,2
order by 1,2) aa;
-- We observe that in the initial periods, the highest retention level is maintained by residents of Yukon. In the later periods, customers from Prince Edward Island also exhibit a high retention level.
-- The lowest retention level throughout the examined periods is shown by customers from Saskatchewan and Alberta.

-- Cohort analysis: education.
SELECT aa.education, aa.period, first_value(aa.cohort_retained) over (partition by aa.education order by period) as cohort_size,
aa.cohort_retained,
aa.cohort_retained*100/first_value(aa.cohort_retained) over (partition by aa.education order by period) as pct_retained
FROM (SELECT c.education, coalesce(a.period,0) as period, count(distinct a.loyalty_number) as cohort_retained
FROM (SELECT a.loyalty_number, a.enrollment_start, a.enrollment_end,
        b.end_date, date_diff(b.end_date,a.enrollment_start, YEAR)  as period
FROM `test-project-23112023.Demo_set.start_end` a LEFT JOIN `test-project-23112023.Demo_set.year_dates` b ON b.end_date between a.enrollment_start and a.enrollment_end
order by 1,4) a JOIN `test-project-23112023.Demo_set.customers_data` c ON c.Loyalty_Number=a.loyalty_number
GROUP BY 1,2
order by 1,2) aa;
-- Retention level, through all periods, is definitely higher for customers at Doctor level. in first periods (1 - 3) the lowest retention percentage is shown by people with Bachelor, but this trend changes after 4th period to customers with Masters.

-- Cohort analysis: salary.
SELECT aa.salary_group, aa.period, first_value(aa.cohort_retained) over (partition by aa.salary_group order by period) as cohort_size,
aa.cohort_retained,
aa.cohort_retained*100/first_value(aa.cohort_retained) over (partition by aa.salary_group order by period) as pct_retained
FROM (SELECT CASE
      WHEN c.salary < 100000 THEN 'Below $100k'
      WHEN c.Salary <= 200000 THEN 'Between $100k and $200K'
      WHEN c.salary <= 300000 THEN 'Between $200k and $300k'
      ELSE 'More than $300k'
      END as salary_group, coalesce(a.period,0) as period, count(distinct a.loyalty_number) as cohort_retained
FROM (SELECT a.loyalty_number, a.enrollment_start, a.enrollment_end,
        b.end_date, date_diff(b.end_date,a.enrollment_start, YEAR)  as period
FROM `test-project-23112023.Demo_set.start_end` a LEFT JOIN `test-project-23112023.Demo_set.year_dates` b ON b.end_date between a.enrollment_start and a.enrollment_end
order by 1,4) a JOIN `test-project-23112023.Demo_set.customers_data` c ON c.Loyalty_Number=a.loyalty_number
GROUP BY 1,2
order by 1,2) aa;
-- The income criterion shows the greatest diversity in retention curves. For the first two periods, customers with incomes between $100K and $200K exhibit the smallest decline. 
-- In the later periods, the retention level of this group is the lowest in the examined category. 
-- A different situation is observed in the group of individuals earning between $200K and $300K. In the first two periods, their retention level experiences the largest drop, but from the third period onwards, this is the group with the highest retention level.

-- Creating table for other Tableau vizes
select a.Loyalty_Number, a.Province, a.Gender, a.Education,
      CASE
      WHEN a.salary < 100000 THEN 'Below $100k'
      WHEN a.Salary <= 200000 THEN 'Between $100k and $200K'
      WHEN a.salary <= 300000 THEN 'Between $200k and $300k'
      ELSE 'More than $300k'
      END as salary_group,
      a.marital_status,
      a.loyalty_card,
      a.clv,
      b.year,
      sum(b.total_flights) as flights_booked
from `test-project-23112023.Demo_set.customers_data` a join `test-project-23112023.Demo_set.flights_data` b 
    on a.Loyalty_Number = b.Loyalty_Number
  group by 1,2,3,4,5,6,7,8,9
  order by a.Loyalty_Number;
