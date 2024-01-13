-- Data: US Retail Trade Report
-- Type of analysis: general and time series for car sales category.
-- For easier interpretation of retrieved data I'm exporting the outcome to Tableau - link to dashboard: https://public.tableau.com/app/profile/olga.klusek/viz/US_Car_sales/US_Car_Sales
SELECT DISTINCT
    (kind_of_business)
FROM
    retail_sales
WHERE
    kind_of_business LIKE '%car%';
-- We will work with new and used car dealears.

-- Getting date range of dates
SELECT 
    MAX(sales_month), MIN(sales_month)
FROM
    retail_sales;
-- Data from 1992 to 2020.

-- What's is a general trend in US car sales? Data will be grouped by year to reduce monthly fluctuations.
SELECT 
    YEAR(sales_month) AS sales_year, SUM(sales) as sales
FROM
    retail_sales
WHERE kind_of_business IN
							("New car dealers",
							"Used car dealers")
GROUP BY sales_year;
-- In the period under review, the car sales segment in the USA grew year on year until 2007. In 2008-2009, this category was also severely affected by the crisis, recording the lowest sales value since 1996 in 2009. Since then, the industry has returned to growth and in 2013 the sales volume exceeded the pre-crisis value. The industry returned to a rising trend, which was slowed down in 2020 (possible incomplete data for that year).

-- We will also explore how sales changed since 1992 (base year, stale value).
SELECT sales_year, 
	sales_per_year, 
	first_value(sales_per_year) OVER (ORDER BY sales_year) as sales_in_base_year,
    (sales_per_year/first_value(sales_per_year) OVER (ORDER BY sales_year)-1)*100 as pct_change_to_base_year
FROM 
	(SELECT 
    YEAR(sales_month) AS sales_year,
    SUM(sales) as sales_per_year
FROM
    retail_sales
WHERE kind_of_business IN
							("New car dealers",
							"Used car dealers")
GROUP BY sales_year) a;
-- The results confirm the previous data. The car sales segment recorded increases until 2007, but was seriously affected by the financial crisis. The worst result was recorded in 2009, when sales fell from 114% compared to the base year (2007) to 54% of sales from the base year.

-- Sales by year. Data grouped by type of business: used or new car dealers.
SELECT 
    YEAR(sales_month) AS sales_year, kind_of_business, SUM(sales) as sales
FROM
    retail_sales
WHERE kind_of_business IN
							("New car dealers",
							"Used car dealers")
GROUP BY sales_year, kind_of_business
ORDER BY sales_year, kind_of_business;
-- Both categories were hit by the crisis after 2007, but with a different force. As it's no surprise that the absolute value is always higher for new cars, we will analyse how each category was affected regarding to previous years.

-- Let's review YoY change for both categories.
SELECT `year`,
		kind_of_business,
		yearly_sales,
        lag(`year`) OVER (partition by kind_of_business order by `year`) as prev_year,
        lag(yearly_sales) OVER (partition by kind_of_business order by `year`) as prev_yearly_sales,
        (yearly_sales/lag(yearly_sales) OVER (partition by kind_of_business order by `year`) -1)*100 as pct_diff
FROM (
		SELECT YEAR(sales_month) as `year`,
        kind_of_business,
		sum(sales) as yearly_sales
		FROM retail_sales
        WHERE kind_of_business IN
							("New car dealers",
							"Used car dealers")
        GROUP BY 1,2) a;
-- Such an approach gives us a better picture of the dynamics of changes in both categories. In both categories, sales growth reduced its growth momentum before the crisis. In times of financial crisis, sales of new cars suffered more, which recorded sales declines YoY at 15%. In both categories, there was a dynamic increase in 2010. Since then, the dynamics of sales growth in the case of new cars is marked downward. The dynamics of sales growth of used cars has a relatively stable level.

-- We will analyse the ratio of new cars sales to used cars sales.
SELECT sales_year,
		ROUND(new_cars_sales/used_cars_sales,2) as new_vs_used_cars_sales
