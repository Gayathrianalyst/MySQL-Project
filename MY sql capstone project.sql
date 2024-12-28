-- Project Steps and Objectives:
-- Data Cleaning:
-- Handling Missing Values and Outliers:
/* ➢ Impute mean for the following columns, and round off to the 
nearest integer if required: WarehouseToHome, HourSpendOnApp, 
OrderAmountHikeFromlastYear, DaySinceLastOrder.*/
USE ecomm;
SELECT * FROM customer_churn;

-- Disable safe update
SET SQL_SAFE_UPDATES = 0;

SET @Avg_warehouestohome = (SELECT ROUND(avg(WarehouseToHome)) 
FROM customer_churn);
SELECT @Avg_warehouestohome;

UPDATE customer_churn
SET WarehouseToHome =  @Avg_warehouestohome
WHERE WarehouseToHome IS NULL;

SET @Avg_HourSpendOnApp = (SELECT ROUND(avg(HourSpendOnApp)) 
FROM customer_churn);
SELECT @Avg_HourSpendOnApp;

UPDATE customer_churn
SET HourSpendOnApp = @Avg_HourSpendOnApp
WHERE HourSpendOnApp IS NULL;

SET @Avg_OrderAmountHikeFromlastYear = (SELECT ROUND(AVG(OrderAmountHikeFromlastYear)) 
FROM customer_churn);
SELECT @Avg_OrderAmountHikeFromlastYear;

UPDATE customer_churn
SET OrderAmountHikeFromlastYear = @Avg_OrderAmountHikeFromlastYear
WHERE OrderAmountHikeFromlastYear IS NULL; 

SET @Avg_DaySinceLastOrder = (SELECT ROUND(AVG(DaySinceLastOrder)) 
FROM customer_churn);
SELECT @Avg_DaySinceLastOrder;

UPDATE customer_churn
SET DaySinceLastOrder = @Avg_DaySinceLastOrder
WHERE DaySinceLastOrder;

/* ➢ Impute mode for the following columns: Tenure, CouponUsed, 
OrderCount.*/
SELECT tenure, COUNT(*) FROM customer_churn 
GROUP BY tenure 
ORDER BY COUNT(*) DESC LIMIT 1;

UPDATE customer_churn
SET tenure = 1
WHERE tenure = 690; 

SELECT CouponUsed, COUNT(*) FROM customer_churn 
GROUP BY CouponUsed ORDER BY COUNT(*) DESC LIMIT 3;

UPDATE customer_churn
SET CouponUsed = 1
WHERE CouponUsed IS NULL;	

SELECT OrderCount, COUNT(*) AS count_of_ordercount FROM customer_churn 
GROUP BY OrderCount ORDER BY COUNT(*) DESC LIMIT 3;

UPDATE customer_churn
SET OrderCount = 2
WHERE OrderCount IS NULL;	

/*➢ Handle outliers in the 'WarehouseToHome' column by deleting rows 
where the values are greater than 100.*/
DELETE FroM customer_churn
WHERE WarehouseToHome > 100;

-- Dealing with Inconsistencies:
/* ➢ Replace occurrences of “Phone” in the 'PreferredLoginDevice' 
column and “Mobile” in the 'PreferedOrderCat' column with “Mobile 
Phone” to ensure uniformity.*/
UPDATE customer_churn
SET PreferredLoginDevice = 'Mobile Phone'
WHERE PreferredLoginDevice = 'Phone';

UPDATE customer_churn
SET PreferedOrderCat = 'Mobile Phone'
WHERE PreferedOrderCat = 'Mobile';

/* ➢ Standardize payment mode values: Replace "COD" with 
"Cash on Delivery" and "CC" with "Credit Card" in the 
PreferredPaymentMode column.*/
UPDATE customer_churn
SET PreferredPaymentMode = CASE
     WHEN PreferredPaymentMode = "COD" THEN "Cash on Delivery"
     WHEN PreferredPaymentMode = "CC" THEN "Credit Card"
     ELSE PreferredPaymentMode
     END;
   
