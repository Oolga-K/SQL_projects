
/* Questions to answer and topics to cover

1. How did sales look in each year?
2. How did sales evolve in each month?
3. Which months were the best in terms of sales?
4. Which country leads in total sales? Which one has the highest average sales?
5. Cities with the highest total sales and with the highest average sales.
6. Dealsize type per market - sales volume.
7. Dealsize type per market - as percentage.
8. TOP PRoducts
9. TOP product categories on a monthly basis.
10. Comparison of sales for Vintage and Classic categories on a monthly basis.
11. TOP Customers
12. Are customers making repeat purchases?
13. How quickly do customers make a repeat purchase?
14. RFM analysis

*/
-- Correcting DATE column - changing format to DATE
SELECT 
    ORDERDATE,
    STR_TO_DATE((REPLACE(orderdate,
                SUBSTRING(orderdate, - 5),
                '')),
            '%m/%d/%Y')
FROM
    `traning_dataset`.`sales_data`;

ALTER TABLE `traning_dataset`.`sales_data`
ADD order_date DATE;

UPDATE `traning_dataset`.`sales_data` 
SET 
    order_date = STR_TO_DATE((REPLACE(orderdate,
                SUBSTRING(orderdate, - 5),
                '')),
            '%m/%d/%Y');

-- Univariate Analysis
SELECT 
    ORDERLINENUMBER,
    SUM(QUANTITYORDERED) AS quantity_per_order,
    ROUND(SUM(SALES), 2) AS sales_per_order
FROM
    `traning_dataset`.`sales_data`
GROUP BY 1
ORDER BY 1;

SELECT 
    STATUS, COUNT(status), SUM(sales), SUM(QUANTITYORDERED)
FROM
    `traning_dataset`.`sales_data`
GROUP BY STATUS;

SELECT Status
		, ROUND(num_orders/total_orders*100,2) as prct_of_total_orders
        , ROUND(quantity_orders/quantity_total_orders*100,2) as prct_of_total_quantity
        , ROUND(sales_orders/sales_total_orders*100,2) as prct_of_total_sales
FROM (Select distinct STATUS
		, count(STATUS) OVER (partition by status) num_orders
		, count(STATUS) OVER () total_orders
		, sum(QUANTITYORDERED) OVER (partition by status) quantity_orders
		, sum(QUANTITYORDERED) OVER () quantity_total_orders
		, round((sum(sales) OVER (partition by status)),2) sales_orders
		, ROUND((sum(sales) OVER ()),2) sales_total_orders
FROM `traning_dataset`.`sales_data`) a;
-- We have 6 status types. 3 of them (Disputed, Cancelled, On Hold) will be excluded from analysis as their execution of the order is uncertain - they're responsible for less then 5% of total sales, qunatity and orders.
-- WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold')

SELECT 
    COUNT(DISTINCT ORDER_DATE), MIN(ORDER_DATE), MAX(ORDER_DATE)
FROM
    `traning_dataset`.`sales_data`;
-- Min date: 06/01/2003, max date: 31/05/2005

SELECT 
    COUNT(DISTINCT ORDERNUMBER),
    COUNT(ORDERNUMBER),
    COUNT(ORDERLINENUMBER) AS num_order_lines,
    COUNT(DISTINCT PRODUCTLINE) AS num_product_lines,
    COUNT(DISTINCT PRODUCTCODE) AS num_products,
    COUNT(DISTINCT CUSTOMERNAME) AS num_clients
FROM
    `traning_dataset`.`sales_data`;

SELECT 
    COUNTRY, COUNT(sales), SUM(sales), AVG(SALES)
FROM
    `traning_dataset`.`sales_data`
GROUP BY COUNTRY;

SELECT 
    COUNTRY, CITY, COUNT(sales), SUM(sales), AVG(SALES)
FROM
    `traning_dataset`.`sales_data`
GROUP BY 1 , 2
ORDER BY 1 , 4;

SELECT 
    DEALSIZE, COUNT(sales), SUM(sales), AVG(SALES)
FROM
    `traning_dataset`.`sales_data`
GROUP BY DEALSIZE;

-- Main Analysis
-- We will exclude orders with uncertain status.

-- 1. How did sales look in each year?
SELECT sales_year
		, Sales
        , ROUND(((sales/lag(Sales) OVER (ORDER BY sales_year)-1)*100),2) as yoy_prct_change_sales
        , avg_sales
        , ROUND(((avg_sales/lag(avg_sales) OVER (ORDER BY sales_year)-1)*100),2) as yoy_prct_change_avg_sales
