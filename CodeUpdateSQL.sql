--begin VuiPhan 5-2-2020
CREATE DATABASE ShopBanDoTheThaoStage
CREATE DATABASE ExternalSourcesTheThao
CREATE DATABASE ShopBanDoTheThaoDW
USE ShopBanDoTheThaoDW
--abc
--def
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

--end VuiPhan 5-2-2020
--begin VuiPhan 5-3-2020
-- Bắt đầu sử dụng database ShopBanDoTheThaoDW
USE ShopBanDoTheThaoDW
CREATE TABLE DimProductType (
   [ProductTypeKey]  int IDENTITY  NOT NULL
   -- Attributes
,  [ProductTypeID]  INT    NOT NULL
,  [ProductTypeName]  nvarchar(100)   NOT NULL
	-- metadata
,  [RowIsCurrent]  bit  DEFAULT 1 NOT NULL
,  [RowStartDate]  datetime  DEFAULT '12/31/1899' NOT NULL
,  [RowEndDate]  datetime  DEFAULT '12/31/9999' NOT NULL
,  [RowChangeReason]  nvarchar(200)   NULL
, CONSTRAINT pkNorthwindProductType PRIMARY KEY ( [ProductTypeKey] )
);
CREATE TABLE DimProducers (
   [ProducerKey]  int IDENTITY  NOT NULL
   -- Attributes
,  [ProducerID]  INT    NOT NULL
,  [ProducerName]  nvarchar(100)   NOT NULL
,  [Information] NVARCHAR(500)
	-- metadata
,  [RowIsCurrent]  bit  DEFAULT 1 NOT NULL
,  [RowStartDate]  datetime  DEFAULT '12/31/1899' NOT NULL
,  [RowEndDate]  datetime  DEFAULT '12/31/9999' NOT NULL
,  [RowChangeReason]  nvarchar(200)   NULL
, CONSTRAINT pkNorthwindDimProducers PRIMARY KEY ( [ProducerKey] )
);
CREATE TABLE DimMembers (
   [MemberKey]  int IDENTITY  NOT NULL
   -- Attributes
,  [IDMember]  INT    NOT NULL
,  [FullName]  nvarchar(100)   NOT NULL
,  [Address] nvarchar(100)
,  [Email] nvarchar(50)
,  [PhoneNumber] nvarchar(12)
	-- metadata
,  [RowIsCurrent]  bit  DEFAULT 1 NOT NULL
,  [RowStartDate]  datetime  DEFAULT '12/31/1899' NOT NULL
,  [RowEndDate]  datetime  DEFAULT '12/31/9999' NOT NULL
,  [RowChangeReason]  nvarchar(200)   NULL
, CONSTRAINT pkNorthwindDimMembers PRIMARY KEY ( [MemberKey] )
);
CREATE TABLE FactSales (
   [DateKey]  int   NOT NULL
,  [ProductKey]  int   NOT NULL
,  [ProducerKey]  int   NOT NULL
,  [ProductTypeKey]  int   NOT NULL
,  [IDOrder]  int   NOT NULL
	-- dimensions
,  [CustomerKey]  int   NOT NULL
	-- facts
,  [Amount]  int   NOT NULL
,  [Price]  decimal(25,4) NOT NULL
,  [TotalMoney]  decimal(25,4)  DEFAULT 0 NOT NULL
   --keys
, CONSTRAINT pkNorthwindFactSales PRIMARY KEY ( ProductKey, IDOrder,DateKey )

, CONSTRAINT fkNorthwindFactSalesProductKey FOREIGN KEY ( ProductKey )
	REFERENCES DimProduct (ProductKey)

, CONSTRAINT fkNorthwindFactSalesMemberKey FOREIGN KEY ( CustomerKey )
	REFERENCES DimMembers (MemberKey)

, CONSTRAINT fkNorthwindFactSalesProducerKey FOREIGN KEY (ProducerKey )
	REFERENCES dbo.DimProducers(ProducerKey)

, CONSTRAINT fkNorthwindFactSalesProductTypeKey FOREIGN KEY (ProductTypeKey )
	REFERENCES dbo.DimProductType (ProductTypeKey)

, CONSTRAINT fkNorthwindFactSalesDateKey FOREIGN KEY (DateKey)
	REFERENCES DimDate (DateKey)
) 
;

SELECT * FROM dbo.FactSales join dbo.DimDate ON DimDate.DateKey = FactSales.DateKey


-- Kết thức sử dụng database ShopBanDoTheThaoDW
-- Bắt đầu sử dụng database ShopBanDoTheThaoNorthwind
USE ShopBanDoTheThaoNorthwind
GO 
DELETE dbo.DetailImport
DELETE dbo.ImportBill 
DELETE dbo.DetailOrder
DELETE dbo.[Order]
UPDATE dbo.Product SET SalesedQuantity = 0, RemainingQuantity = 0 