-- Data Transformation:
-- Column Renaming:
-- ➢ Rename the column "PreferedOrderCat" to "PreferredOrderCat".
ALTER TABLE customer_churn
RENAME COLUMN PreferedOrderCat TO PreferredOrderCat;

-- ➢ Rename the column "HourSpendOnApp" to "HoursSpentOnApp".
ALTER TABLE customer_churn
RENAME COLUMN HourSpendOnApp TO HoursSpentOnApp;

-- Creating New Columns:
/* ➢ Create a new column named ‘ComplaintReceived’ with values "Yes" 
if the corresponding value in the ‘Complain’ is 1, and "No" otherwise.*/
ALTER TABLE customer_churn
ADD COLUMN ComplaintReceived ENUM('Yes','No');

UPDATE customer_churn
SET ComplaintReceived = IF(Complain = 1,'Yes', 'No');
SELECT ComplaintReceived, complain FROM customer_churn;

/* ➢ Create a new column named 'ChurnStatus'. Set its value to 
“Churned” if the corresponding value in the 'Churn' column is 1, 
else assign “Active”.*/
ALTER TABLE customer_churn
ADD COLUMN ChurnStatus ENUM('Churned','Active');

UPDATE customer_churn
SET ChurnStatus = IF(churn = 1, 'Churned','Active');
SELECT churn, churnstatus FROM customer_churn;

-- Column Dropping:
-- ➢ Drop the columns "Churn" and "Complain" from the table.
ALTER TABLE customer_churn
DROP column churn,
DROP COLUMN Complain;

-- Data Exploration and Analysis:
/* 1. Retrieve the count of churned and active customers from the 
dataset.*/
SELECT Churnstatus, COUNT(*) Count_of_customers FROM customer_churn 
GROUP BY Churnstatus;

-- 2. Display the average tenure of customers who churned.
SELECT churnstatus, ROUND(avg(tenure)) avg_tenure FROM customer_churn 
WHERE churnstatus = 'churned'
GROUP BY churnstatus; 

/*3. Calculate the total cashback amount earned by customers 
who churned.*/
SELECT churnstatus, SUM(CashbackAmount) Total_CashbackAmount 
FROM customer_churn 
WHERE churnstatus = 'churned';

-- 4. Determine the percentage of churned customers who complained.
SELECT ComplaintReceived, ChurnStatus FROM customer_churn;
SELECT churnstatus, ComplaintReceived, CONCAT(ROUND(COUNT(*) / 
(SELECT COUNT(*) FROM customer_churn)*100), '%') 
AS Percent_of_churn_Com FROM customer_churn
WHERE Churnstatus = 'churned' AND ComplaintReceived = 'Yes';

-- 5. Find the gender distribution of customers who complained.
SELECT gender, COUNT(*) genderwise_count FROM customer_churn 
WHERE complaintreceived = 'Yes' GROUP BY gender;

/* 6. Identify the city tier with the highest number of churned 
customers whose preferred order category is Laptop & Accessory.*/
SELECT CityTier, PreferredOrderCat, COUNT(*) AS count_of_cus 
FROM customer_churn WHERE Churnstatus = 'churned'
AND PreferredOrderCat = 'Laptop & Accessory'
GROUP BY CityTier, PreferredOrderCat;

-- 7. Identify the most preferred payment mode among active customers.
SELECT PreferredPaymentMode, COUNT(*) count_of_cus FROM customer_churn
WHERE ChurnStatus = 'Active' GROUP BY PreferredPaymentMode
ORDER BY count_of_cus desc LIMIT 1;

/*8. List the preferred login device(s) among customers who took more
than 10 days since their last order.*/
SELECT PreferredLoginDevice FROM customer_churn 
WHERE DaySinceLastOrder > 10;
SELECT PreferredLoginDevice, DaySinceLastOrder FROM customer_churn;

