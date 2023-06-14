--Project
CREATE DATABASE MXZ;

USE MXZ;

--Check the existing tables
SELECT * FROM sys.objects WHERE [type]='U';


-- Add a third department, Operations, to the Department table. 
-- You will assign your positions, salaries, etc. and the Department field will be Operations?
--SELECT * FROM [HumanResources].[Departme5nt];
INSERT INTO [HumanResources].[Department]
(Dept_ID, Dept_Name)
VALUES
(3, 'Operations');
GO

SELECT * FROM [HumanResources].[Department];

--Add executives' data (up to three individuals including yourselves) into the Employee table
--SELECT * FROM [HumanResources].[Employee];
--DELETE FROM [HumanResources].[Employee] WHERE Dept_ID = 3;
INSERT INTO [HumanResources].[Employee]
VALUES
(3011, 'Xinyun', 'Y', 'F', 'CEO', 3, 100000),
(3012, 'May', 'P', 'F', 'CFO', 3, 100000),
(3013, 'Zhehao', 'J', 'M', 'COO', 3, 100000);
GO

-- CREATE TABLES Client, [View], Pricing, ClientType, RegionAgent

--Create and populate table Client
--DROP TABLE [App].[Client];

CREATE TABLE Client (
         ClientID    BIGINT           PRIMARY KEY 
     ,   [Name]      VARCHAR(50)
     ,   TypeID      INT   
     ,   City        NVARCHAR(225)    
     ,   Region      NVARCHAR(225)     
     ,   Pricing     INT     
);
GO

--Create table View
--SELECT * FROM [App].[View];
CREATE TABLE [View] (
         ViewID      INT           PRIMARY KEY 
     ,   ViewDate	 DATETIME
     ,   ID          BIGINT   
     ,   Device      NVARCHAR(225)    
     ,   Browser	 NVARCHAR(225)     
     ,   Host        NVARCHAR(225)
);
GO

--Create pricing table
CREATE TABLE Pricing (
         PlanNo      INT           PRIMARY KEY 
     ,   PlanName    NVARCHAR(225)    
     ,   Monthly	 FLOAT     
);
GO

--Create ClientType table
CREATE TABLE ClientType (
         TypeName    NVARCHAR(225)     
     ,   TypeID      INT            PRIMARY KEY
);
GO

--Create ClientType table
CREATE TABLE RegionAgent (
         Region      NVARCHAR(225)     
     ,   EmployeeID  INT
);
GO


-- BULK INSERT commands for Client and View and filling other tables with copy and paste
-- Bulk insert for Client
BULK INSERT Client
FROM 'C:\Users\Administrator\Desktop\02-SQL Data Fundamentals and Bus Intelligence-7100\Project\FR2\Client.csv'
WITH (FORMAT = 'CSV',
      FIRSTROW = 2
);
GO

-- Bulk insert for View
BULK INSERT [View]
FROM 'C:\Users\Administrator\Desktop\02-SQL Data Fundamentals and Bus Intelligence-7100\Project\FR2\View.txt'
WITH (FIRSTROW = 2,
	  FIELDTERMINATOR = '\t', 
	  ROWTERMINATOR = '\n'
);
GO

--Top ten Spas & Salons? names, regions, and the number of views, with the highest views.
SELECT TOP 10 c.[Name], c.Region, COUNT(v.ID) AS [Number of views]
FROM [App].[View] v JOIN [App].[Client] c ON v.ID = c.ClientID
WHERE c.TypeID = (SELECT TypeID 
                  FROM [App].[ClientType] 
				  WHERE TypeName like 'Spas & Salons')
GROUP BY c.[Name], c.Region, c.ClientID
ORDER BY COUNT(v.ID) DESC


--All clients whose names start OR end with the text Grill? along with their cities, subscription fees**, and number of views.
SELECT  c.[Name]
      , c.City
	  , FORMAT(p.Monthly, 'C') AS [Subscription fees]
	  , COUNT(v.ID) AS [Number of views]
