use [portfolioProject];
-- inspecting the data
select * from [dbo].[sales_data.csv];


--Checking unique value from the data
SELECT DISTINCT STATUS FROM [dbo].[sales_data.csv]; --plot
SELECT DISTINCT YEAR_ID FROM [dbo].[sales_data.csv];
SELECT DISTINCT PRODUCTLINE FROM [dbo].[sales_data.csv];
SELECT DISTINCT COUNTRY FROM [dbo].[sales_data.csv]; --plot
SELECT DISTINCT DEALSIZE FROM [dbo].[sales_data.csv]; --plot
SELECT DISTINCT TERRITORY FROM [dbo].[sales_data.csv];--plot


--ANALYSIS
--grouping sales data by product line
SELECT PRODUCTLINE,SUM(SALES) as REVANUE
FROM [dbo].[sales_data.csv]
GROUP BY PRODUCTLINE
order by 2 desc;

-- sales data by group by year
SELECT YEAR_ID,SUM(SALES) as REVANUE
FROM [dbo].[sales_data.csv]
GROUP BY YEAR_ID
order by 2 desc;

-- sales data by group by dealsize
SELECT DEALSIZE,SUM(SALES) as REVANUE
FROM [dbo].[sales_data.csv]
GROUP BY DEALSIZE
order by 2 desc;

-- best month of sales in a specific year
SELECT YEAR_ID,MONTH_ID,sum(SALES) REVANUE
FROM [dbo].[sales_data.csv]
group by YEAR_ID,MONTH_ID
order by 1,2;

--year 2003
SELECT YEAR_ID,MONTH_ID,sum(SALES) REVANUE,
COUNT(ORDERNUMBER) as ORDERS
FROM [dbo].[sales_data.csv]
group by YEAR_ID,MONTH_ID
having YEAR_ID=2003 -- change the year
order by 3 desc;

--Year 2004
SELECT YEAR_ID,MONTH_ID,sum(SALES) REVANUE,
COUNT(ORDERNUMBER) as ORDERS
FROM [dbo].[sales_data.csv]
group by YEAR_ID,MONTH_ID
having YEAR_ID=2004 -- change the year
order by 3 desc;

--November seems to be the best month so what product they sell the most in november
--2003
SELECT PRODUCTLINE,sum(SALES) REVANUE,
COUNT(ORDERNUMBER) as ORDERS
FROM [dbo].[sales_data.csv]
where YEAR_ID=2003 AND MONTH_ID=11
group by MONTH_ID,PRODUCTLINE
order by 3 desc;

--2004
SELECT PRODUCTLINE,sum(SALES) REVANUE,
COUNT(ORDERNUMBER) as ORDERS
FROM [dbo].[sales_data.csv]
where YEAR_ID=2004 AND MONTH_ID=11
group by MONTH_ID,PRODUCTLINE
order by 3 desc;


-- Who is our best coustomer 


select SUM(QUANTITYORDERED) total_Quantity,COUNT(ORDERLINENUMBER) as NUMBER_OF_TIME_ORDERED,
SUM(SALES) as TOTAL_SPEND,
MAX(ORDERDATE) last_ORDER,
CUSTOMERNAME
from [dbo].[sales_data.csv]
GROUP BY CUSTOMERNAME
order by 3 desc
;
-- TWo best customer are
--1 Euro Shopping Channel (Total Spend 912294.110473633,last order date 2005-05-31 00:00:00.0000000 ,total order 9327)
--2 Mini Gifts Distributors Ltd. (Total Spend 654858.058105469 ,last order date 2005-05-29 00:00:00.0000000, total order 6366)


-- Who is our best coustomer (RFM ANALYSIS) 
--RECENCY (LAST ORDER DATE)
--FREQUENCY (COUNT OF TOTAL ORDER)
--MONETARY (TOTAL SPEND)
DROP TABLE IF EXISTS #rfm;
with rfm as --creating a cte for the below data
	(select 
			CUSTOMERNAME, 
			sum(sales) MonetaryValue,
			avg(sales) AvgMonetaryValue,
			count(ORDERNUMBER) Frequency,
			max(ORDERDATE) last_order_date,
			(select max(ORDERDATE) from [dbo].[sales_data.csv]) max_order_date,
			DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data.csv])) Recency
		from [dbo].[sales_data.csv]
		group by CUSTOMERNAME
),
rfm_calc as
(
SELECT r.*,
	NTILE(4) over (order by  Recency desc) rfm_recency,
	NTILE(4) over (order by  Frequency) rfm_frequency,
	NTILE(4) over (order by  MonetaryValue) rfm_monetary
FROM rfm r)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144,234) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331,412,412,421,423) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322,232,221) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm

