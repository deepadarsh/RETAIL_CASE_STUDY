USE Retail_CaseStudy

SELECT * FROM TRANSACTIONS
SELECT * FROM PROD_CAT_INFO
SELECT * FROM Customer

--1.  What is the total number of rows in each of the 3 tables in the database?

	SELECT  (SELECT COUNT(*) FROM Customer) AS CustCnt,
			(SELECT COUNT(*) FROM Transactions) AS TransCnt,     
			(SELECT COUNT(*) FROM prod_cat_info) AS ProdCnt

--2.  What is the total number of transactions that have a return? 
 
	SELECT count(TOTAL_AMT) [Count_transaction] FROM Transactions WHERE TOTAL_AMT < 0

--3. As you would have noticed, the dates provided across the datasets are not in a correct format. As first steps,
--pls convert the date variables into valid date formats before proceeding ahead. 

	SELECT CONVERT(DATE, DOB, 105) AS DATES FROM Customer 
	SELECT CONVERT(DATE, TRAN_DATE, 105) FROM Transactions
	
--4.  What is the time range of the transaction data available for analysis? Show the output in number of days,
--months and years simultaneously in different columns. 

	SELECT DATEDIFF(DAY, MIN(CONVERT(DATE, TRAN_DATE, 105)), MAX(CONVERT(DATE, TRAN_DATE, 105)))  [Days], 
	DATEDIFF(MONTH, MIN(CONVERT(DATE, TRAN_DATE, 105)), MAX(CONVERT(DATE, TRAN_DATE, 105))) [Months],  
	DATEDIFF(YEAR, MIN(CONVERT(DATE, TRAN_DATE, 105)), MAX(CONVERT(DATE, TRAN_DATE, 105))) [Years] 
	FROM Transactions

--5.  Which product category does the sub-category �DIY� belong to?

	SELECT PROD_CAT FROM prod_cat_info WHERE PROD_SUBCAT = 'DIY'

--DATA ANALYSIS

--1.  Which channel is most frequently used for transactions? 

	SELECT TOP 1 STORE_TYPE ,COUNT(STORE_TYPE) [COUNT_OF_CHANNEL] 
	FROM transactions GROUP BY STORE_TYPE ORDER BY [COUNT_OF_CHANNEL] DESC

--2.  What is the count of Male and Female customers in the database? 

	SELECT GENDER,COUNT(GENDER) [COUNT] FROM Customer
	WHERE GENDER IN ('M','F')
	GROUP BY GENDER

--3.  From which city do we have the maximum number of customers and how many?  

	SELECT TOP 1  city_code,COUNT(CITY_CODE)[CITY_COUNT] FROM Customer GROUP BY city_code ORDER BY [CITY_COUNT] DESC

--4.  How many sub-categories are there under the Books category?  

	SELECT PROD_SUBCAT FROM PROD_CAT_INFO WHERE PROD_CAT = 'BOOKS'

--5.  What is the maximum quantity of products ever ordered?  

	SELECT TOP 1 QTY FROM transactions ORDER BY QTY DESC

--6.  What is the net total revenue generated in categories Electronics and Books?

	SELECT  FROM transactions T INNER JOIN PROD_CAT_INFO P ON 
	T.PROD_SUBCAT_CODE = P.PROD_SUB_CAT_CODE WHERE PROD_CAT IN ('Electronics','Books')

--7.  How many customers have >10 transactions with us, excluding returns?  

	SELECT DISTINCT CUST_ID,COUNT(TRANSACTION_ID)[COUNT] 
	FROM TRANSACTIONS WHERE TOTAL_AMT >=0 GROUP BY CUST_ID HAVING COUNT(TRANSACTION_ID)> 10

--8.  What  is  the  combined  revenue  earned  from  the  �Electronics�  &  �Clothing� categories, from �Flagship stores�? 

	SELECT SUM(TOTAL_AMT) NET_REVENUE FROM TRANSACTIONS T INNER JOIN PROD_CAT_INFO P ON 
	T.PROD_SUBCAT_CODE = P.PROD_SUB_CAT_CODE WHERE PROD_CAT IN ('Electronics','Clothing') AND STORE_TYPE = 'FLAGSHIP STORE'

--9.  What is the total revenue generated from �Male� customers in �Electronics� category? Output should display total revenue by prod sub-cat.

	SELECT DISTINCT PROD_SUBCAT,SUM(TOTAL_AMT) REVENUE_GEN
	FROM TRANSACTIONS
	LEFT JOIN Customer ON CUST_ID=CUSTOMER_ID
	LEFT JOIN PROD_CAT_INFO ON PROD_SUBCAT_CODE = PROD_SUB_CAT_CODE
	WHERE GENDER = 'M' AND PROD_CAT = 'Electronics'
	GROUP BY PROD_SUBCAT