FROM [App].[Client] c JOIN [App].[View] v ON c.ClientID = v.ID
                      JOIN [App].[Pricing] p ON c.Pricing = p.PlanNo
WHERE c.[Name] like 'OR%' or c.[Name] like '%Grill'
GROUP BY c.[Name], c.City, p.Monthly

--Count of client types (Arts & Entertainment, Bakery, etc.) with their average views per client
--and average subscription fees per client
SELECT  ct.TypeID
      , ct.TypeName
	  , COUNT(v.ID)/COUNT(DISTINCT v.ID) AS [Average Views per Client]
--	  , [Total Fees]
	  , FORMAT([Total Fees]/COUNT(DISTINCT v.ID), 'C') AS [Average subscription fees per client]
FROM 
(SELECT ct.TypeID, ct.TypeName, SUM(p.Monthly) AS [Total Fees]
 FROM [App].[Client] c JOIN [App].[Pricing] p ON p.PlanNo = c.Pricing
                       JOIN [App].[ClientType] ct ON ct.TypeID = c.TypeID
 GROUP BY ct.TypeID, ct.TypeName) AS [TypeFees] JOIN [App].[ClientType] ct ON TypeFees.TypeID = ct.TypeID
	                                            JOIN [App].[Client] c ON ct.TypeID = c.TypeID
												JOIN [App].[View] v ON v.ID = c.ClientID
GROUP BY ct.TypeID, ct.TypeName, [Total Fees]
ORDER BY [Average Views per Client] desc;


--Cities (along with their regions) for which total number of views 
--for non-restaurant clients are more than 15
SELECT City, Region, COUNT(v.ID) AS [Total Number of Views]
FROM [App].[Client] c JOIN  [App].[View] v ON c.ClientID = v.ID
WHERE c.TypeID not in (SELECT TypeID 
                       FROM [App].[ClientType]
                       WHERE TypeName LIKE 'Restaurant')
GROUP BY City, Region
HAVING COUNT(v.ID) > 15


--States (regions) with number of clients and number of coffee customers 
--for those states (regions) in which there are both types of customers.
SELECT  c.Region
      , COUNT(DISTINCT c.ClientID) AS [Number of Clients]
      , COUNT(DISTINCT cu.CustomerNum) AS [Number of Customers]
FROM [App].[Client] c JOIN [Restaurant].[Customer] cu ON c.Region = cu.[State]
GROUP BY c.Region;


--Number of clients, their total fees, total views, and average fees per view with respect to regions, 
--sorted in descending order of average fees per views.
SELECT c1.Region
    , COUNT(DISTINCT c1.ClientID) AS [Number of Clients]
    , FORMAT([Total Fees Number], 'C') AS [Total Fees]
    , COUNT(v.ViewID) AS [Total views]
	, FORMAT([Total Fees Number]/COUNT(v.ViewID), 'C') AS [Average Fees per View]
FROM 
    (SELECT  c2.Region
	       , Sum(p.Monthly) AS [Total Fees Number] 
     FROM [App].[Client] c2 JOIN [App].[Pricing] p ON p.PlanNo = c2.Pricing
     GROUP BY c2.Region) AS RegionFees   JOIN  [App].[Client] c1    ON c1.Region = RegionFees.Region
                                         JOIN  [App].[View] v       ON c1.ClientID = v.ID
GROUP BY c1.Region, [Total Fees Number]
ORDER BY [Total Fees Number]/COUNT(v.ViewID) DESC;



--All views (all columns) that took place after October 15th, by Kindle devices, 
--hosted by Yelp from cities where there are more than 20 clients. 
--Also add the name and the city of the client as last columns for each view.
SELECT v.*, c.[Name], c.City
FROM [App].[View] v JOIN [App].[Client] c ON v.ID = c.ClientID
WHERE Host like 'yelp' 
     and Device like 'Kindle' 
	 and ViewDate >= '2022-10-16 00:00:00.000'
	 and c.City in (SELECT c.City 
	                  FROM [App].[Client] c join [App].[View] v ON  c.ClientID = v.ID
	                  GROUP BY City
	                  HAVING COUNT(c.ClientID) > 20);

