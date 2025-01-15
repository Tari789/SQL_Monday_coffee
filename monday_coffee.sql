
-- Monday Coffee-- Analysis 

       
 --1. How many people in each city are estimated to consume coffee, given that 25% of the population does?
 
 
 SELECT city_name ,Round((population * 0.25)/100000, 2)  AS no_of_coffee_consumers_millions, city_rank 
  FROM city
  ORDER BY 2 
  
  
  ---2.What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
  
  SELECT
    Sum (total) AS total_rev
  FROM Sales 
  WHERE
    EXTRACT(YEAR FROM sale_date) = 2023
    AND
    EXTRACT(Quarter FROM sale_date) = 4
    
 
 --- Q3 How many units of each coffee product have been sold?
  
  
SELECT 
 p.product_name, 
 count(s.sale_id) AS total_orders 
FROM products AS p 
LEFT JOIN 
sales AS s 
ON s.product_id = p.product_id
GROUP BY 1 
  
  --Q4.What is the average sales amount per customer in each city?
  
SELECT 
   ci.city_name,
   SUM (s.total) AS total_revenue, 
   Count(DISTINCT s.customer_id),
   Round (SUM (s.total)::NUMERIC / Count(DISTINCT s.customer_id)::NUMERIC ,2) AS AVG_sellpercity
FROM sales AS s 
JOIN customers AS c 
ON s.customer_id = c.customer_id
JOIN city AS ci 
ON ci.city_id = c.city_id
GROUP BY 1 
ORDER BY 2 DESC 


---5. Provide a list of cities along with their populations and estimated coffee consumers.


WITH city_table AS 
(
    SELECT 
     city_name,
     Round((population*0.25)/1000000,2) AS coffee_consumers 
    FROM city
 ) , 
 
 customers_table AS
  (
  
  SELECT 
     ci.city_name,
     count(DISTINCT c.customer_id) AS unique_cx 
  FROM sales AS s
  JOIN customers AS c 
  ON c.customer_id = s.customer_id
  JOIN city AS ci 
  ON ci.city_id = c.city_id
  GROUP BY 1 
)
    
  SELECT 
    customers_table.city_name, 
    city_table.coffee_consumers AS coffee_consumers,
    customers_table.unique_cx
  FROM city_table 
  JOIN  customers_table 
  ON city_table.city_name = customers_table.city_name 

------ Q6 What are the top 3 selling products in each city based on sales volume?



SELECT * FROM 

(SELECT
    ci.city_name,
    p.product_name,
    count(s.sale_id) AS total_orders,
    dense_rank() OVER (PARTITION BY ci.city_name ORDER BY count(s.sale_id)DESC) AS rank 
FROM sales AS s 
JOIN products AS p 
ON s.product_id = p.product_id 
JOIN customers AS c 
ON c.customer_id = s.customer_id
JOIN city AS ci 
ON ci.city_id = c.city_id 
GROUP BY 1,2
--order by 1,3 Desc 
) AS t1 
WHERE rank IN(1,2,3)


---- 7.  many unique customers are there in each city who have purchased coffee products?

SELECT 
  ci.city_name,
  count(DISTINCT c.customer_id) AS unx_cus
FROM city AS ci 
LEFT JOIN customers AS c 
ON c.city_id = ci.city_id 
JOIN sales AS s 
ON s.customer_id = c.customer_id 
WHERE 
s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY 1 

-- Q8 Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer


WITH city_table AS
 (
SELECT 
    ci.city_name,
   SUM (s.total) AS total_revenue, 
   Count(DISTINCT s.customer_id) AS total_cx,
   Round (SUM (s.total)::NUMERIC / Count(DISTINCT s.customer_id)::NUMERIC ,2) AS AVG_sellpercity
FROM sales AS s 
JOIN customers AS c 
ON s.customer_id = c.customer_id
JOIN city AS ci 
ON ci.city_id = c.city_id
GROUP BY 1 
ORDER BY 2 DESC 
),

city_rent 
AS
 (
SELECT 
 city_name ,
 estimated_rent
 FROM city
  )
 
 
 
 SELECT 
  cr.city_name,
  cr.estimated_rent,
  ct.total_cx,
  ct.AVG_sellpercity, 
  round( cr.estimated_rent:: NUMERIC / ct.total_cx :: NUMERIC, 2 ) AS avg_rent_per_cx 
FROM city_rent AS cr 
JOIN city_table AS ct 
ON cr.city_name = ct.city_name 
  
  
--9. Sales Growth Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
 -- By each city 
 
 WITH monthly_sales AS (
 SELECT 
 ci.city_name,
 EXTRACT(MONTH FROM sale_date) AS "Month",
 EXTRACT(YEAR FROM sale_date ) AS "Year",
 SUM(s.total) AS total_sales
 FROM sales AS s 
 JOIN customers AS c 
 ON c.customer_id = s.customer_id
 JOIN city AS ci 
 ON ci.city_id = c.city_id 
 GROUP BY 1,2,3
 ORDER BY 1,3,2
 
),
  monthly_ratio AS (     
SELECT 
  city_name,
  "Month",
  "Year",
  total_sales AS cr_month_sale, 
  Lag(total_sales, 1) OVER(PARTITION BY city_name ORDER BY "Year", "Month" ) AS last_month_sale
FROM monthly_sales )
  
  
      
SELECT 
  city_name,
  "Month",
  "Year",
  cr_month_sale, 
  last_month_sale,
  Round((cr_month_sale -last_month_sale):: NUMERIC/last_month_sale::NUMERIC * 100 , 2) AS growth_ration
  FROM monthly_ratio
  WHERE last_month_sale IS NOT NULL 
  
 -- Q 10 .Market Potential Analysis Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
 
 WITH city_table AS
 (
SELECT 
    ci.city_name,
   SUM (s.total) AS total_revenue, 
   Count(DISTINCT s.customer_id) AS total_cx,
   Round (SUM (s.total)::NUMERIC / Count(DISTINCT s.customer_id)::NUMERIC ,2) AS AVG_sellpercity
FROM sales AS s 
JOIN customers AS c 
ON s.customer_id = c.customer_id
JOIN city AS ci 
ON ci.city_id = c.city_id
GROUP BY 1 
--order by 2 DESC 
),

city_rent 
AS
 (
    SELECT 
        city_name ,
        estimated_rent,
        Round((population * 0.25)/1000000, 3) AS esitmated_coffeeconsumer_millions 
    FROM city
  )
 
 SELECT 
  cr.city_name,
  cr.estimated_rent,
  ct.total_cx,
  ct.total_revenue,
  esitmated_coffeeconsumer_millions,
  ct.AVG_sellpercity, 
  round( cr.estimated_rent:: NUMERIC / ct.total_cx :: NUMERIC, 2 ) AS avg_rent_per_cx 
FROM city_rent AS cr 
JOIN city_table AS ct 
ON cr.city_name = ct.city_name 
ORDER BY 4 DESC 
 
  
  
 

