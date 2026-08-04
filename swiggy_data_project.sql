 SELECT * FROM swiggy_data;

 -- Data Validation & Cleaning
 -- Null Check 

SELECT 
	SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS null_state,
	SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS null_city,
	SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS null_orderd_ate,
	SUM(CASE WHEN Restaurant_Name IS NULL THEN 1 ELSE 0 END) AS null_resturant,
	SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS null_location,
	SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS null_category,
	SUM(CASE WHEN Dish_Name IS NULL THEN 1 ELSE 0 END) AS null_dish_name,
	SUM(CASE WHEN Price_INR IS NULL THEN 1 ELSE 0 END) AS null_price,
	SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) AS null_rating,
	SUM(CASE WHEN Rating_Count IS NULL THEN 1 ELSE 0 END) AS null_rtcount,
	SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS null_city
FROM swiggy_data;


-- Blank or Empty String
SELECT *
FROM swiggy_data
WHERE 
State = ' ' OR Restaurant_Name = ' '  OR City = ' '
OR Category = ' ' OR Dish_Name = ' ' OR
Price_INR = ' ' OR Rating = ' ' OR Rating_Count = ' ';

-- Duplicate check

SELECT
State, Restaurant_Name, City,
Category, Dish_Name, Location,
Price_INR, Rating_Count, count(*) as CNT
FROM swiggy_data
GROUP BY 
State, Restaurant_Name, City,
Category, Dish_Name, Location,
Price_INR, Rating_Count
HAVING COUNT(*)> 1;

-- DELETE DUPLICATION
WITH CTE AS (
SELECT *, ROW_NUMBER() OVER(
	PARTITION BY State, Restaurant_Name, City,
Category, Dish_Name, Location,
Price_INR, Rating_Count
ORDER BY (SELECT NULL)
) AS rn
FROM swiggy_data
)
delete FROM CTE WHERE rn> 1

-- CREATE SCHEMA
-- DIMENSIONS TABLE
-- DATA TABLE

CREATE TABLE dim_date(
		date_id INT IDENTITY(1,1) PRIMARY KEY,
		Full_Date DATE,
		Year INT,
		Month INT,
		Month_Name varchar(20),
		Quarter INT,
		Day INT,
		Week INT
	);

CREATE TABLE dim_location(
		location_id INT IDENTITY(1,1) PRIMARY KEY,
		State VARCHAR(100),
		City VARCHAR(100),
		Location VARCHAR(100)
);

DROP TABLE IF EXISTS dim_dish;
CREATE TABLE dim_dish(
		dish_id INT IDENTITY(1,1) PRIMARY KEY,
		Dish_Name VARCHAR(200)
);

DROP TABLE IF EXISTS dim_restaurant;
CREATE TABLE dim_restaurant(
		restaurant_id INT IDENTITY(1,1) PRIMARY KEY,
		Restaurant_Name VARCHAR(200)
);

DROP TABLE IF EXISTS dim_category;
CREATE TABLE dim_category(
		category_id INT IDENTITY(1,1) PRIMARY KEY,
		Category VARCHAR(200)
);

CREATE TABLE fact_swiggy_orders(
		order_id INT IDENTITY(1,1) PRIMARY KEY,
		date_id INT REFERENCES dim_date(date_id),
		Price_INR DECIMAL(10,2),
		Rating DECIMAL(4,2),
		Rating_Count INT,
		location_id INT REFERENCES dim_location(location_id),
		restaurant_id INT REFERENCES dim_restaurant(restaurant_id),
		category_id INT REFERENCES dim_category(category_id),
		dish_id INT REFERENCES dim_dish(dish_id)
);


SELECT * FROM fact_swiggy_orders;


-- INSERT DATA IN TABLES
INSERT INTO dim_date(Full_Date,Year, Month, Month_Name, Quarter, Day, Week)
SELECT DISTINCT
		Order_date,
		Year(Order_Date),
		MONTH(Order_Date),
		DATENAME(MONTH,Order_Date),
		DATEPART(QUARTER,Order_Date),
		DAY(Order_Date),
		DATEPART(WEEK, Order_Date)
