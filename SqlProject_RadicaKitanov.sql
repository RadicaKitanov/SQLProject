--Super
-- SQLProject_RADICAKITANOV

Create database SQLProject_RadicaKitanov
GO

USE SQLProject_RadicaKitanov
GO

DROP TABLE IF EXISTS dbo.SeniorityLevel
CREATE TABLE dbo.SeniorityLevel
(
	ID int IDENTITY(1,1) NOT NULL,
	[Name] nvarchar(100) NOT NULL,
	CONSTRAINT [PK_SeniorityLevel] PRIMARY KEY CLUSTERED([ID] ASC)
)
GO

INSERT INTO dbo.SeniorityLevel ([Name])
VALUES ('Junior'),('Intermediate'),('Senor'),('Lead'),('Project Manager'),('Division Manager'),('Office Manager'),('CEO'),('CTO'),('CIO')
GO

--Test Select * from dbo.SeniorityLevel

DROP TABLE IF EXISTS dbo.[Location]
CREATE TABLE dbo.[Location]
(
	ID int IDENTITY(1,1) NOT NULL,
	[CountryName] nvarchar(100) NULL,
	[Continent] nvarchar(100) NULL,
	[Region] nvarchar(100) NULL,
	CONSTRAINT [PK_Location] PRIMARY KEY CLUSTERED([ID] ASC)
)
GO

INSERT INTO dbo.[Location] ([CountryName], [Continent], [Region] )
	SELECT wac.CountryName,wac.Continent,wac.Region
FROM 
	[WideWorldImporters].[Application].[Countries] as wac
GO

--Test Select * from [dbo].[Location]

DROP TABLE IF EXISTS dbo.Department
CREATE TABLE dbo.Department
(
	ID int IDENTITY(1,1) NOT NULL,
	[Name] nvarchar(100) Not NULL,
	CONSTRAINT [PK_Department] PRIMARY KEY CLUSTERED([ID] ASC)
)
GO

INSERT INTO dbo.Department ([Name])
VALUES ('Personal Banking & Operations'),('Digital Banking Department'),('Retail Banking & Marketing Department'),('Wealth Management & Third Party Products'),('International Banking Division & DFB'),('Treasury'),('Information Technology'),('Corporate Communications'),('Support Services & Branch Expansion'),('Human Resources')
GO

--Test Select * from dbo.Department

DROP TABLE IF EXISTS dbo.[Employee]
CREATE TABLE dbo.[Employee]
(
	ID int IDENTITY(1,1) NOT NULL,
	FirstName nvarchar(100) NOT NULL,
	LastName nvarchar(100) NOT NULL,
	LocationId int NOT NULL,
	SenorityLevelId int NOT NULL,
	DepartmentId int NOT NULL,
	CONSTRAINT [PK_Employee] PRIMARY KEY CLUSTERED([ID] ASC)
)
GO


DROP TABLE IF EXISTS dbo.[Salary]
CREATE TABLE dbo.[Salary]
(
	ID int IDENTITY(1,1) NOT NULL,
	EmployeeId int NOT NULL,
	[Month] smallint NOT NULL,
	[Year] smallint NOT NULL,
	GrossAmount decimal(18,2) NOT NULL,
	NetAmount decimal(18,2) NOT NULL,
	RegularWorkAmount decimal(18,2) NOT NULL,
	BonusAmount decimal(18,2) NOT NULL,
	OvertimeAmount decimal(18,2) NOT NULL,
	[VacationDays] smallint NOT NULL,
	[SickLeaveDays] smallint NOT NULL,
	CONSTRAINT [PK_Salary] PRIMARY KEY CLUSTERED([ID] ASC)
)
GO


ALTER TABLE dbo.Employee
ADD CONSTRAINT FK_Location_Employee FOREIGN KEY(LocationId)
REFERENCES dbo.Location(ID)
GO

ALTER TABLE dbo.Employee
ADD CONSTRAINT FK_SeniorityLevel_Employee FOREIGN KEY(SenorityLevelId)
REFERENCES dbo.SeniorityLevel(ID)
GO

