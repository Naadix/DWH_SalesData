-- create datawarhouse database and use DWH_SalesData 

IF DB_ID('DWH_SalesData') IS NULL
BEGIN 
	CREATE DATABASE DWH_SalesData;
END
GO

USE DWH_SalesData;
GO

-- create schemas --

-- create bronze schema 
IF NOT EXISTS (
	SELECT 1 FROM sys.schemas
	WHERE name = 'bronze'
)
BEGIN
	EXEC('CREATE SCHEMA bronze');
END
GO

-- create silver schema
IF NOT EXISTS (
	SELECT 1 FROM sys.schemas
	WHERE name = 'silver'
)
BEGIN
	EXEC('CREATE SCHEMA silver');
END
GO

-- create gold schema 
IF NOT EXISTS (
	SELECT 1 FROM sys.schemas
	WHERE name = 'gold'
)
BEGIN 
	EXEC('CREATE SCHEMA gold')
END
GO