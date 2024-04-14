-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates 
its business in the APAC region.

gdb023
select market
from dim_customer
where customer="Atliq Exclusive" and region="APAC";


2. What is the percentage of unique product increase in 2021 vs. 2020?
 The final output contains these fields, 
 unique_products_2020 unique_products_2021 percentage_chg
 
with 
		x as(
   select count(distinct(product_code)) as unique_products_2020
   from fact_sales_monthly
   where fiscal_year=2020),
		y as (
      select count(distinct(product_code)) as unique_products_2021
   from fact_sales_monthly
   where fiscal_year=2021)
select 
x.unique_products_2020,
y.unique_products_2021,
(y.unique_products_2021-x.unique_products_2020)*100/x.unique_products_2020 as percentage_change
from x
join y


/*3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count*/

select segment,count(distinct(product)) as product_count
from dim_product
group by segment
order by product_count desc


/*4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference*/


with x as(
    select d.segment as segment,count(distinct(f.product_code)) as product_count_2020
    from dim_product d
    join fact_sales_monthly  f
    on d.product_code=f.product_code
    where f.fiscal_year=2020
    group by d.segment),
    
    y as(
    select d.segment as segment ,count(distinct(f.product_code)) as product_count_2021
    from dim_product d
    join fact_sales_monthly  f
    on d.product_code=f.product_code
	where f.fiscal_year=2021
    group by d.segment)

select x.segment,
		x.product_count_2020,
        y.product_count_2021,
        (y.product_count_2021-x.product_count_2020)*100/x.product_count_2020 as difference
from x,y 
where x.segment=y.segment


/*5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost*/

SELECT F.product_code, P.product, F.manufacturing_cost 
FROM fact_manufacturing_cost F JOIN dim_product P
ON F.product_code = P.product_code
WHERE manufacturing_cost
IN (
	SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost
    UNION
    SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost
    ) 
ORDER BY manufacturing_cost DESC ;





/*6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage*/
WITH TBL1 AS
(SELECT customer_code AS A, AVG(pre_invoice_discount_pct) AS B FROM fact_pre_invoice_deductions
WHERE fiscal_year = '2021'
GROUP BY customer_code),
     TBL2 AS
(SELECT customer_code AS C, customer AS D FROM dim_customer
WHERE market = 'India')

SELECT TBL2.C AS customer_code, TBL2.D AS customer, ROUND (TBL1.B, 4) AS average_discount_percentage
FROM TBL1 JOIN TBL2
ON TBL1.A = TBL2.C
ORDER BY average_discount_percentage DESC
LIMIT 5 



/*7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount*/

select CONCAT(MONTHNAME(f.date), ' (', YEAR(f.date), ')') AS 'Month',
       f.fiscal_year,
		sum(f.sold_quantity * p.gross_price) as gross_sales_amount
from fact_sales_monthly f
join dim_customer c on f.customer_code=c.customer_code
join fact_gross_price p on f.product_code=p.product_code
where c.customer="Atliq Exclusive"
group by Month,f.fiscal_year


/*8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity*/
select CASE
        WHEN MONTH(date) BETWEEN 9 AND 11 THEN 'Q1'
        WHEN MONTH(date) IN (12, 1, 2) THEN 'Q2'
        WHEN MONTH(date) BETWEEN 3 AND 5 THEN 'Q3'
        WHEN MONTH(date) BETWEEN 6 AND 8 THEN 'Q4'
    END AS quarter, sum(sold_quantity) as total_sales
from fact_sales_monthly
where fiscal_year=2020 
group by quarter
order by total_sales desc


/*9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage*/

WITH TotalGrossSales AS (
    SELECT d.channel,
           SUM(sold_quantity * gross_price) AS gross_sales_mln
    FROM dim_customer d
    JOIN fact_sales_monthly f ON d.customer_code = f.customer_code
    JOIN fact_gross_price g ON f.product_code = g.product_code
    WHERE d.customer_code = f.customer_code AND f.fiscal_year = 2021
    GROUP BY d.channel
)

SELECT channel,
       gross_sales_mln,
       (gross_sales_mln / SUM(gross_sales_mln) OVER ()) * 100 AS contribution_percentage
FROM TotalGrossSales
ORDER BY gross_sales_mln DESC;



/*10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order*/


WITH ProductRanking AS (
    SELECT d.division,
           d.product_code,
           d.product,
           sum(f.sold_quantity) AS total_sold_quantity,
           ROW_NUMBER() OVER (PARTITION BY d.division ORDER BY COUNT(DISTINCT f.sold_quantity) DESC) AS rank_order
    FROM dim_product d
    JOIN fact_sales_monthly f ON d.product_code = f.product_code
    WHERE f.fiscal_year = 2021
    GROUP BY d.division, d.product_code, d.product
)

SELECT division, product_code, product, total_sold_quantity, rank_order
FROM ProductRanking
WHERE rank_order <= 3
ORDER BY division, rank_order;