ALTER TABLE dbo.Employee
ADD CONSTRAINT FK_Department_Employee FOREIGN KEY(DepartmentId)
REFERENCES dbo.Department(ID)
GO

ALTER TABLE dbo.Salary
ADD CONSTRAINT FK_Employee_Salary FOREIGN KEY(EmployeeId)
REFERENCES dbo.Employee(ID)
GO


INSERT INTO  dbo.[Employee] (FirstName,LastName,LocationId,SenorityLevelId,DepartmentId)
	SELECT 
		SUBSTRING(wap.FullName, 1, CHARINDEX(' ', wap.FullName) - 1) AS FirstName,     
		SUBSTRING(wap.FullName, CHARINDEX(' ', wap.FullName) + 1, LEN(wap.FullName) - CHARINDEX(' ', wap.FullName)) AS LastName,
		1 as LocationID, 1 as SenorityLevelId, 1 as  DepartmentId
FROM [WideWorldImporters].[Application].[People] as wap

GO	

WITH myCTE AS 
(
	SELECT
		e.ID,e.SenorityLevelId,e.LocationID,e.DepartmentID,
		NTILE(10) OVER (PARTITION BY s.Name ORDER BY e.ID ) RanksSenorityLevelID,
		NTILE(10) OVER (PARTITION BY d.Name ORDER BY e.ID) RanksDepartmentlID,
		NTILE(185) OVER (PARTITION BY l.ID ORDER BY e.ID) RanksLocationID
	FROM
		dbo.Employee as e
		JOIN dbo.SeniorityLevel as s ON s.ID=e.SenorityLevelId
		JOIN dbo.Department as d ON e.DepartmentId=d.ID
		JOIN dbo.Location as l ON l.ID=e.LocationId
)
UPDATE 
	e
SET 
	SenorityLevelId  =myCTE.RanksSenorityLevelID,
	DepartmentID =myCTE.RanksDepartmentlID,
	LocationID =myCTE.RanksLocationID
FROM myCTE 
join dbo.Employee as e ON e.ID=myCTE.ID
GO

--Test select * from dbo.Employee

-- Salary


-- Create Date Damension

DROP TABLE IF EXISTS [dbo].[Date]
CREATE TABLE [dbo].[Date]
(
	[DateKey] Date NOT NULL
,	[Day] TINYINT NOT NULL
,	DaySuffix CHAR(2) NOT NULL
,	[Weekday] TINYINT NOT NULL
,	WeekDayName VARCHAR(10) NOT NULL
,	IsWeekend BIT NOT NULL
,	IsHoliday BIT NOT NULL
,	HolidayText VARCHAR(64) SPARSE
,	DOWInMonth TINYINT NOT NULL
,	[DayOfYear] SMALLINT NOT NULL
,	WeekOfMonth TINYINT NOT NULL
,	WeekOfYear TINYINT NOT NULL
,	ISOWeekOfYear TINYINT NOT NULL
,	[Month] TINYINT NOT NULL
,	[MonthName] VARCHAR(10) NOT NULL
,	[Quarter] TINYINT NOT NULL
,	QuarterName VARCHAR(6) NOT NULL
,	[Year] INT NOT NULL
,	MMYYYY CHAR(6) NOT NULL
,	MonthYear CHAR(7) NOT NULL
,	FirstDayOfMonth DATE NOT NULL
,	LastDayOfMonth DATE NOT NULL
,	FirstDayOfQuarter DATE NOT NULL
,	LastDayOfQuarter DATE NOT NULL
,	FirstDayOfYear DATE NOT NULL
,	LastDayOfYear DATE NOT NULL
,	FirstDayOfNextMonth DATE NOT NULL
,	FirstDayOfNextYear DATE NOT NULL
,	CONSTRAINT [PK_Date] PRIMARY KEY CLUSTERED 
	(
		[DateKey] ASC
	)
)
GO