FROM swiggy_data
WHERE Order_Date IS NOT NULL;

-- CHECK IF THE  DATA INSERTED SUCCESSFULLY
SELECT * FROM dim_date

-- dim_location

INSERT INTO dim_location(State, City, Location)
select distinct
		State,
		City,
		Location
FROM swiggy_data;

SELECT * FROM dim_location;

-- dim_restaurant
INSERT INTO dim_restaurant(Restaurant_Name)
Select DISTINCT
		Restaurant_Name
From swiggy_data;

SELECT * FROM dim_restaurant;

-- dim_category
INSERT INTO dim_category(Category)
SELECT DISTINCT
		Category
FROM swiggy_data;

SELECT * FROM dim_category;

-- dim_dish
INSERT INTO dim_dish(Dish_name)
SELECT DISTINCT
		Dish_Name
FROM swiggy_data;

SELECT * FROM dim_dish;



--fact_table
INSERT INTO fact_swiggy_orders
(
		date_id,
		Price_INR,
		Rating,
		Rating_Count,
		location_id,
		restaurant_id,
		category_id,
		dish_id
)
SELECT
		dd.date_id,
		s.Price_INR,
		s.Rating,
		s.Rating_Count,
		dl.location_id,
		dr.restaurant_id,
		dc.category_id,
		dsh.dish_id
FROM swiggy_data s

JOIN dim_date dd
	ON dd.Full_Date = s.Order_Date

JOIN dim_location dl
	ON dl.State = s.State
	AND dl.City = s.City
	AND dl.Location = s.Location

JOIN dim_restaurant dr
	ON dr.Restaurant_Name = s.Restaurant_Name

Join dim_category dc
	ON dc.Category = s.Category

Join dim_dish dsh
	ON dsh.Dish_Name = s.Dish_Name


SELECT * FROM fact_swiggy_orders;

-------------------------------------------------------------------------------------------------------------------------------------------------------------
--KPIs 
-------------------------------------------------------------------------------------------------------------------------------------------------------------
--Total Otders
SELECT 
	 count(*) as Total_Orders
FROM fact_swiggy_orders;

--Total Revenue
Select*FROM fact_swiggy_orders;
SELECT 
	SUM(Price_INR) as Total_Revenue
FROM fact_swiggy_orders;

--Avarage Dish Price

SELECT 
	FORMAT(AVG(Price_INR), 'N2') as avd_dish_price
FROM fact_swiggy_orders;

--AVG Rating
SELECT 
	FORMAT(AVG(Rating), 'N2') as avg_rating
FROM fact_swiggy_orders;

-----------------------------------------------------------------------------
--Date Based Analysis
-----------------------------------------------------------------------------
--Monthly order trends
SELECT
	dd.Month,
	dd.Month_Name,
	Count(fso.order_id) as total_orders
FROM dim_date dd
LEFT JOIN fact_swiggy_orders fso
	ON dd.date_id = fso.date_id
GROUP BY dd.Month, Month_Name
ORDER BY dd.Month;

--Quartely Order trends

SELECT
	dd.Quarter,
	Count(fso.order_id) as total_orders
FROM dim_date dd
LEFT JOIN fact_swiggy_orders fso
	ON dd.date_id = fso.date_id
GROUP BY dd.Quarter;


--Year_Wise Growth

SELECT
	dd.Year,
	Count(fso.order_id) as total_orders
FROM dim_date dd
LEFT JOIN fact_swiggy_orders fso
	ON dd.date_id = fso.date_id
GROUP BY dd.Year;

--Day of the week patterns

Select*FROM fact_swiggy_orders;
Select*FROM dim_date

SELECT
	dd.Day,
	dd.Week,
	Count(fso.order_id) as total_orders
