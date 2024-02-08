 /*
1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region. */

SELECT DISTINCT(market)
FROM dim_customer
WHERE customer = "Atliq Exclusive" and region = "APAC";

/*
2. What is the percentage of unique product increase in 2021 vs. 2020? */

WITH  uniqueproducts AS (

SELECT fiscal_year,COUNT(DISTINCT product_code) as unique_products 
FROM  fact_gross_price 
GROUP BY  fiscal_year 
) 
SELECT
    UP2020.unique_products AS unique_products_2020,
    UP2021.unique_products AS unique_products_2021,
    ROUND(((UP2021.unique_products - UP2020.unique_products) / UP2020.unique_products) * 100, 2) AS percentage_change
    
FROM uniqueproducts UP2020
CROSS JOIN uniqueproducts UP2021
WHERE UP2020.fiscal_year = 2020 AND UP2021.fiscal_year = 2021;

/*
3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. */

SELECT COUNT(DISTINCT product_code) as product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC ;

/*
4. Which segment had the most increase in unique products in 2021 vs 2020?  */

WITH  segment_product_count AS (

SELECT p.segment , fs.fiscal_year , COUNT(DISTINCT(p.product_code)) as product_count 
FROM dim_product p
JOIN  fact_sales_monthly fs
ON p.product_code = fs.product_code
GROUP BY segment,fiscal_year 
)

SELECT 
	SP2021.segment, SP2020.product_count AS product_count_2020,
	SP2021.product_count AS product_count_2021,
    (SP2021.product_count - SP2020.product_count) AS difference
    
FROM segment_product_count SP2020
JOIN segment_product_count SP2021 
ON   SP2020.segment = SP2021.segment

WHERE SP2020.fiscal_year = 2020 AND SP2021.fiscal_year = 2021
ORDER BY difference DESC;

/*
5. Get the products that have the highest and lowest manufacturing costs. */

-- Highest Manufacturing cost product

SELECT p.product, p.variant,	fm.manufacturing_cost
FROM fact_manufacturing_cost fm
JOIN  dim_product p
ON p.product_code = fm.product_code
WHERE fm.manufacturing_cost = (SELECT MAX(fm.manufacturing_cost) FROM fact_manufacturing_cost) 
ORDER BY fm.manufacturing_cost DESC
LIMIT 1;

-- Lowerst Manufacturing cost product

SELECT p.product, p.variant,	fm.manufacturing_cost
FROM fact_manufacturing_cost fm
JOIN  dim_product p
ON p.product_code = fm.product_code
WHERE fm.manufacturing_cost = (SELECT MIN(fm.manufacturing_cost) FROM fact_manufacturing_cost) 
ORDER BY fm.manufacturing_cost 
LIMIT 1;
 
/*
6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year
   2021 and in the Indian market.
*/
   
SELECT  c.customer , ROUND(AVG(fpd.pre_invoice_discount_pct)*100,2)  as pre_invoice_discount_pct
FROM dim_customer c
JOIN fact_pre_invoice_deductions fpd
ON fpd.customer_code = c.customer_code
WHERE fpd.fiscal_year = 2021 and c.market = "India "
GROUP BY c.customer ,c.customer_code
ORDER BY pre_invoice_discount_pct  DESC
LIMIT 5 ;



/*
7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get
   an idea of low and high-performing months and take strategic decisions.
*/

SELECT  MONTHNAME(date) AS Month_name, YEAR(date) AS Year_value,
		CONCAT("$ ",ROUND(SUM(fgp.gross_price * fs.sold_quantity) / 1000000 , 2), " M") AS  gross_amount 
FROM fact_sales_monthly fs 
JOIN fact_gross_price fgp
ON fgp.product_code  = fs.product_code
AND fgp.fiscal_year = fs.fiscal_year
JOIN dim_customer c 
ON c.customer_code = fs.customer_code
WHERE c.customer = "Atliq Exclusive" 
GROUP BY Month_name , Year_value
ORDER BY Year_value;

   
   
/* 8. In which quarter of 2020, got the maximum total_sold_quantity? */

-- In Atliq hardware first financial month is September

SELECT
	CASE
		WHEN MONTH(date) IN (9, 10, 11) THEN "Q1"
        WHEN MONTH(date) IN (12, 1, 2)  THEN "Q2"
        WHEN MONTH(date) IN (3, 4, 5) 	THEN "Q3"
        ELSE "Q4"
	END AS Quarter  , SUM(sold_quantity) as Total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarter 
ORDER BY Total_sold_quantity DESC;

/*
9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? */

WITH sales_per_channel AS (
SELECT c.channel AS channels  , ROUND(SUM(fgp.gross_price * fs.sold_quantity)/1000000, 2) AS  gross_amount 
FROM fact_sales_monthly fs 
JOIN fact_gross_price fgp
ON fs.product_code = fgp.product_code 
AND fs.fiscal_year = fgp.fiscal_year
JOIN dim_customer c
ON fs.customer_code = c.customer_code
WHERE fs.fiscal_year = 2021
GROUP BY channels 
) 
SELECT channels, CONCAT('$',gross_amount, " M") AS gross_amount,
	   CONCAT(ROUND(gross_amount/ (SUM(gross_amount) OVER())*100,2),'%') AS percentage
FROM sales_per_channel
ORDER BY percentage DESC;


/* 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? */

WITH sold_products AS  (

SELECT  p.product_code, p.product  ,p.division, SUM(fs.sold_quantity) AS total_quantity
FROM dim_product p
JOIN fact_sales_monthly fs
ON fs.product_code = p.product_code
WHERE fs.fiscal_year = "2021"
GROUP BY p.product_code, p.product,p.division
ORDER BY total_quantity DESC
),

top_sold_products_per_division AS (

SELECT division, product_code  , product , total_quantity,
		DENSE_RANK() OVER(PARTITION BY division ORDER BY total_quantity DESC ) as rank_order 
FROM sold_products 
)
SELECT * FROM  top_sold_products_per_division
WHERE rank_order <= 3;

	