FROM (SELECT YEAR(sales_month) as sales_year,
				SUM(CASE 
						WHEN kind_of_business="New car dealers" THEN sales
							END) as new_cars_sales,
				SUM(CASE
						WHEN kind_of_business= "Used car dealers" THEN sales
							END) as used_cars_sales
		FROM
			retail_sales
		WHERE kind_of_business IN
							("New car dealers",
							"Used car dealers")
		GROUP BY 1) a;
-- The ratio of new car sales to used car sales has been decreasing since 1993. The lowest level was reached in the years of crisis - in 2009, new car sales were more than seven times higher than used car sales. After the crisis, this ratio began to increase slightly in favor of new cars, but since 2013 it has been falling again and is currently oscillating around the value from 2009.

-- We can also use different approach and show each category as a % of their total value.
SELECT sales_year,
		ROUND(new_cars_sales/(used_cars_sales+new_cars_sales)*100,2) as new_cars_sales_percentage,
        ROUND(used_cars_sales/(used_cars_sales+new_cars_sales)*100,2) as used_cars_sales_percentage
FROM (SELECT YEAR(sales_month) as sales_year,
				SUM(CASE 
						WHEN kind_of_business="New car dealers" THEN sales
							END) as new_cars_sales,
				SUM(CASE
						WHEN kind_of_business= "Used car dealers" THEN sales
							END) as used_cars_sales
		FROM
			retail_sales
		WHERE kind_of_business IN
							("New car dealers",
							"Used car dealers")
		GROUP BY 1) a;
-- We receive confirmation of the changing proportions of individual categories in the car sales segment - an increase in the share of used car sales in total car sales.

-- Let's change the granularity of received data. I will also use partition by clause to shorten my query.
SELECT sales_month,
		kind_of_business,
        sales,
        SUM(sales) OVER (partition by sales_month) as total_sales,
        ROUND((sales*100/SUM(sales) OVER (partition by sales_month)),2) as total_percentage
FROM
			retail_sales
		WHERE kind_of_business IN
							("New car dealers",
							"Used car dealers");



-- We can also check if there is any seasonality in each type of car sales. We will check sales per month as a percentage of the yearly sales for each category.
-- I will review data for 2019 only. 
SELECT sales_month,
		kind_of_business,
        sales,
        SUM(sales) OVER (partition by YEAR(sales_month), kind_of_business) as total_sales_per_year,
        ROUND((sales*100/SUM(sales) OVER (partition by YEAR(sales_month), kind_of_business)),2) as percentage_of_yearly_sales
FROM
			retail_sales
		WHERE kind_of_business IN
							("New car dealers",
							"Used car dealers")
					AND YEAR(sales_month)=2019
ORDER BY kind_of_business;
-- Looking only at 2019, new cars sold best in August and December. The weakest months are January and February. For used cars, the top month is March, and the worst ones are December and January.

-- Let's dive deeper into new cars segment and explore seasonality of this category. First, we will look at YTD monthly sales values. I will cut data to years 2015-2019.
SELECT sales_month,
		sales,
        SUM(sales) OVER (Partition by YEAR(sales_month) order by sales_month) as ytd_sales
FROM retail_sales
WHERE kind_of_business = 'New car dealers'
		AND YEAR(sales_month) BETWEEN 2015 AND 2019;
-- In the selected range, the data maintain the trend in terms of the worst period - the beginning of the year and autumn. The statement about increased sales in August and December is also confirmed.

-- To explore it more, I will take data from 2015 - 2019 and show each year on the month scale to confirm strong/weak months.
SELECT month(sales_month) as `Month`,
		monthname(sales_month) as month_name,
        max(case when year(sales_month) = 2015 then sales end) as sales_2015,
        max(case when year(sales_month) = 2016 then sales end) as sales_2016,
        max(case when year(sales_month) = 2017 then sales end) as sales_2017,
        max(case when year(sales_month) = 2018 then sales end) as sales_2018,
        max(case when year(sales_month) = 2019 then sales end) as sales_2019
FROM retail_sales
WHERE kind_of_business = 'New car dealers'
	AND sales_month BETWEEN '2015-01-01' AND '2019-12-01'
GROUP BY 1,2;
-- The analysis using the pivot confirms the indicated trends and shows clear periods of seasonality for new car sales.
-- END
