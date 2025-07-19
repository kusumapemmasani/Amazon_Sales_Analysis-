-- Amazon Sales Analysis 
-- Overview of data set--

/* OBJECTIVE: 
The main aim of the project is to get some insights from the sales data of Amazon and
 also be able to uderstand how different factores are affecting sales of different branches. */ 

/* Creating the DataBase With name of 'amazon' and also a table staructure that includes 17 columns 
given in the source dataset. */

create database amazon;
use amazon;
SHOW databases;

CREATE TABLE amazon_sales (
    invoice_id VARCHAR(30) NOT NULL,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL,
    tax_5_percent DECIMAL(6, 4) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    date DATE NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(20) NOT NULL,
    cogs DECIMAL(10, 2) NOT NULL,
    gross_margin_percentage FLOAT NOT NULL,
    gross_income DECIMAL(10, 2) NOT NULL,
    rating FLOAT NOT NULL
);
describe amazon_sales;

/* 1. DATA WRANLING: Importing the data using 'table data import wizard and checking the data type */

select * from amazon_sales;
describe amazon_sales;

/*.Ensure there are no NULL values */

SELECT count(*) AS count_of_null_values
FROM amazon_sales
WHERE 
    invoice_id IS NULL 
    OR branch IS NULL
    OR city IS NULL
    OR customer_type IS NULL
    OR gender IS NULL
    OR product_line IS NULL
    OR unit_price IS NULL
    OR quantity IS NULL
    OR tax_5_percent IS NULL
    OR total IS NULL
    OR date IS NULL
    OR time IS NULL
    OR payment IS NULL
    OR cogs IS NULL
    OR gross_margin_percentage IS NULL
    OR gross_income IS NULL
    OR rating IS NULL;

/* 2.FEATURE ENGINEERING: added the new columns i.e. time_of_day, day_name, month_name as required
 with the helo of time and date columns.
 USE: It is easy to understand the sales on different factors.*/
 
-- Adding the new column time_of_day
ALTER TABLE amazon_sales
ADD time_of_day VARCHAR(15) NOT NULL;

SET SQL_SAFE_UPDATES=0;
-- Updating the time_of_day column based on the time values
UPDATE amazon_sales
SET time_of_day = 
CASE
WHEN HOUR(time) BETWEEN 06 AND 12 THEN 'Morning'
WHEN HOUR(time) BETWEEN 12 AND 18 THEN 'Afternoon'
ELSE 'Evening'
END;

-- Adding new column dayname that contains days of the week on which the transaction took place. 
ALTER TABLE amazon_sales
ADD day_name VARCHAR(10) NOT NULL;

UPDATE amazon_sales
SET day_name = DAYNAME(date);

-- Adding new column dayname that extracts month of the year. 

ALTER TABLE amazon_sales
ADD month_name VARCHAR(10) NOT NULL;

UPDATE amazon_sales
SET month_name = MONTHNAME(date);

select * from amazon_sales limit 10;

SET SQL_SAFE_UPDATES=1;

/* SQL queries fri Business Questions */

-- 1. What is the count of distinct cities in the dataset? --
select count(distinct city) as cities from amazon_sales;

-- 2. For each branch, what is the corresponding city? --
SELECT distinct branch, city
FROM amazon_sales;

-- 3. What is the count of distinct product lines in the dataset? --
select count(distinct product_line) as productline from amazon_sales;

-- 4. Which payment method occurs most frequently?
SELECT payment, COUNT(payment) AS payment_count
FROM amazon_sales
GROUP BY payment
ORDER BY payment_count DESC;

-- 5. Which product line has the highest sales?

SELECT product_line, SUM(total) AS total_sales
FROM amazon_sales
GROUP BY product_line
ORDER BY total_sales DESC
LIMIT 1;

-- 6. How much revenue is generated each month?
select month_name,sum(total) as monthly_revenue
from amazon_sales
group by month_name
order by monthly_revenue desc;

-- 7. In which month did the cost of goods sold reach its peak?
select month_name,sum(cogs) as cost_of_goods_sold from amazon_sales
group by month_name 
order by cost_of_goods_sold desc;

-- 8. Which product line generated the highest revenue?
SELECT product_line, sum(total) as total_revenue from amazon_sales
group by product_line
order by total_revenue desc;
/* output: among 6 unique product line,food and beverages received the highest revenue in total*/

-- 9.In which city was the highest revenue recorded?
select city,sum(total) as high_revenue from amazon_sales
group by city
order by high_revenue desc;  
/* OUTPUT: amaong 3 unique cities, Naypyitaw has received the collection of hihest revenue */

-- 10. Which product line incurred the highest Value Added Tax?
select product_line,SUM(tax_5_percent) as total_vat from amazon_sales
group by product_line
order by total_vat desc;

-- 11. For each product line, add a column indicating "Good" if its sales are above average, otherwise "Bad."
select product_line,sum(total) as revenue,
case
when sum(total) > (select avg(total) from amazon_sales) then 'Good'
else 'Bad'
end as sales_performance from amazon_sales
group by product_line;

-- 12. Identify the branch that exceeded the average number of products sold.
select branch,sum(quantity) as product_sold from amazon_sales
group by branch
having product_sold > (select avg(quantity) from amazon_sales);
/* OUTPUT: all three branches have exceededbthe average number of products sold */