FROM dim_date dd
LEFT JOIN fact_swiggy_orders fso
	ON dd.date_id = fso.date_id
GROUP BY dd.Day, dd.Week
ORDER BY dd.Day;

----------------------------------------------------------------------------------------------------
--Location Based Analysis
----------------------------------------------------------------------------------------------------
--Top 10 cities by order volume
SELECT TOP 10
	dl.City,
	Count(fso.order_id) as total_orders
From dim_location dl
LEFT JOIN fact_swiggy_orders fso
	ON dl.location_id = fso.location_id
GROUP BY dl.City
ORDER BY total_orders DESC;

--Revenue Contribution by state


SELECT 
	dl.State,
	SUM(fso.Price_INR) as total_revenue
From dim_location dl
LEFT JOIN fact_swiggy_orders fso
	ON dl.location_id = fso.location_id
GROUP BY dl.State
ORDER BY total_revenue DESC;

---------------------------------------------------------------------------------------------------------------------
--Food Perfomance Analysis
---------------------------------------------------------------------------------------------------------------------

--Top Ten Restaurants by orders

SELECT TOP 10
	dr.Restaurant_Name,
	COUNT(fso.order_id) as total_orders
From dim_restaurant dr
LEFT JOIN fact_swiggy_orders fso
	ON dr.restaurant_id = fso.restaurant_id
GROUP BY dr.Restaurant_Name
ORDER BY total_orders DESC;

--Top Categories
	
SELECT TOP 10
	dc.Category,
	COUNT(fso.order_id) as total_orders
From dim_category dc
LEFT JOIN fact_swiggy_orders fso
	ON dc.category_id = fso.category_id
GROUP BY dc.Category
ORDER BY total_orders DESC;

--The best rated dish

WITH DishRatings AS(
SELECT
	dsh.Dish_Name,
	FORMAT(AVG(fso.Rating), 'N2') as avg_rating,
	COUNT(fso.order_id) as total_orders
FROM dim_dish dsh
left join  fact_swiggy_orders fso
	ON dsh.dish_id = fso.dish_id
GROUP BY dsh.Dish_Name
)
SELECT TOP 10
	DENSE_RANK() OVER (ORDER BY avg_rating DESC, total_orders DESC) AS dish_rank,
	Dish_Name,
	avg_rating,
	total_orders
FROM DishRatings
ORDER BY dish_rank;	


-------------------------------------------------------------------------------------------------------------------------------------------------------------
--Customer Spending insights
-------------------------------------------------------------------------------------------------------------------------------------------------------------

--Orders under 100 INR

SELECT 
	count(*) as Total_orders
FROM fact_swiggy_orders
WHERE Price_INR < 100;

--0rders between 100-199
SELECT 
	count(*) as Total_orders
FROM fact_swiggy_orders
WHERE Price_INR >= 100
		AND Price_INR < 200;

--0rders between 200-299
SELECT 
	count(*) as Total_orders
FROM fact_swiggy_orders
WHERE Price_INR >= 200
		AND Price_INR < 300;

--0rders between 300-499
SELECT 
	count(*) as Total_orders
FROM fact_swiggy_orders
WHERE Price_INR >= 300
		AND Price_INR < 500;

--0rders between 500+
SELECT 
	count(*) as Total_orders
FROM fact_swiggy_orders
WHERE Price_INR >= 500;

-------------------------------------------------------------------------------------------------------------------------------
--Rating Analysis
-------------------------------------------------------------------------------------------------------------------------------

-- Distribution of dish ratings
SELECT 
	dsh.Dish_Name,
	FORMAT(AVG(fso.Rating), 'N2') as avg_dish_rate
FROM dim_dish dsh
LEFT JOIN fact_swiggy_orders fso
	ON dsh.dish_id = fso.dish_id
GROUP BY dsh.Dish_Name
ORDER BY avg_dish_rate DESC;


















































