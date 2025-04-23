-- Which date corresponds to the highest number of sales?
-- Find out the postcode with the highest average price per sale?
-- Which year witnessed the lowest number of sales?
-- The top six postcodes by year's price?

CREATE TABLE property_sales (date_sold DATE, post_code INT, price INT, property_type VARCHAR(50), bedrooms INT);

---------------------------------------------------------------------------------------------------------------------
-- DUPLICATE DATE SEARCH, RESULTED = NONE
select *, COUNT(*)
from property_sales 
group by date_sold, post_code, price, property_type, bedrooms
having COUNT(*) > 1;

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

-- WHICH DATE CORRESPONDS TO THE HIGHEST NUMBER OF SALES?

-- HISTORICAL MONTHLY PERFORMANCE
SELECT 
	  MONTHNAME(date_sold) AS MONTH,
	  count(date_sold) AS TOTAL_SOLD,
      CONCAT(ROUND(AVG(PRICE),2),'$') AS AVG_PRICE,
      CONCAT(MAX(PRICE), '$') AS HIGHEST_SOLD_PRICE,
      DENSE_RANK () OVER ( ORDER BY COUNT(DATE_SOLD) DESC) AS TOTAL_SOLD_RANK
FROM property_sales
GROUP BY   MONTHNAME(date_sold);

-- RUNNING TOTAL SOLD AND IT'S SUM_PRICE

WITH CTE_SUM_PRICE AS (
SELECT 
      YEAR(DATE_SOLD) AS YEARS,
      COUNT(DATE_SOLD) AS TOTAL_SOLD,
      SUM(PRICE) AS SUM_PRICE
FROM PROPERTY_SALES
GROUP BY YEAR(DATE_SOLD)
)
SELECT 
       YEARS,
       TOTAL_SOLD,
       SUM_PRICE,
       SUM(SUM_PRICE) OVER (ORDER BY YEARS) AS RUNNING_TOTAL
FROM CTE_SUM_PRICE;
 
-- HISTORICAL YEARLY PERFORMANCE

SELECT 
      YEAR (DATE_SOLD) AS YEAR,
      COUNT(DATE_SOLD) AS TOTAL_SOLD,
      SUM(COUNT(DATE_SOLD)) OVER (ORDER BY YEAR(DATE_SOLD)) AS CUMULATIVE_SOLD,
      CONCAT(SUM(PRICE), '$') AS TOTAL_SALES,
      CONCAT(ROUND(AVG(PRICE),2), '$') AS AVG_PRICE,
      CONCAT(SUM(SUM(PRICE)) OVER (ORDER BY YEAR(DATE_SOLD)), '$') AS CUMULATIVE_SOLD_PRICE,
	  CONCAT(ROUND((count(date_sold) - LAG(COUNT(DATE_SOLD)) OVER (order by year(date_sold) asc)) / LAG(COUNT(DATE_SOLD)) OVER (order by year(date_sold) asc) * 100,2),'%') AS 'diff'
FROM property_sales
GROUP BY YEAR(DATE_SOLD);

-- OVERALL HISTORICAL PERFORMANCE

SELECT 
      YEAR (DATE_SOLD) AS YEAR,
      QUARTER(DATE_SOLD) AS QUARTER,
      MONTHNAME(DATE_SOLD) AS MONTH,
      COUNT(DATE_SOLD) AS TOTAL_SOLD,
      CONCAT(SUM(PRICE), '$') AS TOTAL_SALES,
      CONCAT(ROUND(AVG(PRICE),2), '$') AS AVG_PRICE,
      CONCAT(MAX(PRICE), '$') AS HIGHEST_SOLD_PRICE,
	  CONCAT(ROUND((count(date_sold) - LAG(COUNT(DATE_SOLD)) OVER (order by year(date_sold) asc)) / LAG(COUNT(DATE_SOLD)) OVER (order by year(date_sold) asc) * 100,2),'%') AS 'CHANGES'
FROM property_sales
GROUP BY YEAR(DATE_SOLD), MONTHNAME(DATE_SOLD), QUARTER(DATE_SOLD);


SELECT 
      YEAR (DATE_SOLD) AS YEAR,
      QUARTER(DATE_SOLD) AS QUARTER,
      MONTHNAME(DATE_SOLD) AS MONTH,
      COUNT(DATE_SOLD) AS TOTAL_SOLD,
      SUM(PRICE) AS TOTAL_SALES,
      AVG(PRICE) AS AVG_PRICE,
      MAX(PRICE)AS HIGHEST_SOLD_PRICE,
	 property_type
FROM property_sales
GROUP BY YEAR(DATE_SOLD), MONTHNAME(DATE_SOLD), QUARTER(DATE_SOLD), property_type;
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

-- postcode with the highest average price per sale

-- 1. RANK OF AVG_PRICE BY POST_CODE