GO 
-- Khi nhập hàng sẽ tăng số lượng tồn kho của sản phẩm
CREATE TRIGGER [dbo].[ImportIncreaseRemainingQuantity] ON [dbo].[DetailImport]
FOR INSERT
AS
BEGIN
	DECLARE @maSP INT, @soLuongNhap INT
	SELECT @maSP = Ins.IDProduct,@soLuongNhap = Ins.Amount FROM Inserted AS Ins
	UPDATE dbo.Product
	SET RemainingQuantity += @soLuongNhap
	WHERE ProductID=@maSP
END 

GO 
-- Khi nhập hàng sẽ tăng bên phiếu nhập (TotalQuanlity and TotalMoney)
CREATE TRIGGER [dbo].[ThemSoLuongCuaPN] ON [dbo].[DetailImport]
FOR INSERT
AS
BEGIN
	DECLARE @soLuong INT,@soTien DECIMAL,@MaPN INT
	SELECT @soLuong=Inserted.Amount,@soTien = Inserted.Price,@MaPN=Inserted.IDImport FROM Inserted
	UPDATE dbo.ImportBill
	SET TotalMoney += @soTien*@soLuong ,TotalAmount += @soLuong
	WHERE IDImport = @MaPN
END 
-- Giảm số lượng sản phẩm sau khi đặt hàng
GO 
CREATE TRIGGER [dbo].[GiamSLKhiDatHang] ON [dbo].DetailOrder
AFTER INSERT
AS
BEGIN
	DECLARE @MaSP INT,@SoLuong INT
	SELECT @MaSP=Ins.IDProduct,@SoLuong=Ins.Amount FROM Inserted AS Ins
	UPDATE dbo.Product
	SET RemainingQuantity-=@SoLuong, SalesedQuantity+=@SoLuong
	WHERE ProductID=@MaSP
END

--Insert dữ liệu vào Importbill
GO 
INSERT INTO dbo.ImportBill
        ( TotalMoney ,
          TotalAmount ,
          IDSupplier ,
          DateImport
        )
VALUES  ( 0 , -- TotalMoney - money
          0 , -- TotalAmount - int
          1 , -- IDSupplier - int
          GETDATE()  -- DateImport - datetime
        )
GO 
INSERT INTO dbo.DetailImport
        ( IDImport, IDProduct, Price, Amount )
VALUES  ( 13, -- IDImport - int
          3, -- IDProduct - int
          2150000, -- Price - decimal
          100  -- Amount - int
          )
INSERT INTO dbo.DetailImport
        ( IDImport, IDProduct, Price, Amount )
VALUES  ( 13, -- IDImport - int
          4, -- IDProduct - int
          2150000, -- Price - decimal
          100  -- Amount - int
          )
INSERT INTO dbo.DetailImport
        ( IDImport, IDProduct, Price, Amount )
VALUES  ( 13, -- IDImport - int
          5, -- IDProduct - int
          2150000, -- Price - decimal
          100  -- Amount - int
          )
------------------
INSERT INTO dbo.ImportBill
        ( TotalMoney ,
          TotalAmount ,
          IDSupplier ,
          DateImport
        )
VALUES  ( 0 , -- TotalMoney - money
          0 , -- TotalAmount - int
          2 , -- IDSupplier - int
          GETDATE()  -- DateImport - datetime
        )
GO 
INSERT INTO dbo.DetailImport
        ( IDImport, IDProduct, Price, Amount )
VALUES  ( 14, -- IDImport - int
          6, -- IDProduct - int
          2350000, -- Price - decimal
          45  -- Amount - int
          )
INSERT INTO dbo.DetailImport
        ( IDImport, IDProduct, Price, Amount )
VALUES  ( 14, -- IDImport - int
          7, -- IDProduct - int
          2250000, -- Price - decimal
          50  -- Amount - int
          )
INSERT INTO dbo.DetailImport
        ( IDImport, IDProduct, Price, Amount )
VALUES  ( 14, -- IDImport - int
          8, -- IDProduct - int
          2000000, -- Price - decimal
          55  -- Amount - int
          )
------------------
SELECT * FROM dbo.Product ORDER BY ProductID
SELECT * FROM dbo.ImportBill
SELECT * FROM dbo.DetailImport
SELECT * FROM dbo.Product WHERE ProductID = 3 OR ProductID=4


SELECT * FROM dbo.ImportBill AS I, dbo.DetailImport AS D
WHERE D.IDImport = I.IDImport


GO 
SELECT * FROM dbo.[Order] AS O JOIN dbo.DetailOrder ON DetailOrder.IDOrder = O.IDOrder