--10. What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?

	SELECT TOP 5 
	PROD_SUBCAT, (SUM(TOTAL_AMT)/(SELECT SUM(TOTAL_AMT) FROM TRANSACTIONS))*100 AS PERCANTAGE_OF_SALES, 
	(COUNT(CASE WHEN TOTAL_AMT < 0 THEN QTY ELSE NULL END)/SUM(QTY))*100 AS PERCENTAGE_OF_RETURN
	FROM TRANSACTIONS
	INNER JOIN PROD_CAT_INFO ON  PROD_SUBCAT_CODE= PROD_SUB_CAT_CODE
	GROUP BY PROD_SUBCAT
	ORDER BY SUM(TOTAL_AMT) DESC

--11. For all customers aged between 25 to 35 years find what is the net total revenue generated by these consumers in 
--	  last 30 days of transactions from max transaction date available in the data? 

	SELECT CUST_ID,SUM(TOTAL_AMT) AS REVENUE FROM Transactions
	WHERE CUST_ID IN 
	(
	SELECT CUSTOMER_ID FROM Customer WHERE DATEDIFF(YEAR,CONVERT(DATE,DOB,103),GETDATE()) BETWEEN 25 AND 35) 
	AND CONVERT(DATE,tran_date,103) BETWEEN DATEADD(DAY,-30,(SELECT MAX(CONVERT(DATE,tran_date,103)) FROM Transactions)) 
	AND (SELECT MAX(CONVERT(DATE,tran_date,103)) FROM Transactions)
	GROUP BY CUST_ID


--12.	Which product category has seen the max value of returns in the last 3 
--		months of transactions?

	SELECT TOP 1 PROD_CAT, SUM(TOTAL_AMT)[TOTAL_AMT] FROM Transactions 
	INNER JOIN PROD_CAT_INFO  ON PROD_SUBCAT_CODE = PROD_SUB_CAT_CODE 
	WHERE TOTAL_AMT < 0 AND 
	CONVERT(date, tran_date, 103) BETWEEN DATEADD(MONTH,-3,(SELECT MAX(CONVERT(DATE,tran_date,103)) FROM Transactions)) 
	 AND (SELECT MAX(CONVERT(DATE,tran_date,103)) FROM Transactions)
	GROUP BY PROD_CAT
	ORDER BY [TOTAL_AMT] DESC

--13.	Which store-type sells the maximum products; by value of sales amount and
--		by quantity sold?

	SELECT  STORE_TYPE, SUM(TOTAL_AMT) TOT_SALES, SUM(QTY) TOT_QUAN
	FROM Transactions
	GROUP BY STORE_TYPE
	HAVING SUM(TOTAL_AMT) >=ALL (SELECT SUM(TOTAL_AMT) FROM Transactions GROUP BY STORE_TYPE)
	AND SUM(QTY) >=ALL (SELECT SUM(QTY) FROM Transactions GROUP BY STORE_TYPE)


--14.	What are the categories for which average revenue is above the overall average.

	SELECT PROD_CAT, AVG(TOTAL_AMT) AS AVERAGE
	FROM Transactions
	INNER JOIN PROD_CAT_INFO ON PROD_SUBCAT_CODE = PROD_SUB_CAT_CODE
	GROUP BY PROD_CAT
	HAVING AVG(TOTAL_AMT)> (SELECT AVG(TOTAL_AMT) FROM Transactions) 


--15.	Find the average and total revenue by each subcategory for the categories 
--		which are among top 5 categories in terms of quantity sold.


SELECT PROD_CAT, PROD_SUBCAT, AVG(TOTAL_AMT) AS AVERAGE_REV, SUM(TOTAL_AMT) AS REVENUE
FROM Transactions
INNER JOIN PROD_CAT_INFO ON PROD_SUBCAT_CODE = PROD_SUB_CAT_CODE
WHERE PROD_CAT IN
(
SELECT TOP 5 
PROD_CAT
FROM Transactions 
INNER JOIN PROD_CAT_INFO ON PROD_SUBCAT_CODE = PROD_SUB_CAT_CODE
GROUP BY PROD_CAT
ORDER BY SUM(QTY) DESC
)
GROUP BY PROD_CAT, PROD_SUBCAT 