--=========================================================================
--Creates Procedure for initial load Date Dimension
--=========================================================================
CREATE OR ALTER PROCEDURE sp_GenerateDimensionDate
AS
BEGIN
	DECLARE
		@StartDate DATE = '2001-01-01'
	,	@NumberOfYears INT = 20
	,	@CutoffDate DATE;
	SET @CutoffDate = DATEADD(YEAR, @NumberOfYears, @StartDate);

	-- prevent set or regional settings from interfering with 
	-- interpretation of dates / literals
	SET DATEFIRST 7;
	SET DATEFORMAT mdy;
	SET LANGUAGE US_ENGLISH;

	-- this is just a holding table for intermediate calculations:
	CREATE TABLE #dim
	(
		[Date]       DATE        NOT NULL, 
		[day]        AS DATEPART(DAY,      [date]),
		[month]      AS DATEPART(MONTH,    [date]),
		FirstOfMonth AS CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, 0, [date]), 0)),
		[MonthName]  AS DATENAME(MONTH,    [date]),
		[week]       AS DATEPART(WEEK,     [date]),
		[ISOweek]    AS DATEPART(ISO_WEEK, [date]),
		[DayOfWeek]  AS DATEPART(WEEKDAY,  [date]),
		[quarter]    AS DATEPART(QUARTER,  [date]),
		[year]       AS DATEPART(YEAR,     [date]),
		FirstOfYear  AS CONVERT(DATE, DATEADD(YEAR,  DATEDIFF(YEAR,  0, [date]), 0)),
		Style112     AS CONVERT(CHAR(8),   [date], 112),
		Style101     AS CONVERT(CHAR(10),  [date], 101)
	);

	-- use the catalog views to generate as many rows as we need
	INSERT INTO #dim ([date]) 
	SELECT
		DATEADD(DAY, rn - 1, @StartDate) as [date]
	FROM 
	(
		SELECT TOP (DATEDIFF(DAY, @StartDate, @CutoffDate)) 
			rn = ROW_NUMBER() OVER (ORDER BY s1.[object_id])
		FROM
			-- on my system this would support > 5 million days
			sys.all_objects AS s1
			CROSS JOIN sys.all_objects AS s2
		ORDER BY
			s1.[object_id]
	) AS x;
	-- select * from #dim

	INSERT dbo.[Date] ([DateKey], [Day], [DaySuffix], [Weekday], [WeekDayName], [IsWeekend], [IsHoliday], [HolidayText], [DOWInMonth], [DayOfYear], [WeekOfMonth], [WeekOfYear], [ISOWeekOfYear], [Month], [MonthName], [Quarter], [QuarterName], [Year], [MMYYYY], [MonthYear], [FirstDayOfMonth], [LastDayOfMonth], [FirstDayOfQuarter], [LastDayOfQuarter], [FirstDayOfYear], [LastDayOfYear], [FirstDayOfNextMonth], [FirstDayOfNextYear])
	SELECT
		--DateKey     = CONVERT(INT, Style112),
		[DateKey]        = [date],
		[Day]         = CONVERT(TINYINT, [day]),
		DaySuffix     = CONVERT(CHAR(2), CASE WHEN [day] / 10 = 1 THEN 'th' ELSE 
						CASE RIGHT([day], 1) WHEN '1' THEN 'st' WHEN '2' THEN 'nd' 
						WHEN '3' THEN 'rd' ELSE 'th' END END),
		[Weekday]     = CONVERT(TINYINT, [DayOfWeek]),
		[WeekDayName] = CONVERT(VARCHAR(10), DATENAME(WEEKDAY, [date])),
		[IsWeekend]   = CONVERT(BIT, CASE WHEN [DayOfWeek] IN (1,7) THEN 1 ELSE 0 END),
		[IsHoliday]   = CONVERT(BIT, 0),
		HolidayText   = CONVERT(VARCHAR(64), NULL),
		[DOWInMonth]  = CONVERT(TINYINT, ROW_NUMBER() OVER 
						(PARTITION BY FirstOfMonth, [DayOfWeek] ORDER BY [date])),
		[DayOfYear]   = CONVERT(SMALLINT, DATEPART(DAYOFYEAR, [date])),
		WeekOfMonth   = CONVERT(TINYINT, DENSE_RANK() OVER 
						(PARTITION BY [year], [month] ORDER BY [week])),
		WeekOfYear    = CONVERT(TINYINT, [week]),
		ISOWeekOfYear = CONVERT(TINYINT, ISOWeek),
		[Month]       = CONVERT(TINYINT, [month]),
		[MonthName]   = CONVERT(VARCHAR(10), [MonthName]),
		[Quarter]     = CONVERT(TINYINT, [quarter]),
		QuarterName   = CONVERT(VARCHAR(6), CASE [quarter] WHEN 1 THEN 'First' 
						WHEN 2 THEN 'Second' WHEN 3 THEN 'Third' WHEN 4 THEN 'Fourth' END), 
		[Year]        = [year],
		MMYYYY        = CONVERT(CHAR(6), LEFT(Style101, 2)    + LEFT(Style112, 4)),
		MonthYear     = CONVERT(CHAR(7), LEFT([MonthName], 3) + LEFT(Style112, 4)),
		FirstDayOfMonth     = FirstOfMonth,
		LastDayOfMonth      = MAX([date]) OVER (PARTITION BY [year], [month]),
		FirstDayOfQuarter   = MIN([date]) OVER (PARTITION BY [year], [quarter]),
		LastDayOfQuarter    = MAX([date]) OVER (PARTITION BY [year], [quarter]),
		FirstDayOfYear      = FirstOfYear,
		LastDayOfYear       = MAX([date]) OVER (PARTITION BY [year]),
		FirstDayOfNextMonth = DATEADD(MONTH, 1, FirstOfMonth),
		FirstDayOfNextYear  = DATEADD(YEAR,  1, FirstOfYear)
	FROM #dim