/* 9. List the number of active customers who spent more than 3 hours 
on the app.*/
SELECT HoursSpentOnApp, COUNT(ChurnStatus = 'Active') no_of_activecustomers 
FROM Customer_churn WHERE HoursSpentOnApp > 3
group by HoursSpentOnApp;

/* 10. Find the average cashback amount received by customers who 
spent at least 2 hours on the app.*/
SELECT HoursSpentOnApp, ROUND(AVG(CashbackAmount)) Avg_cashbackamount 
FROM Customer_churn WHERE HoursSpentOnApp >= 2
group by HoursSpentOnApp;

/*11. Display the maximum hours spent on the app by customers in each 
preferred order category.*/
SELECT PreferredOrderCat, MAX(HoursSpentOnApp) AS MAX_HoursSpentOnApp 
FROM customer_churn GROUP BY PreferredOrderCat;

/* 12. Find the average order amount hike from last year for customers
in each marital status category.*/
SELECT MaritalStatus, ROUND(AVG(OrderAmountHikeFromlastYear)) Avg_OrderAmountHikeFromlastYear
FROM customer_churn GROUP BY MaritalStatus;

/* 13. Calculate the total order amount hike from last year for 
customers who are single and prefer mobile phones for ordering.*/
SELECT SUM(OrderAmountHikeFromlastYear) Total_amount 
FROM customer_churn 
WHERE MaritalStatus = 'Single' AND PreferredOrderCat = 'Mobile phone';

/* 14. Find the average number of devices registered among customers 
who used UPI as their preferred payment mode.*/
SELECT PreferredPaymentMode, ROUND(AVG(NumberOfDeviceRegistered)) AVG_NumberOfDeviceRegistered
FROM customer_churn WHERE PreferredPaymentMode = 'UPI';

/* 15. Determine the city tier with the highest number of customers.*/
SELECT citytier, COUNT(*) count_of_cus FROM customer_churn 
GROUP BY Citytier ORDER BY count_of_cus DESC LIMIT 1;

/* 16. Find the marital status of customers with the highest number 
of addresses.*/
SELECT maritalstatus, NumberOfAddress, count(*) AS no_of_customer 
FROM customer_churn GROUP BY maritalstatus, NumberOfAddress 
order by NumberOfAddress desc LIMIT 1;	

/*17. Identify the gender that utilized the highest number of coupons.*/
SELECT gender, count(CouponUsed) highest_no_of_cuponused 
FROM customer_churn
group by gender order by highest_no_of_cuponused desc;
    
/* 18. List the average satisfaction score in each of the preferred 
order categories.*/
SELECT PreferredOrderCat, ROUND(AVG(SatisfactionScore)) AS avg_score 
FROM CUSTOMER_CHURN GROUP BY PreferredOrderCat;

/* 19. Calculate the total order count for customers who prefer using 
credit cards and have the maximum satisfaction score.*/
SELECT SUM(OrderCount) Total_order_count FROM customer_churn 
WHERE PreferredPaymentMode = 'Credit Card' AND SatisfactionScore >= 4;

/* 20. How many customers are there who spent only one hour on the app and days
since their last order was more than 5?*/
SELECT COUNT(*) No_of_customer FROM customer_churn 
where DaySinceLastOrder > 5 AND HoursSpentOnApp > 2;

/* 21. What is the average satisfaction score of customers who have 
complained?*/
SELECT ROUND(AVG(SatisfactionScore)) Avg_satisfactionscore 
FROM customer_churn 
WHERE ComplaintReceived = 'Yes';

/* 22. How many customers are there in each preferred order category?*/
SELECT PreferredOrderCat, COUNT(*) no_of_customer FROM customer_churn
group by PreferredOrderCat;

/* 23. What is the average cashback amount received by married customers?*/
SELECT ROUND(avg(CashbackAmount)) avg_cashbackamt FROM customer_churn
WHERE MaritalStatus = 'Married';