SELECT 
      post_code AS POST_CODE,
      COUNT(date_sold),
      CONCAT(ROUND(AVG(PRICE),2),'$') AS AVG_PRICE,
      DENSE_RANK () OVER (ORDER BY COUNT(DATE_SOLD) DESC) AS RANK_BY_TOTAL_SOLD,
      DENSE_RANK () OVER (ORDER BY AVG(PRICE) DESC) AS RANK_BY_AVG_PRICE      
FROM property_sales
GROUP BY post_code;

-- 2. HISTORICAL YEARLY SALES BY POST_CODE

SELECT 
       post_code, 
       year(date_sold),
       COUNT(date_sold), 
       CONCAT(ROUND(AVG(PRICE),2), '$') AS AVG_PRICE, 
       CONCAT(SUM(PRICE), '$') AS TOTAL_SALES,
       CONCAT(MAX(PRICE), '$') AS HIGHEST_PRICE,
       DENSE_RANK () OVER (PARTITION BY YEAR(date_sold) ORDER BY YEAR(DATE_SOLD) DESC) AS RANK_NUM 
FROM property_sales 
GROUP BY YEAR(date_sold), post_code;

-- 3. SEARCH RANK OF AVG_PRICE AND TOTAL_SOLD BY POST_CODE

WITH cte_avg_price AS (
SELECT 
      post_code AS POST_CODE,
      COUNT(date_sold) AS TOTAL_SOLD,
      CONCAT(ROUND(AVG(PRICE),2),'$') AS AVG_PRICE,
      ROW_NUMBER () OVER (ORDER BY AVG(PRICE) DESC) AS AVG_PRICE_RANK,
      ROW_NUMBER () OVER (ORDER BY COUNT(date_sold) DESC) AS TOTAL_SOLD_RANK
FROM property_sales
GROUP BY post_code
)
SELECT 
      POST_CODE,
      AVG_PRICE,
      TOTAL_SOLD
FROM cte_avg_price
WHERE AVG_PRICE_RANK = 1 OR TOTAL_SOLD_RANK = 1;

-- 4. PROPERTY SALES ABOVE AVGERAGE PRICE

WITH cte_avg_price AS (
SELECT 
      AVG(PRICE) AS AVG_PRICE
FROM property_sales 
)
SELECT 
      YEAR(DATE_SOLD),
      -- property_type,
      SUM(CASE WHEN PRICE > AVG_PRICE THEN 1 ELSE 0 END) AS SOLD_ABOVE_AVG,
      CONCAT(ROUND(SUM(CASE WHEN PRICE > AVG_PRICE THEN 1 ELSE 0 END) / COUNT(PRICE) * 100,2), '%') AS PERCENTAGE_OF_TOTAL
FROM property_sales
JOIN cte_avg_price
GROUP BY YEAR(DATE_SOLD); -- ,property_type 

-- 5. PROPERTY TYPE SOLD DISTRIBUTION

WITH cte_house AS (
SELECT 
      COUNT(property_type) AS house_type
FROM property_sales
WHERE property_type = 'house'
), 
cte_unit AS (
SELECT 
      COUNT(property_type) AS unit_type
FROM property_sales
WHERE property_type = 'unit'
),
cte_count AS (
SELECT 
      COUNT(property_type) AS TOTAL_PROPERTY
FROM property_sales
)
SELECT 
      DISTINCT(property_type),
      COUNT(property_type) AS PROPERTY_COUNT,
      CASE 
      WHEN PROPERTY_TYPE = 'HOUSE' THEN CONCAT(ROUND(HOUSE_TYPE / TOTAL_PROPERTY * 100,2),'%') 
      WHEN PROPERTY_TYPE = 'UNIT' THEN CONCAT(ROUND(UNIT_TYPE / TOTAL_PROPERTY * 100,2),'%') 
      ELSE NULL
      END AS PERCENTAGE_OF_TOTAL
FROM property_sales
JOIN cte_house
JOIN cte_unit
JOIN cte_count
GROUP BY   property_type,HOUSE_TYPE, UNIT_TYPE, TOTAL_PROPERTY;

-- 5. BEDROOM TYPE SALES BY POST_CODE

SELECT 
	  DISTINCT(BEDROOMS) AS BEDROOM_TYPE,
      POST_CODE,
      COUNT(DATE_SOLD) AS TOTAL_SOLD,
      AVG(PRICE) AS AVG_PRICE,
      DENSE_RANK () OVER (PARTITION BY bedroomS ORDER BY AVG(PRICE) DESC) AS RANK_NUM_AVG_PRICE,
      DENSE_RANK () OVER (PARTITION BY bedroomS ORDER BY COUNT(DATE_SOLD) DESC) AS RANK_NUM_TOTAL_SOLD
FROM 
	property_sales