--FR3.Q8: Create a view named vEmployeeClientCustomer based on the query
IF EXISTS (SELECT name FROM sysobjects 
           WHERE name = 'vEmployeeClientCustomer'[Restaurant].[Order] AND type = 'v')
DROP VIEW vEmployeeClientCustomer
GO

CREATE VIEW vEmployeeClientCustomer AS
(
SELECT 
        EmployeeID
	  , e.FirstName
	  , e.LastName
      , [Number of Regions]
	  , [Number of Clients]
	  , [Total Views]
	  , [Number of Distinct Coffee Customers]
	  , [Total Coffee Sales]
FROM
(SELECT r.EmployeeID
      , COUNT(DISTINCT r.Region) AS [Number of Regions]
	  , COUNT(DISTINCT c.ClientID) AS [Number of Clients]
 FROM [HumanResources].[RegionAgent] r JOIN [HumanResources].[Employee] e ON r.EmployeeID = e.Employee_ID
                                       JOIN [App].[Client] c ON r.Region = c.Region
 GROUP BY r.EmployeeID) AS [Employee] JOIN (SELECT e.Employee_ID, Sum([Views]) AS [Total Views]
                                            FROM (SELECT v.ID, CAST(COUNT(v.ID) AS bigint) AS [Views] 
											      FROM [App].[View] v GROUP BY v.ID) AS [View] JOIN [App].[Client] c on [View].ID = c.ClientID
                                                                                               JOIN [HumanResources].[RegionAgent] r on c.Region = r.Region
																							   JOIN [HumanResources].[Employee] e on e.Employee_ID = r.EmployeeID
                                                  Group by e.Employee_ID
                                                  ) AS [View] ON [View].Employee_ID = [Employee].EmployeeID
									  JOIN (SELECT  e.Employee_ID
                                                  , COUNT(DISTINCT cu.CustomerNum) AS [Number of Distinct Coffee Customers]
	                                              , CASE 
	                                                WHEN FORMAT(SUM(o.OrderAmountKg*co.PricePerKg), 'C') IS NULL THEN 'Not coffee agent' 
		                                            ELSE FORMAT(SUM(o.OrderAmountKg*co.PricePerKg), 'C')
		                                            END [Total Coffee Sales]
                                            FROM [Restaurant].[Customer] cu JOIN [HumanResources].[RegionAgent] r on cu.State = r.Region
								                                            JOIN [Restaurant].[Order] o ON cu.CustomerNum = o.CustomerNum
								                                            JOIN [Restaurant].[Coffee] co ON o.CoffeeID = co.CoffeeID
								                                            RIGHT JOIN [HumanResources].[Employee] e on e.Employee_ID = r.EmployeeID                                                                                                         
                                            GROUP BY e.Employee_ID) AS [Coffee] ON Coffee.Employee_ID = [View].Employee_ID
                                      RIGHT JOIN [HumanResources].[Employee] e on [Employee].EmployeeID = e.Employee_ID
WHERE e.Dept_ID not in (SELECT Dept_ID FROM [HumanResources].[Department] WHERE Dept_Name like 'Operations') 
GROUP BY EmployeeID, [Total Views], [Number of Regions]  vv, [Number of Clients], e.FirstName, e.LastName, [Number of Distinct Coffee Customers], [Total Coffee Sales]

--Create a stored procedure named spEmployeeReport, 
--for which you will pass the last name of the employee only. 
--The result should be FR3.Q9 only for that employee. 
IF EXISTS (SELECT name FROM sysobjects 
           WHERE name = 'spEmployeeReport' AND type = 'P')
DROP PROCEDURE spEmployeeReport;
GO

CREATE PROCEDURE spEmployeeReport @LastName nvarchar(225) 
AS
BEGIN 
SELECT * 
FROM vEmployeeClientCustomer
WHERE LastName = @LastName
END;

EXEC spEmployeeReport Mea
EXECUTE spEmployeeReport Bundy

