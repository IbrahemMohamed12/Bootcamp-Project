select *
from Customers_cleaning

select *
from Orders_cleaning

select *
from OrdersDetails_cleaning

select *
from Products_cleaning

-- --------------------	Products ----------------------------------

-- 1 - Analyzing sales revenue, units sold, average price for each item & value per order?
SELECT 
    SUM(Revenue) AS TotalRevenue, -- Total Revenue
    SUM(Quantity) AS TotalQuantitySold, -- Total Quantity sold
    ROUND(AVG(Revenue / Quantity), 2) AS average_order_value_per_item, -- Average order value per item
    ROUND(AVG(Revenue / NumOrders), 2) AS average_order_value_per_order -- Average order value per order
FROM (
    SELECT 
        OrderID,
        SUM(Revenue) AS Revenue,
        COUNT(DISTINCT OrderID) AS NumOrders,
        SUM(Quantity) AS Quantity
    FROM 
        OrdersDetails_cleaning
    GROUP BY 
        OrderID
) AS OrderTotals;





-- 2 - Analyzing sales revenue, units sold, and average order value for each product?
SELECT 
    p.ProductName,
    SUM(od.Revenue) AS Revenue,
    SUM(od.Quantity) AS Quantity,
    ROUND(AVG(od.Revenue / od.Quantity), 2) AS average_order_value
FROM 
    OrdersDetails_cleaning od
JOIN 
    Products_cleaning p ON od.ProductID = p.ProductID
GROUP BY 
    p.ProductName
ORDER BY 
    average_order_value DESC;




-- 3 - Identifying top-selling products or categories based on sales volume:
SELECT TOP 10
    p.CategoryName,
    p.ProductName,
    SUM(od.Quantity) AS Quantity
FROM 
    OrdersDetails_cleaning od
JOIN 
    Products_cleaning p ON od.ProductID = p.ProductID
GROUP BY 
    p.ProductName, p.CategoryName
ORDER BY 
    Quantity DESC;



-- 4 - Exploring patterns in sales performance:
SELECT
	o.Quarter,
    o.Month,
    SUM(od.Revenue) AS Revenue
FROM
    OrdersDetails_cleaning od
JOIN
    Products_cleaning p ON od.ProductID = p.ProductID
JOIN
    Orders_cleaning o ON od.OrderID = o.OrderID
GROUP BY
    o.Month,
	o.Quarter
ORDER BY
    Revenue DESC;


-- 5 - The number of units remaining in stock and the number of units required for each product? 
select 
	distinct(ProductName),
	UnitsInStock,
	UnitsOnOrder
from 
	Products_cleaning
order by 
	UnitsOnOrder desc	


-- 6 -  total price of all pending orders for each product? 
select 
	ProductName,
	UnitsOnOrder,
	UnitPrice * UnitsOnOrder as price_of_orders 
from 
	Products_cleaning
where 
	UnitPrice * UnitsOnOrder > 0
order by 
	price_of_orders desc


-- 7 - calculates the total units in stock for each product ?
SELECT 
    ProductName,
	sum(UnitsInStock) UnitsInStock
FROM 
    Products_cleaning 
WHERE 
    UnitsInStock > 0
GROUP BY 
    ProductName
ORDER BY 
    UnitsInStock DESC;


-- 8 - calculates the top 10 products sold ?
SELECT TOP 10
    p.ProductName,
    SUM(od.Quantity) AS Quantity
FROM 
    OrdersDetails_cleaning od
JOIN 
    c p ON od.ProductID = p.ProductID
GROUP BY 
    p.ProductName, p.CategoryName
ORDER BY 
    Quantity DESC;


select ProductName, UnitsInStock
from Products_cleaning
where UnitsInStock = 0




-- --------------------------- Customer -----------------------------------------

-- 1 - Calculate the conversion rate ? 
SELECT 
	 round(count(distinct o.CustomerID) * 100.0 / count(distinct c.CustomerID),2) AS ConversionRate
FROM
    Customers_cleaning c
left JOIN
    Orders_cleaning o ON c.CustomerID = o.CustomerID



-- 2 - RFM analysis ?
drop table if EXISTS #RFM
;with RFM as 
(
SELECT
	c.CustomerID,
    round(sum(Revenue),2) as MontaryValue,
	round(avg(Revenue),2) as AvgMontaryValue,
	round(count(o.OrderID),2) as Frequency,
	max(OrderDate) as LastOrderDate,
	(select max(OrderDate) from Orders_cleaning) MaxOrderDate,
	DATEDIFF(DD,max(OrderDate), (select max(OrderDate) from Orders_cleaning))Recency
FROM 
    Products_cleaning p
JOIN 
    OrdersDetails_cleaning od ON p.ProductID = od.ProductID
JOIN 
    Orders_cleaning o ON od.OrderID = o.OrderID
JOIN 
    Customers_cleaning c ON o.CustomerID = c.CustomerID
group by 
	c.CustomerID
),
RFM_Calc as
(
select *,
	NTILE(5) over(order by Recency desc) RFM_Recency,
	NTILE(5) over(order by Frequency) RFM_Frequency,
	NTILE(5) over(order by MontaryValue) RFM_Montary
from 
	RFM
)
select 
	*,
	RFM_Frequency + RFM_Montary + RFM_Recency as RFM_Cell,
	cast(RFM_Recency as varchar) +  cast(RFM_Frequency as varchar) RFM_Score
