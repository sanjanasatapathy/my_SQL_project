-- SQL porfolio project.
CREATE DATABASE credit_card_transaction;
USE credit_card_transaction;

SELECT *
FROM credit_card_transaction;

-- solve below questions
-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
WITH cte as(
SELECT city,
SUM(amount) as total_spends, 
DENSE_RANK() OVER (ORDER BY sum(amount) DESC) as credit_spends
FROM credit_card_transaction
GROUP BY city
)
SELECT city, total_spends , ROUND((total_spends / sum(total_spends) OVER() )*100, 2) as percentage
FROM cte
WHERE credit_spends<= 5;



-- 2- write a query to print highest spend month and amount spent in that month for each card type
WITH cte AS (
    SELECT
        card_type,
        YEAR(transaction_date) AS yt,
        MONTH(transaction_date) AS mt,
        SUM(amount) AS total_spend
    FROM
        credit_card_transaction
    GROUP BY
        card_type,
        YEAR(transaction_date),
        MONTH(transaction_date)
)
SELECT
    *
FROM (
    SELECT
        *,
        RANK() OVER (PARTITION BY card_type ORDER BY total_spend DESC) AS rn
    FROM
        cte
) a
WHERE
    rn = 1;

-- 3- write a query to print the transaction details(all columns from the table) for each card type when
	-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
WITH cte as(
SELECT *, 
SUM(amount) OVER (PARTITION BY card_type ORDER BY transaction_date,transaction_id)as total_spend
FROM credit_card_transaction
ORDER BY card_type,total_spend  
)
SELECT *
FROM( SELECT *, Rank() OVER (PARTITION BY card_type ORDER BY total_spend) as rn
FROM cte
WHERE total_spend>=1000000) as abc
WHERE rn = 1;

-- 4- write a query to find city which had lowest percentage spend for gold card type
WITH cte as(
SELECT *, 
SUM(amount) OVER (PARTITION BY card_type ORDER BY transaction_date,transaction_id)as total_spend
FROM credit_card_transaction
ORDER BY card_type,total_spend  
)
SELECT *
FROM( SELECT *, Rank() OVER (PARTITION BY card_type ORDER BY total_spend desc) as rn
FROM cte
WHERE total_spend>=1000000) as abc
WHERE card_type = "Gold" AND rn = 1;


-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

WITH cte AS (
    SELECT
        city,
        exp_type,
        SUM(amount) AS total_amount
    FROM
        credit_card_transaction
    GROUP BY
        city,
        exp_type
)
SELECT
    city,
    MAX(CASE WHEN rn_desc = 1 THEN exp_type END) AS highest_expense_type,
    MIN(CASE WHEN rn_asc = 1 THEN exp_type END) AS lowest_expense_type
FROM (
    SELECT
        city,
        exp_type,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY total_amount DESC) AS rn_desc,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY total_amount ASC) AS rn_asc
    FROM
        cte
) A
GROUP BY
    city;

-- 6- write a query to find percentage contribution of spends by females for each expense type
SELECT exp_type,
SUM(case when gender='F' then amount else 0 end)*1.0/sum(amount) as percentage_female_contribution
FROM credit_card_transaction
GROUP BY exp_type
ORDER BY percentage_female_contribution desc;
-- 7- which card and expense type combination saw highest month over month growth in Jan-2014
WITH cte AS (
    SELECT
        card_type,
        exp_type,
        YEAR(transaction_date) AS yt,
        MONTH(transaction_date) AS mt,
        SUM(amount) AS total_spend
    FROM
        credit_card_transaction
    GROUP BY
        card_type,
        exp_type,
        YEAR(transaction_date),
        MONTH(transaction_date)
)
SELECT
    A.*,
    (A.total_spend - B.total_spend) AS mom_growth
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY total_spend DESC) AS row_num
    FROM
        cte
    WHERE
        yt = 2014
        AND mt = 1
) A
JOIN (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY total_spend DESC) AS row_num
    FROM
        cte
    WHERE
        yt = 2014
        AND mt = 1
) B ON A.row_num = B.row_num + 1;


-- 8- during weekends which city has highest total spend to total no of transcations ratio 
SELECT
    city,
    SUM(amount) / COUNT(*) AS ratio
FROM
    credit_card_transaction
WHERE
    DAYOFWEEK(transaction_date) IN (1, 7)
GROUP BY
    city
ORDER BY
    ratio DESC
LIMIT 1;

-- 9- which city took least number of days to reach its 500th transaction after the first transaction in that city
WITH cte as (
SELECT *,
ROW_NUMBER() OVER(PARTITION BY city ORDER BY transaction_date,transaction_id) as rn
from credit_card_transaction
)
SELECT city, datediff(max(transaction_date),min(transaction_date)) as datediff1
FROM cte
WHERE rn=1 or rn=500
GROUP BY city
HAVING count(1)=2
ORDER BY datediff1;