GROUP BY BEDROOMS, POST_CODE;

      
----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------

--  Top six postcodes by year's price.

WITH cte_row_num AS (
SELECT 
	  DISTINCT(POST_CODE),
      YEAR(DATE_SOLD),
      COUNT(DATE_SOLD),
      SUM(PRICE),
      DENSE_RANK () OVER (PARTITION BY YEAR(DATE_SOLD) ORDER BY SUM(PRICE)DESC) AS RANK_NUM 
      FROM property_sales 
      GROUP BY YEAR(DATE_SOLD), POST_CODE
)
SELECT *
FROM CTE_ROW_NUM
WHERE RANK_NUM BETWEEN 1 AND 6;

---------------------------------------------------------------------------------------------------------
-- 1. Overall sales data combined
SELECT 
      YEAR (DATE_SOLD) AS YEAR,
      QUARTER(DATE_SOLD) AS QUARTER,
      MONTHNAME(DATE_SOLD) AS MONTH,
      POST_CODE,
      COUNT(DATE_SOLD) AS TOTAL_SOLD,
      SUM(PRICE) AS TOTAL_SALES,
      AVG(PRICE) AS AVG_PRICE,
      MAX(PRICE)AS HIGHEST_SOLD_PRICE,
	  PROPERTY_TYPE,
      ROW_NUMBER () OVER (PARTITION BY YEAR(DATE_SOLD) ORDER BY MONTHNAME(DATE_SOLD)) AS ROW_NUM
FROM property_sales
GROUP BY YEAR(DATE_SOLD), MONTHNAME(DATE_SOLD), QUARTER(DATE_SOLD), POST_CODE,property_type;
      
----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
 
-- 1. procedure for searching property_sold info by date
DELIMITER $$
CREATE PROCEDURE p1_property_info_by_date_sold (IN P_DATE_SOLD DATE)
BEGIN 
     SELECT 
		   POST_CODE,
           PROPERTY_TYPE,
           PRICE,
           BEDROOMS
	FROM 
        PROPERTY_SALES P
        WHERE P.DATE_SOLD = P_DATE_SOLD;
END $$
DELIMITER ; 

-- 2. procedure for finding avg_price for post_code through years
DELIMITER $$
CREATE PROCEDURE p_avg_price_year (IN P_POST_CODE INT)
BEGIN 
     SELECT 
           POST_CODE,
           YEAR(DATE_SOLD),
           CONCAT(ROUND(AVG(PRICE),2),'$')
	 FROM PROPERTY_SALES P
     WHERE P.POST_CODE = P_POST_CODE 
     GROUP BY POST_CODE, YEAR(DATE_SOLD);
END $$
DELIMITER ;

-- 3. procedure for finding total_sales by post_code covering total_property sold, total_price of the sold, and yearly percentage changes in total_revenue
DELIMITER $$
CREATE PROCEDURE p_yearly_sales_by_post_code (IN P_POST_CODE INT)
BEGIN 
     WITH CTE_AVG AS (
SELECT 
		POST_CODE AS POST_CODE,
		YEAR(DATE_SOLD) AS DATE_SOLD,
		SUM(PRICE) AS SUM_PRICE,
		COUNT(DATE_SOLD) AS TOTAL_SOLD,
		CONCAT(ROUND(AVG(PRICE),2),'$') AS AVG_PRICE
           
FROM PROPERTY_SALES P
GROUP BY POST_CODE, YEAR(DATE_SOLD) )
     
SELECT 
		C.POST_CODE,
		C.DATE_SOLD,
		TOTAL_SOLD,
		SUM_PRICE,
		AVG_PRICE,
		CONCAT(ROUND((SUM_PRICE - LAG(SUM_PRICE) OVER (ORDER BY C.DATE_SOLD )) / LAG(SUM_PRICE) OVER (ORDER BY C.DATE_SOLD) * 100,2),'%') AS YEARLY_SALES_CHANGES
FROM CTE_AVG C
JOIN property_sales
WHERE P_POST_CODE = C.POST_CODE
GROUP BY 
        POST_CODE,
		DATE_SOLD,
		SUM_PRICE,
		TOTAL_SOLD;
END $$
DELIMITER ;

-- 4. procedure for searching info on last property_sold by post_code
DELIMITER $$
CREATE PROCEDURE p_last_sold_date_info (IN p_post_code INT)
BEGIN 
     SELECT 
           MAX(DATE_SOLD),
           PRICE,
           PROPERTY_TYPE,
           BEDROOMS
		FROM PROPERTY_SALES P
        WHERE P.POST_CODE = P_POST_CODE
        GROUP BY  PRICE, PROPERTY_TYPE, BEDROOMS
        ORDER BY MAX(DATE_SOLD) DESC
        LIMIT 1;
        
END $$
DELIMITER ;