-- 13. Which product line is most frequently associated with each gender?
with prod_line_freq as (
select gender,product_line,count(*) as prod_line_count,
rank() over(partition by gender order by count(*) desc) as rank_num from amazon_sales
group by gender,product_line)
select gender,product_line,prod_line_count from prod_line_freq 
where rank_num=1;

-- 14. Calculate the average rating for each product line.
select product_line,avg(rating) as avg_rating from amazon_sales
group by product_line;
/* OUTPUT: Food and beverages get the highest avg rating followed by Fashion accessories and Health and beauty*/

-- 15.Count the sales occurrences for each time of day on every weekday.
select day_name, time_of_day, count(*) as sales_count
from amazon_sales
group by day_name,time_of_day
order by field(day_name, 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'),
field(time_of_day, 'Morning', 'Afternoon', 'Evening');
/*OUTPUT: every weekday most sales occur duirng the afternoon */

-- 16. Identify the customer type contributing the highest revenue.
select customer_type,sum(total) as revenue from amazon_sales
group by customer_type
order by revenue desc;
/*OUTPUT: out of two customer type, member customers contributed highest in the revenue. */

-- 17. Determine the city with the highest VAT percentage.
select city, max(tax_5_percent) as vat_percentage from amazon_sales
group by city
order by vat_percentage desc;

-- 18. Identify the customer type with the highest VAT payments.
SELECT customer_type, SUM(tax_5_percent) AS total_vat
FROM amazon_sales                   
GROUP BY customer_type
ORDER BY total_vat DESC
LIMIT 1;
/* OUTPUT: we can say, Member customers contribute maximun to the revenu and 
it's obvious that they pay more than normal customers */

-- 19. What is the count of distinct customer types in the dataset?
select count(distinct(customer_type)) as count_distinct_customer_type from amazon_sales;
/* there are 2 types of customer 1. member 1.normal*/

-- 20. What is the count of distinct payment methods in the dataset?
select count(distinct(payment)) as count_distinct_payment from amazon_sales;
/* there are 3 distinct types of payment methods - 	Ewallet, Cash, Credit Card */

-- 21. Which customer type occurs most frequently?
select customer_type,count(*) as count from amazon_sales
group by customer_type
order by count desc;
/* Member customer_type occurred more frequently */

-- 22.Identify the customer type with the highest purchase frequency.
select customer_type, sum(total) as purchase_frequency from amazon_sales
group by customer_type
order by sum(total) desc;
/*  Member customer_type purchased items more frequently */

-- 23. Determine the predominant gender among customers.
select gender, count(*) as count from amazon_sales
group by gender order by count desc;

-- 24. Examine the distribution of genders within each branch.
select branch, gender, count(gender) as gender_count from amazon_sales
group by branch,gender
order by branch,gender_count desc;
/* In branch A nd B males are prominent whereas in branch c female contributes more */

-- 25. Identify the time of day when customers provide the most ratings.
select time_of_day,count(rating) as rating_count from amazon_sales
group by time_of_day
order by rating_count desc;

-- 26. Determine the time of day with the highest customer ratings for each branch.
select branch, time_of_day, count(rating) as highest_rating from amazon_sales
group by branch,time_of_day
order by branch desc;


-- 27. Identify the day of the week with the highest average ratings.
select day_name, avg(rating) as avg_rating from amazon_sales
group by day_name
order by avg_rating desc;

-- 28. Determine the day of the week with the highest average ratings for each branch.
with branch_high_avg_rating as (
select branch, day_name, avg(rating) as avg_rating,
rank() over(partition by branch order by avg(rating) desc) as rank_num from amazon_sales
group by branch, day_name)
select branch, day_name, avg_rating
from branch_high_avg_rating where rank_num=1;
/* fro branch B, Monday is the day which gets highest avg rating and 
for branches A and C it is Friday */

-- Key Findings 
/* Product Analysis : 
1. There are 6 product lines in total : Health and beauty
                                        Electronic accessories
                                        Home and Lifestyle
                                        Sports and Travel
                                        Food and beverages
                                        Fashion accessories
2. Product line with :
Highest Revenue : Food and beverages with 56145.96
Lowest Revenue  : Health and beauty with 49193.96
Highest vat     : Food and beverages with 2673.5640
Loest vat       : Health and beauty with 2342.55
Highest sales	: Electronic accessories		*/

/* SALES Analysis :
Month with highest Revenue : January with 116292.11
Month with lowest Revenue : February with 92589
City,branch with Highest Revenue: Napyitaw[C] i.e. 110568.86
City,branch with lowest Revenue: Napyitaw[C] i.e. 106198.00
Highest sales : Afternoon
MOost used payment method : EWALLET */

/* Customer Analysis: 
There are 2 cusromer types : member (predominant customer type,highest revenue)
							 normal
Most Predominent Gender : Female 
product line (popular for male): Health and beauty 
product line (popular for female): Fashion accessories
Gender with highest revenue : Female have contributed more to revenue (but not much difference) */


/* Suggestions / Recommendations :

-- As january month has highest revenue generated and also highest sales recorded ,
providing vast Diverse options for all customer types and implementing few effective strategies will help.

-- Announcements of offers,new products or campaigns during afterenoon playa s crucial role for sales, as aftrenoon has peak sales hours.

-- Health and beauty products is least performing ,
so providing a new effective plan and need to give more attention to this product line.

--  Member type customers have been contributed more to revenue, likely due to the benefits or offeres
 available to then.
 Developing a strategy to promote memberships among more customers to lower costs for acquiring new 
 customers while boosting overall revenue. */ 
                                        
                                        
                                        