-- I removed fields with missing both price and description when uploading (less then 2% of data).
-- I've also created total SalesVolume as Quantity * UnitPrice.
-- There are negative SalesVolume values. I've spot-checked the biggest ones - looks like returns or transaction correction. I will leave them in the table as they adjust total sales results.

SELECT InvoiceNo, CustomerID, UnitPrice, Quantity, SalesVolume
FROM `test-project-23112023.Demo_set.OnlineRetail`
WHERE SalesVolume <0
ORDER BY SalesVolume;

-- DATA EXPLORATION
-- Do we only have one-time buyers or we have also the data regarding returning clients (more than 2 invoices)? Which client has the most invoices?

SELECT CustomerID, count(Distinct InvoiceNo) as num_of_invoices
FROM `test-project-23112023.Demo_set.OnlineRetail`
GROUP BY CustomerID
Having num_of_invoices > 1
ORDER BY num_of_invoices desc;

-- Let's check the number of unique client, unique products sold and total sales per country. Let's check how each value rank amongs all countries.

SELECT  Country, 
        count(distinct CustomerID) as UniqueClients,
        RANK() OVER (ORDER BY count(distinct CustomerID) desc) as rank_UniqueClients,
        count(distinct StockCode) as UniqueProducts,
        RANK() OVER (ORDER BY count(distinct StockCode) desc) as rank_UniqueStockCode,
        sum(SalesVolume) as TotalSales,
        RANK() OVER (ORDER BY sum(SalesVolume) desc) as rank_TotalSales
FROM `test-project-23112023.Demo_set.OnlineRetail`
GROUP BY Country
ORDER BY TotalSales desc;

-- Let's check if there is any trend in when the order is placed (hour).

SELECT CASE
            WHEN EXTRACT(HOUR FROM InvoiceDate) >= 21 OR (0<=EXTRACT(HOUR FROM InvoiceDate) and EXTRACT(HOUR FROM InvoiceDate)<8) 
                                                THEN 'Night'
            WHEN EXTRACT(HOUR FROM InvoiceDate) < 11 THEN 'Morning'
            WHEN EXTRACT(HOUR FROM InvoiceDate) < 17 THEN 'In the middle of the day'
            WHEN EXTRACT(HOUR FROM InvoiceDate) < 21 THEN 'Evening'
            ELSE 'Unknown time of transaction'
            END AS Time_of_the_day,
      COUNT(distinct InvoiceNo) as count_of_orders
FROM `test-project-23112023.Demo_set.OnlineRetail`
GROUP BY Time_of_the_day;

-- What's the avg transaction (invoice) value per each market?

SELECT Country, 
      ROUND((sum(SalesVolume)/count(distinct InvoiceNo)),2) as avg_invoice_value
FROM `test-project-23112023.Demo_set.OnlineRetail`
GROUP BY Country
ORDER BY avg_invoice_value desc;

-- TOP products for each country in terms of sold quantity.

WITH cte as (SELECT Country, MAX(Quantity) as top_product_quantity
FROM `test-project-23112023.Demo_set.OnlineRetail`
GROUP BY Country)
SELECT e.Country, a.Description, a.Quantity
FROM `test-project-23112023.Demo_set.OnlineRetail` a JOIN cte e ON a.Country=e.Country
            AND a.Quantity = e.top_product_quantity
ORDER BY Country;

-- Client 14911.0 had the most invoices recorded. Let's view his transaction values:

SELECT InvoiceDate, 
      InvoiceNo, 
      sum(Quantity) as TotalQuantity,
      sum(SalesVolume) as TotalSales,
      LAG(sum(SalesVolume)) OVER(ORDER BY InvoiceDate) as Previous_TotalSales
FROM `test-project-23112023.Demo_set.OnlineRetail`
WHERE CustomerID=14911.0
GROUP BY InvoiceDate, InvoiceNo
ORDER BY InvoiceDate;

-- Let's change the granularity of the outcome to MONTHs and view MoM change in %.

WITH cte as (
      SELECT datetime_trunc(InvoiceDate,month) as month,
      sum(Quantity) as TotalQuantity,
      sum(SalesVolume) as TotalSales
      FROM `test-project-23112023.Demo_set.OnlineRetail`
      WHERE CustomerID=14911.0
      GROUP BY month
      ORDER BY month )
SELECT month, 
            ROUND(TotalQuantity,2) as TotalQuantity, 
            ROUND(TotalSales, 2) as TotalSales, 
            LAG(ROUND(TotalSales, 2)) OVER(order by month) as previous_month_total_sales,
            (ROUND(TotalSales, 2)/LAG(ROUND(TotalSales, 2)) OVER(order by month) - 1)*100 as precentage_change
FROM cte
order by month;