into #RFM
from 
	RFM_Calc

select 
	CustomerID,
	Recency,
	Frequency, 
	MontaryValue as Monetary, 
	RFM_Recency as Recency_Score,
	RFM_Frequency as Frequency_Score,
	RFM_Montary as Monetary_Score,
	RFM_Score
from 
	#RFM 

	

-- 3 - what products are most sold together?
SELECT 
    distinct o.OrderID, 
    STUFF(
        (
            SELECT ', ' + p.ProductName
            FROM Orders_cleaning o2
            JOIN OrdersDetails_cleaning od2 ON o2.OrderID = od2.OrderID
            JOIN Products_cleaning p ON od2.ProductID = p.ProductID
            WHERE o2.OrderID = o.OrderID
            FOR XML PATH('')
        ), 1, 1, ''
    ) AS Products
FROM 
    Orders_cleaning o
JOIN 
    OrdersDetails_cleaning od ON o.OrderID = od.OrderID
JOIN 
    Products_cleaning p ON od.ProductID = p.ProductID




-- 4 - what is the best country for units sold and revenue ?
select 
	Country,
	sum(Quantity) Quantity,
	sum(Revenue) Revenue
FROM 
    Orders_cleaning o
JOIN 
    OrdersDetails_cleaning od ON o.OrderID = od.OrderID
JOIN 
    Products_cleaning p ON od.ProductID = p.ProductID
join 
	Customers_cleaning c on o.CustomerID = c.CustomerID
group by 
	Country
order by 
	3 desc




-- 5 - what is the best City for units sold and revenue ?
select 
	City,
	sum(Quantity) Quantity,
	sum(Revenue) Revenue
FROM 
    Orders_cleaning o
JOIN 
    OrdersDetails_cleaning od ON o.OrderID = od.OrderID
JOIN 
    Products_cleaning p ON od.ProductID = p.ProductID
join 
	Customers_cleaning c on o.CustomerID = c.CustomerID
group by 
	City
order by 
	3 desc


-- 6 - count customer of each country?
select 
	Country, 
	count(distinct c.CustomerID) Count_Customer,
	count(distinct c.CompanyName) Count_Company
FROM 
    Orders_cleaning o
JOIN 
    OrdersDetails_cleaning od ON o.OrderID = od.OrderID
JOIN 
    Products_cleaning p ON od.ProductID = p.ProductID
join 
	Customers_cleaning c on o.CustomerID = c.CustomerID
group by 
	Country
order by 2 desc




-- 7 - count Customer of each city ?
select 
	City, 
	count(distinct c.CustomerID) Count_Customer,
	count(distinct c.CompanyName) Count_Company
FROM 
    Orders_cleaning o
JOIN 
    OrdersDetails_cleaning od ON o.OrderID = od.OrderID
JOIN 
    Products_cleaning p ON od.ProductID = p.ProductID
join 
	Customers_cleaning c on o.CustomerID = c.CustomerID
group by 
	City
order by 2 desc


-- 8 - Typr of customer ?
select 
	ContactTitle, 
	count(ContactTitle) count_ContactTitle
FROM 
  Customers_cleaning

group by 
	ContactTitle
order by 2 desc


-- 9 - what is the top 10 country of ship?
select 
	ShipCountry, 
	count(ShipCountry) count_ship
from 
	Orders_cleaning
group by 
	ShipCountry
order by 2 desc


-- 10 - what is the top 10 city of shipping?
select 
	ShipCity, 
	count(ShipCity) count_shipping
from 
	Orders_cleaning
group by 
	ShipCity
order by 2 desc


-- 11 - what is the top 10 city of ordered?
select 
	Country, 
	count(City) count_order
from 
	Orders_cleaning o 
join 
	Customers_cleaning c on o.CustomerID = c.CustomerID
group by 
	Country
order by 2 desc




-- 11 - what is the top 10 city of ordered?
select 
	City, 
	count(City) count_order
from 
	Orders_cleaning o 
join 
	Customers_cleaning c on o.CustomerID = c.CustomerID
group by 
	City
order by 2 desc



select 
	*
from 
	Orders_cleaning o 
join 
	Customers_cleaning c on o.CustomerID = c.CustomerID
where ShipCountry = 'Germany' and Country != 'Germany'




-- 12 - what is the employee has a high sales?
select 
	EmployeeID, 
	sum(Revenue) Revenue,
	sum(Quantity) Quantity
from 
	Orders_cleaning o 
join 
	OrdersDetails_cleaning od on o.OrderID = od.OrderID
group by 
	EmployeeID
order by 2 desc




-- 13 - what is the country hight pric of ship ?
select 
	ShipCountry,
	round(avg(Freight),2) Freight
from 
	Orders_cleaning
group by 
	ShipCountry
order by 2 desc


