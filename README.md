# CuoiKy
--begin VuiPhan 5-2-2020
CREATE DATABASE ShopBanDoTheThaoStage
CREATE DATABASE ExternalSourcesTheThao
CREATE DATABASE ShopBanDoTheThaoDW
USE ShopBanDoTheThaoDW

CREATE  TABLE  DimProduct
(
	ProductKey int identity not null,
	-- attributes
	ProductID int not null, 
	ProductName nvarchar(40) not null,
	Discontinued nchar(1) default('N') not null,
	SupplierName nvarchar(40) not null,
	CategoryName nvarchar(15) not null,
	ProducerName nvarchar(100) NOT NULL,
	ProductTypeName nvarchar(100) NOT NULL, 
	-- metadata
	RowIsCurrent bit default(1) not null,
	RowStartDate datetime default('1/1/1900') not null,
	RowEndDate datetime default('12/31/9999') not null,
	RowChangeReason nvarchar(200) default ('N/A') not null,
	-- keys
	CONSTRAINT  pkNorthwindDimProductKey primary key (ProductKey),	
);
CREATE TABLE [DimDate](
	[DateKey] [int] NOT NULL,
	[Date] [datetime] NULL,
	[DayOfWeek] [tinyint] NOT NULL,
	[DayName] [varchar](9) NOT NULL,
	[DayOfMonth] [tinyint] NOT NULL,
	[DayOfYear] [smallint] NOT NULL,
	[WeekOfYear] [tinyint] NOT NULL,
	[MonthName] [varchar](9) NOT NULL,
	[MonthOfYear] [tinyint] NOT NULL,
	[Quarter] [tinyint] NOT NULL,
	[Year] [smallint] NOT NULL,
	[IsAWeekday] varchar(1) NOT NULL DEFAULT (('N')),
	constraint pkNorthwindDimDate PRIMARY KEY ([DateKey])
)



-- code để load vào stage Products
--thêm stg 
USE ShopBanDoTheThaoNorthwind
SELECT Product.ProductID, Product.ProductName, Product.Price, 
Product.SalesedQuantity, Product.RemainingQuantity, Product.Discontinued, 
Producer.ProducerName, ProductType.ProductTypeName, Supplier.NameSupplier
FROM Producer INNER JOIN
                         Product ON Producer.ProducerID = Product.ProducerID INNER JOIN
                         ProductType ON Product.ProductTypeID = ProductType.ProductTypeID INNER JOIN
                         Supplier ON Product.SupplierID = Supplier.IDSupplier

--end VuiPhan 5-2-2021

