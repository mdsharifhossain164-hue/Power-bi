-- Explore the customers table 
Select * FROM customers

-- Explore the customers journey table
Select * FROM customer_journey

--Explore the Customer reviews table
Select * FROM customer_reviews

-- Explore the engagement table
Select * FROM engagement_data

-- Explore the geography table
Select * FROM geography

--Explore the products table
Select * FROM products


-- Categorize products based on their price into 'Low', 'Medium', and 'High' price categories   
SELECT 
    ProductID,
    ProductName,  
    Price,  
	

    CASE 
        WHEN Price < 50 THEN 'Low'  
        WHEN Price BETWEEN 50 AND 200 THEN 'Medium'  
        ELSE 'High'  
    END AS PriceCategory  

FROM 
    products;

    Select * FROM engagement_data
    Select * FROM geography

-- SQL statement to join customers with geography to enrich customer data with geographic information
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email,
    c.gender,
    c.Age,
    g.Country,
    g.City
FROM 
    customers c LEFT JOIN geography g
ON 
    c.GeographyID = g.GeographyID;  

-- Query to clean whitespace issues in the ReviewText column of the customer_reviews table
SELECT 
    ReviewID, 
    CustomerID, 
    ProductID,
    ReviewDate, 
    Rating, 
    
    REPLACE(ReviewText, '  ', ' ') AS ReviewText
FROM 
    customer_reviews;  

-- Query to clean and normalize the engagement_data table

SELECT 
    EngagementID,  
    ContentID,  
	CampaignID,  
    ProductID,  
    UPPER(REPLACE(ContentType, 'Socialmedia', 'Social Media')) AS ContentType,  
    LEFT(ViewsClicksCombined, CHARINDEX('-', ViewsClicksCombined) - 1) AS Views, 
    RIGHT(ViewsClicksCombined, LEN(ViewsClicksCombined) - CHARINDEX('-', ViewsClicksCombined)) AS Clicks,  

    FORMAT(CONVERT(DATE, EngagementDate), 'dd.MM.yyyy') AS EngagementDate 
FROM 
    engagement_data  
WHERE 
    ContentType != 'Newsletter';  


-- Common Table Expression (CTE) to identify and tag duplicate records

WITH DuplicateRecords AS (
    SELECT 
        JourneyID, 
        CustomerID,
        ProductID, 
        VisitDate,
        Stage,
        Action, 
        Duration,
       
        ROW_NUMBER() OVER (
          
            PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action  
           
            ORDER BY JourneyID  
        ) AS row_num 
    FROM 
        dbo.customer_journey  
)
    
SELECT *
FROM DuplicateRecords
WHERE row_num > 1
ORDER BY JourneyID

-- Outer query selects the final cleaned and standardized data
    
SELECT 
    JourneyID, 
    CustomerID, 
    ProductID, 
    VisitDate, 
    Stage,
    Action,
    COALESCE(Duration, avg_duration) AS Duration 
FROM 
    (
        -- Subquery to process and clean the data
        SELECT 
            JourneyID,
            CustomerID,
            ProductID,
            VisitDate,
            UPPER(Stage) AS Stage,
            Action,  -- Selects the action taken by the customer (e.g., View, Click, Purchase)
            Duration,
            AVG(Duration) OVER (PARTITION BY VisitDate) AS avg_duration, 
            ROW_NUMBER() OVER (
                PARTITION BY CustomerID, ProductID, VisitDate, UPPER(Stage), Action 
                ORDER BY JourneyID 
            ) AS row_num 
        FROM 
            dbo.customer_journey 
    ) AS subquery  
WHERE 
    row_num = 1;  