INSERT INTO dbo.[Order]
        ( Status ,
          OrderedDate ,
          ConfirmDate ,
          DeliveryDate ,
          DeliveredDate ,
          TotalMoney ,
          TotalAmount ,
          IDMember ,
          Address ,
          PhoneNumber ,
          Email ,
          FullName ,
          Notes
        )
VALUES  ( 4 , -- Status - tinyint
          GETDATE() , -- OrderedDate - datetime
          GETDATE() , -- ConfirmDate - datetime
          GETDATE() , -- DeliveryDate - datetime
          GETDATE() , -- DeliveredDate - datetime
          0 , -- TotalMoney - decimal
          0 , -- TotalAmount - int
          8 , -- IDMember - int
          N'146 Hoàng Diệu 2' , -- Address - nvarchar(100)
          '0984429047' , -- PhoneNumber - varchar(10)
          'phanvui453@gmail.com' , -- Email - varchar(100)
          N'Phan Đăng Vui' , -- FullName - nvarchar(100)
          N'Giao 5 giờ chiều'  -- Notes - nvarchar(max)
        )
INSERT INTO dbo.[Order]
        ( Status ,
          OrderedDate ,
          ConfirmDate ,
          DeliveryDate ,
          DeliveredDate ,
          TotalMoney ,
          TotalAmount ,
          IDMember ,
          Address ,
          PhoneNumber ,
          Email ,
          FullName ,
          Notes
        )
VALUES  ( 4 , -- Status - tinyint
          GETDATE() , -- OrderedDate - datetime
          GETDATE() , -- ConfirmDate - datetime
          GETDATE() , -- DeliveryDate - datetime
          GETDATE() , -- DeliveredDate - datetime
          0 , -- TotalMoney - decimal
          0 , -- TotalAmount - int
          8 , -- IDMember - int
          N'146 Hoàng Diệu 2' , -- Address - nvarchar(100)
          '0984429047' , -- PhoneNumber - varchar(10)
          'phanvui453@gmail.com' , -- Email - varchar(100)
          N'Phan Đăng Vui' , -- FullName - nvarchar(100)
          N'Giao 5 giờ chiều'  -- Notes - nvarchar(max)
        )

GO 
INSERT INTO dbo.DetailOrder
        ( IDOrder, IDProduct, Amount, Price )
VALUES  ( 36, -- IDOrder - int
          4, -- IDProduct - int
          1, -- Amount - int
          2150000  -- Price - decimal
          )
INSERT INTO dbo.DetailOrder
        ( IDOrder, IDProduct, Amount, Price )
VALUES  ( 36, -- IDOrder - int
          5, -- IDProduct - int
          1, -- Amount - int
          2150000  -- Price - decimal
          )
INSERT INTO dbo.DetailOrder
        ( IDOrder, IDProduct, Amount, Price )
VALUES  ( 36, -- IDOrder - int
          6, -- IDProduct - int
          2, -- Amount - int
          2150000  -- Price - decimal
          )
INSERT INTO dbo.DetailOrder
        ( IDOrder, IDProduct, Amount, Price )
VALUES  ( 37, -- IDOrder - int
          8, -- IDProduct - int
          10, -- Amount - int
          2150000  -- Price - decimal
          )
SELECT * FROM dbo.Product WHERE ProductID = 8
SELECT * FROM dbo.DetailOrder WHERE IDProduct=8
SELECT * FROM dbo.StatusOrder
SELECT * FROM dbo.Member
GO 
DELETE dbo.Review
SELECT * FROM dbo.Review
SELECT        [Order].IDOrder, DetailOrder.IDProduct,
 [Order].DeliveryDate, DetailOrder.Amount, DetailOrder.Price, [Order].IDMember, 
 [Order].Address, [Order].PhoneNumber, [Order].FullName, Review.Message, Review.Star
FROM DetailOrder INNER JOIN
                         [Order] ON DetailOrder.IDOrder = [Order].IDOrder LEFT JOIN
                         Review ON [Order].IDOrder = Review.IDOrder AND Review.IDProduct = DetailOrder.IDProduct

INSERT INTO dbo.Review
        ( IDMember ,
          FullName ,
          IDProduct ,
          Star ,
          Image ,
          Message ,
          Date,
		  IDOrder
        )
VALUES  ( 8 , -- IDMember - int
          N'Phan Đăng Vui' , -- FullName - nvarchar(100)
          3 , -- IDProduct - int
          5 , -- Star - int
          N'' , -- Image - nvarchar(max)
          N'Sản phẩm tốt' , -- Message - nvarchar(250)
          GETDATE(),  -- Date - datetime,
		  36
        )

-- Kết thúc sử dụng database ShopBanDoTheThaoNorthwind
-- end VuiPhan 3-5-2020