/* 24. What is the average number of devices registered by customers who are not
using Mobile Phone as their preferred login device?*/
SELECT ROUND(AVG(NumberOfDeviceRegistered)) Avg_no_of_deviceregistered 
FROM customer_churn WHERE PreferredLoginDevice != 'MOBILE PHONE';

/*25. List the preferred order category among customers who used more than 5
coupons.*/
SELECT PreferredOrderCat, COUNT(*) no_of_customer FROM customer_churn 
WHERE CouponUsed > 5 GROUP BY PreferredOrderCat 
ORDER BY no_of_customer DESC;

/*26. List the top 3 preferred order categories with the highest 
average cashback amount.*/
SELECT PreferredOrderCat, ROUND(AVG(CashbackAmount)) avg_cashbackamt 
FROM customer_churn GROUP BY PreferredOrderCat 
ORDER BY avg_cashbackamt DESC LIMIT 3;

/* 27. Find the preferred payment modes of customers whose average 
tenure is 10 months and have placed more than 500 orders.*/
SELECT PreferredPaymentMode, COUNT(*) No_of_customer 
FROM customer_churn 
WHERE tenure = 10 AND OrderCount > 500 
GROUP BY PreferredPaymentMode;

/* 28. Categorize customers based on their distance from the warehouse
to home such as 'Very Close Distance' for distances <=5km, 'Close 
Distance' for <=10km, 'Moderate Distance' for <=15km, and 'Far 
Distance' for >15km. Then, display the churn status breakdown for 
each distance category.*/
SELECT case 
       WHEN WarehouseToHome <= 5 THEN 'Very Close Distance' 
       WHEN WarehouseToHome <= 10 THEN 'Close Distance'
       WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
       ELSE 'Far Distance'
       END distance_from_WarehouseToHome,
       Churnstatus
 FROM customer_churn;
 
/*29. List the customer’s order details who are married, live in City 
Tier-1, and their order counts are more than the average number of 
orders placed by all customers.*/
SET @avg_no_of_orders = (SELECT ROUND(AVG(OrderCount)) 
FROM customer_churn);
SELECT @avg_no_of_orders; 
SELECT CustomerID, Ordercount FROM customer_churn 
WHERE maritalstatus = 'married' AND Citytier = 1
GROUP BY CustomerID 
HAVING Ordercount > @avg_no_of_orders;

/*30. a) Create a ‘customer_returns’ table in the ‘ecomm’ database 
and insert the following data:
ReturnID CustomerID ReturnDate RefundAmount
1001 50022 2023-01-01 2130
1002 50316 2023-01-23 2000
1003 51099 2023-02-14 2290
1004 52321 2023-03-08 2510
1005 52928 2023-03-20 3000
1006 53749 2023-04-17 1740
1007 54206 2023-04-21 3250
1008 54838 2023-04-30 1990 */
CREATE TABLE customer_returns(
ReturnID INT PRIMARY KEY, 
CustomerID INT UNIQUE, 
ReturnDate DATE, 
RefundAmount DECIMAL(10,2));
INSERT INTO Customer_returns(
ReturnID, CustomerID, ReturnDate, RefundAmount)
VALUES 
(1001, 50022, '2023-01-01', 2130),
(1002, 50316, '2023-01-23', 2000),
(1003, 51099, '2023-02-14', 2290),
(1004, 52321, '2023-03-08', 2510),
(1005, 52928, '2023-03-20', 3000),
(1006, 53749, '2023-04-17', 1740),
(1007, 54206, '2023-04-21', 3250),
(1008, 54838, '2023-04-30', 1990);
 SELECT * FROM Customer_returns;
 
/* b) Display the return details along with the customer details 
of those who have churned and have made complaints.*/
SELECT * FROM Customer_returns r
LEFT JOIN Customer_churn c ON r.CustomerID = c.CustomerID
WHERE ChurnStatus = 'churned' AND ComplaintReceived = 'Yes';

--                       THE END