FROM (SELECT distinct YEAR(order_date) as sales_year
		, ROUND((SUM(SALES) OVER (Partition BY YEAR(order_date))),2) as Sales
        , ROUND((avg(Sales) OVER (Partition BY YEAR(order_date))),2) as avg_sales
FROM `traning_dataset`.`sales_data`
WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold')) a;
-- There was a 31% increase in sales in 2004.The 65% drop in 2005 is due to data covering only half of the year. We can look at the average transaction value which increased by 4.6%

-- 2. How did sales evolve in each month?
-- Checking if we had sales in yeah month
SELECT distinct date_format(order_date,'%Y-%m')
FROM `traning_dataset`.`sales_data`
order by 1;
-- Total number is 29, so we have all months included.

SELECT sales_month
		, avg_sales
		, sales
        , ROUND((sales/lag(sales) OVER (order by sales_month)-1),2) as mom_change
        , ROUND((sales/lag(sales, 12) OVER (order by sales_month)-1),2) as prev_year_month_sales_change
       /* , lag(sales_month,12) OVER (order by sales_month) as prev_year_month
        , lag(sales, 12) OVER (order by sales_month) as prev_year_month_sales */
FROM (SELECT distinct date_format((order_date), '%Y-%m') as sales_month
		, ROUND((SUM(SALES) OVER (Partition BY date_format((order_date), '%Y-%m'))),2) as sales
        , ROUND((AVG(SALES) OVER (Partition BY date_format((order_date), '%Y-%m'))),2) as avg_sales
FROM `traning_dataset`.`sales_data`
WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold')
ORDER BY 1) a;
-- The upward trend is also evident on a monthly basis. This approach allows us to include data from 2005 and confirm the continuation of the upward sales trend. In the years 2003 and 2004, we also observe a significant increase in sales towards the end of the year, which we will confirm in the subsequent analysis.

-- 3. Which months were the best in terms of sales?
-- Comparison of sales for each month in different years. The percentage share of each month in annual sales (prct_month_sale).
SELECT month_num
		, sales_2003
        , ROUND((sales_2003/SUM(sales_2003) OVER ())*100,2) as prct_month_sale
        , sales_2004
        , ROUND((sales_2004/SUM(sales_2004) OVER ())*100,2) as prct_month_sale
        , sales_2005
FROM (SELECT MONTH(order_date) as month_num
		, ROUND(SUM(CASE WHEN YEAR(order_date)='2003' THEN sales END),2) as 'sales_2003'
		, ROUND(SUM(CASE WHEN YEAR(order_date)='2004' THEN sales END),2) as 'sales_2004'
		, ROUND(SUM(CASE WHEN YEAR(order_date)='2005' THEN sales END),2) as 'sales_2005'
FROM `traning_dataset`.`sales_data`
WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold')
GROUP BY 1
ORDER BY 1) a;
-- In the years 2003-2004, the strongest sales months were October and November. The data does not cover the second half of 2005, so it does not show the percentage share of each month in the annual sales.

-- Deeper analysis of selected categories
-- 4. Which country leads in total sales? Which one has the highest average sales?
SELECT COUNTRY
		, sales_per_country
        , rank() OVER (order by sales_per_country desc) as ranking_total_sales
        , avg_sales_per_country
        , rank() OVER (order by avg_sales_per_country desc) as ranking_avg_sales
FROM (SELECT distinct COUNTRY
		, ROUND((sum(sales) over (partition by COUNTRY)),2) as sales_per_country
        , ROUND((avg(sales) over (partition by COUNTRY)),2) as avg_sales_per_country
FROM `traning_dataset`.`sales_data`
WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold')
Order BY 2 desc) a
order by 3;
-- The largest sales markets during the examined period are the USA, Spain, and France. The average transaction value is highest in Sweden, Switzerland, and Austria.

-- 5. Cities with the highest total sales and with the highest average sales.
SELECT CITY
		, sales_per_city
        , rank() OVER (order by sales_per_city desc) as ranking_total_sales
        , avg_sales_per_city
        , rank() OVER (order by avg_sales_per_city desc) as ranking_avg_sales
FROM (SELECT distinct CITY
		, ROUND((sum(sales) over (partition by CITY)),2) as sales_per_city
        , ROUND((avg(sales) over (partition by CITY)),2) as avg_sales_per_city
FROM `traning_dataset`.`sales_data`
WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold')
Order BY 2 desc) a
order by 3;
-- In terms of sales volume, the leading cities are Madrid, San Rafael, and New York City. The average transaction value is highest for New Haven, Liverpool, and Strasbourg.

-- 6. Dealsize type per market - sales volume.
SELECT COUNTRY
		, MAX(CASE WHEN DEALSIZE='Large' THEN sales_deal_type END) as large_sales
		, MAX(CASE WHEN DEALSIZE='Medium' THEN sales_deal_type END) as medium_sales
		, MAX(CASE WHEN DEALSIZE='Small' THEN sales_deal_type END) as small_sales
FROM (SELECT COUNTRY, DEALSIZE, count(dealsize) as num_deal_type, ROUND(sum(sales),2) as sales_deal_type
FROM `traning_dataset`.`sales_data`
WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold')
group by 1,2
order by 1,2) a
GROUP BY 1;

-- 7. Dealsize type per market - as percentage.
SELECT  aa.COUNTRY
        , ROUND(small_sales/sales_per_country*100,2) as prct_of_small_deals
        , ROUND(medium_sales/sales_per_country*100,2) as prct_of_medium_deals
        , ROUND(large_sales/sales_per_country*100,2) as prct_of_large_deals
FROM (SELECT COUNTRY
		, MAX(CASE WHEN DEALSIZE='Large' THEN sales_deal_type END) as large_sales
		, MAX(CASE WHEN DEALSIZE='Medium' THEN sales_deal_type END) as medium_sales
		, MAX(CASE WHEN DEALSIZE='Small' THEN sales_deal_type END) as small_sales
FROM (SELECT COUNTRY, DEALSIZE, count(dealsize) as num_deal_type, sum(sales) as sales_deal_type
FROM `traning_dataset`.`sales_data`
WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold')
group by 1,2
order by 1,2) a 
GROUP BY 1) aa JOIN
					(select country, 
					sum(sales) as sales_per_country
                    from `traning_dataset`.`sales_data`
                    WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold')
                    group by country) b ON aa.country = b.country
ORDER BY aa.country;
-- On most markets, medium-sized transactions dominated (in terms of total sales). Medium-sized transactions represent a vast majority in the Switzerland market - almost 84%. Meanwhile, in Switzerland and Belgium, no large transactions were recorded.
-- The most balanced market is Ireland - here, medium transactions account for just over 46%, while small and large ones each make up almost 27%.

-- 8. TOP Products.
SELECT PRODUCTCODE
		, sum(quantityordered) as Qantity_ordered
		, ROUND(sum(sales),2) as Sales
FROM `traning_dataset`.`sales_data`
WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold')
GROUP BY 1
ORDER BY 3 desc;
-- The best-selling product, both in terms of quantity and total sales, is product number S18_3232.

-- 9. TOP product categories on a monthly basis.
SELECT PRODUCTLINE
		, sum(quantityordered) as Qantity_ordered
		, ROUND(sum(sales),2) as Sales
FROM `traning_dataset`.`sales_data`
WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold')
GROUP BY 1
ORDER BY 3 desc;
-- The most popular category is Classic Cars.

-- 10. Comparison of sales for Vintage and Classic categories on a monthly basis.
SELECT sales_month
		, MAX(CASE WHEN PRODUCTLINE='Classic Cars' THEN Sales END) as classic_cars_sales
		, MAX(CASE WHEN PRODUCTLINE='Vintage Cars' THEN Sales END) as vintage_cars_sales
        , ROUND(MAX(CASE WHEN PRODUCTLINE='Classic Cars' THEN Sales END) - MAX(CASE WHEN PRODUCTLINE='Vintage Cars' THEN Sales END),2) as classic_minus_vintage
        , ROUND(MAX(CASE WHEN PRODUCTLINE='Classic Cars' THEN Sales END)/MAX(CASE WHEN PRODUCTLINE='Vintage Cars' THEN Sales END),2) as classic_to_vintage_ratio
FROM (SELECT distinct date_format((order_date), '%Y-%m') as sales_month
		, PRODUCTLINE
        , ROUND(SUM(Sales),2) as Sales
FROM `traning_dataset`.`sales_data`
WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold') 
		AND PRODUCTLINE IN ('Classic Cars', 'Vintage Cars')
GROUP BY 1,2
ORDER BY 1) a
GROUP BY 1;
-- Only in the beginning of 2003, sales in the Vintage Cars category were higher than in the Classic category. Since March 2003, the Classic category has achieved higher sales levels.

-- 11. TOP Customers.
SELECT CUSTOMERNAME
		, sum(quantityordered) as Quantity_ordered
		, ROUND(sum(sales),2) as Sales
FROM `traning_dataset`.`sales_data`
WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold')
GROUP BY 1
ORDER BY 3 desc;
-- TOP 3 clients: Euro Shopping Channel, Mini Gifts Distributors Ltd., Australian Collectors, Co.


-- Clients analysis
-- Finding max first order date
SELECT CUSTOMERNAME, min(order_date) as first_order_date
FROM `traning_dataset`.`sales_data`
WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold')
GROUP BY 1;
-- All customers made their first purchase by 15/09/2015.

-- 12. Are customers making repeat purchases?
SELECT CUSTOMERNAME, COUNT(distinct order_date) as order_date
FROM `traning_dataset`.`sales_data`
WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold')
GROUP BY 1
HAVING order_date=1;
-- We had only 1 one-time buyer.

-- 13. How quickly do customers make a repeat purchase?
SELECT CASE WHEN days_since_first_purchase <30 THEN "Next purchase within 30 days"
			WHEN  days_since_first_purchase <=90 THEN "Next purchase within 90 days"
			WHEN days_since_first_purchase <= 180 THEN "Next purchase within 180 days"
            WHEN  days_since_first_purchase <=365 THEN "Next purchase within 365 days"
            ELSE "Next purchase after 1 year"
            END as period_from_last_purchase
            , COUNT(CUSTOMERNAME) as num_customers
FROM (SELECT a.CUSTOMERNAME
		, datediff(b.order_date, first_order_date) as days_since_first_purchase
        , MONTH(first_order_date) as month_of_first_order
FROM (SELECT CUSTOMERNAME, MIN(order_date) as first_order_date
FROM `traning_dataset`.`sales_data`
WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold')
GROUP BY 1) a JOIN 
		(SELECT customername	
				, order_date
				, dense_rank() OVER (partition by CUSTOMERNAME ORDER BY order_date) as date_pos
        FROM `traning_dataset`.`sales_data`
        WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold')
        GROUP BY 1,2) b ON a.customername = b.customername and b.order_date > a.first_order_date and b.date_pos = 2) aa
        GROUP BY 1;
-- Most customers make a repeat purchase within six months to a year from the date of their first purchase. Few customers make a repeat purchase within a month.

-- 14. RFM analysis
-- Getting RFM scores
SELECT CUSTOMERNAME
		, recency_score
		, ntile(10) OVER (ORDER BY recency_score desc) as r
        , frequency_score
		, ntile(10) OVER (ORDER BY frequency_score) as f
        , monetary_score
		, ntile(10) OVER (ORDER BY monetary_score) as m
FROM (Select CUSTOMERNAME
		, MAX(order_date) as most_recent_order
		, datediff('2005-06-01',MAX(order_date)) as recency_score
        , COUNT(ORDERNUMBER) as frequency_score
        , ROUND(SUM(SALES),2) as monetary_score
FROM `traning_dataset`.`sales_data`
WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold')
GROUP BY 1) a;

-- Getting total score
SELECT CUSTOMERNAME
		, r
        , f
        , m
        , m + r+ f as rfm_score
FROM (SELECT CUSTOMERNAME
		, recency_score
		, ntile(10) OVER (ORDER BY recency_score desc) as r
        , frequency_score
		, ntile(10) OVER (ORDER BY frequency_score) as f
        , monetary_score
		, ntile(10) OVER (ORDER BY monetary_score) as m
FROM (Select CUSTOMERNAME
		, MAX(order_date) as most_recent_order
		, datediff('2005-06-01',MAX(order_date)) as recency_score
        , COUNT(ORDERNUMBER) as frequency_score
        , ROUND(SUM(SALES),2) as monetary_score
FROM `traning_dataset`.`sales_data`
WHERE STATUS NOT IN ('Disputed','Cancelled','On Hold')
GROUP BY 1) a) aa
ORDER BY rfm_score desc;
-- RFM analysis indicates that the best customers are Mini Gifts Distributors Ltd., La Rochelle Gifts, Souvenirs And Things Co., and Euro Shopping Channel.