END
GO

DELETE FROM dbo.[Date]
GO

EXEC sp_GenerateDimensionDate
GO

DROP TABLE IF EXISTS #date
CREATE TABLE #date ([Month] tinyint ,[Year] int)

INSERT INTO #date
	SELECT DISTINCT Month,Year
FROM 
	dbo.[Date]
ORDER BY 1,2

GO

INSERT INTO dbo.Salary([EmployeeId], [Month], [Year], [GrossAmount], [NetAmount], [RegularWorkAmount], [BonusAmount], [OvertimeAmount], [VacationDays], [SickLeaveDays])
SELECT
	e.ID as EmployeeID,#date.[Month] as [Month],#date.[Year] as [Year],(30000 + ABS(CHECKSUM(NewID())) % 30000) as GrossAmount,1,1,1,1,1,1
FROM 
	dbo.Employee as e
CROSS JOIN #date
ORDER BY 1,2,3

GO

UPDATE
	dbo.Salary
SET 
	NetAmount =GrossAmount*0.9
GO

UPDATE
	dbo.Salary
SET 
	RegularWorkAmount =NetAmount*0.8
GO

UPDATE
	dbo.Salary
SET 
	BonusAmount =CASE WHEN Month in(1,3,5,7,9,11) THEN (NetAmount-RegularWorkAmount) ELSE 0 END	
GO


UPDATE 
	dbo.Salary
SET 
	OvertimeAmount = CASE WHEN Month in (2,4,6,8,10,12) THEN (NetAmount-RegularWorkAmount) ELSE 0 END
GO

UPDATE 
	dbo.Salary
SET VacationDays =0,
	SickLeaveDays=0
GO

UPDATE 
	dbo.Salary
SET 
	VacationDays =10
WHERE 
	Month in (7,12)
GO

UPDATE 
	dbo.salary 
SET 
	vacationDays = vacationDays + (EmployeeId % 2)
WHERE  
	(employeeId + MONTH+ year)%5 = 1
GO

UPDATE 
	dbo.salary 
SET 
	SickLeaveDays = EmployeeId%8, vacationDays = vacationDays + (EmployeeId % 3)
WHERE  
	(employeeId + MONTH+ year)%5 = 2
GO

SELECT * FROM dbo.SeniorityLevel
SELECT * FROM dbo.[Location]
SELECT * FROM dbo.Department
SELECT * FROM dbo.Employee
SELECT * FROM dbo.Salary



----Checking results
--select * from dbo.salary 
--where NetAmount <> (regularWorkAmount + BonusAmount + OverTimeAmount)





 








