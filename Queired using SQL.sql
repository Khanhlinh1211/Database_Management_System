
-- LAB 01 - Giới thiệu truy vấn căn bản
-- Sử dụng database Northwind
USE Northwind;

-- 1. Truy vấn danh sách các Customer
SELECT * 
FROM Customer

--2. Truy vấn danh sách các Customer theo các thông tin Id, FullName (là kết hợp FirstName-LastName), City, Country
SELECT Id, 
	   CONCAT(FirstName,' ',LastName) as FullName, 
	   City, Country 
FROM Customer

--3. Cho biết có bao nhiêu khách hàng từ Germany và UK, đó là những khách hàng nào
SELECT *
FROM Customer 
WHERE Country in ('Germany','UK')

SELECT Count(Id) as 'Number of Customers from Germany and UK'
FROM Customer
WHERE Country in ('Germany','UK')

--4. Liệt kê danh sách khách hàng theo thứ tự tăng dần của FirstName và giảm dần của Country
SELECT * 
FROM Customer
ORDER BY FirstName asc, Country desc

--5. Truy vấn danh sách các khách hàng với ID là 5,10, từ 1-10, và từ 5-10
-- 5.1) Id bằng 5 hoặc 10
SELECT *
FROM Customer
WHERE Id in (5,10)
--5.2) Id từ 1-10 (sử dụng TOP N vì bảng Customer 'Id' đã được sắp xếp theo thứ tư tăng dần)
SELECT TOP 10 *
FROM Customer
--5.3) Id từ 5 đến 10 
-- Sử dụng OFFSET bắt buộc phải có ORDER BY, FETCH tuỳ chọn 
SELECT *
FROM Customer
ORDER BY Id
OFFSET 4 ROWS
FETCH NEXT 6 ROWS ONLY

--5.4 Truy vấn các khách hàng ở các sản phẩm (Product) mà đóng gói dưới dạng bottles có giá từ 15 đến 20 mà không từ nhà cung cấp có ID là 16. 
SELECT *
FROM Customer as c
WHERE Id in (SELECT Id
			 FROM Product as p
			 WHERE p.Package like '%bottles%'
				   and p.UnitPrice between 15 and 20
				   and NOT p.Id=16
			)

--LAB 02 – Truy Vấn Căn Bản (Tiếp theo)
--1. Xuất danh sách các nhà cung cấp (gồm Id, CompanyName, ContactName, City, Country, Phone) kèm theo giá min và max của các sản phẩm mà nhà cung cấp đó cung cấp. Có sắp xếp theo thứ tự Id của nhà cung cấp (Gợi ý : Join hai bản Supplier và Product, dùng GROUP BY tính Min, Max)
SELECT s.Id, s.CompanyName, s.ContactName, s.City, s.Country, s.Phone,
	   min(p.UnitPrice) as minPrice,
	   max(p.UnitPrice) as maxPrice
FROM Supplier as s
INNER JOIN Product as p
ON s.Id=p.SupplierId
GROUP BY s.Id, s.CompanyName, s.ContactName, s.City, s.Country, s.Phone
ORDER BY s.Id

--2. Cũng câu trên nhưng chỉ xuất danh sách nhà cung cấp có sự khác biệt giá (max – min) không quá lớn (<=30).(Gợi ý: Dùng HAVING)
SELECT s.Id, s.CompanyName, s.ContactName, s.City, s.Country, s.Phone,
	   min(p.UnitPrice) as minPrice,
	   max(p.UnitPrice) as maxPrice
FROM Supplier as s
INNER JOIN Product as p
ON s.Id=p.SupplierId
GROUP BY s.Id, s.CompanyName, s.ContactName, s.City, s.Country, s.Phone
HAVING max(p.UnitPrice)<=30 and min(p.UnitPrice)<=30
ORDER BY s.Id

--3. Xuất danh sách các hóa đơn (Id, OrderNumber, OrderDate) kèm theo tổng giá chi trả (UnitPrice*Quantity) cho hóa đơn đó, bên cạnh đó có cột Description là “VIP” nếu tổng giá lớn hơn 1500 và “Normal” nếu tổng giá nhỏ hơn 1500(Gợi ý: Dùng UNION)
SELECT o.Id,o.OrderNumber,o.OrderDate,
	   oi.UnitPrice*oi.Quantity as TotalCost,
	   'VIP' as [Description]
FROM [Order] as o
INNER JOIN OrderItem as oi
ON o.Id=oi.OrderId
WHERE  oi.UnitPrice*oi.Quantity>1500

UNION

SELECT o.Id,o.OrderNumber,o.OrderDate,
	   oi.UnitPrice*oi.Quantity as TotalCost,
	   'Normal' as [Description]
FROM [Order] as o
INNER JOIN [OrderItem] as oi
ON o.Id=oi.OrderId
WHERE  oi.UnitPrice*oi.Quantity<=1500

--4. Xuất danh sách những hóa đơn (Id, OrderNumber, OrderDate) trong tháng 7 nhưng phải ngoại trừ ra những hóa đơn từ khách hàng France. (Gợi ý: dùng EXCEPT)
SELECT o.Id,o.OrderNumber,o.OrderDate, CONCAT(c.FirstName,' ',c.LastName) as FullName, c.Country
FROM [Order] as o
INNER JOIN Customer as c
ON c.Id=o.CustomerId
WHERE MONTH(OrderDate)=07

EXCEPT

SELECT o.Id,o.OrderNumber,o.OrderDate, CONCAT(c.FirstName,' ',c.LastName) as FullName, c.Country
FROM Customer as c
INNER JOIN [Order] as o
ON c.Id=o.CustomerId
WHERE c.Country like 'France'

--5. Xuất danh sách những hóa đơn (Id, OrderNumber, OrderDate, TotalAmount)  nào có TotalAmount nằm trong top 5 các hóa đơn. (Gợi ý : Dùng IN)
SELECT Id, OrderNumber, OrderDate, TotalAmount
FROM [Order] 
WHERE TotalAmount in (SELECT TOP 5 TotalAmount
					  FROM [Order]
					  ORDER BY TotalAmount DESC
					  )

--LAB 3 – Truy Vấn Nâng Cao (Phần 1)
-- 1. Sắp xếp sản phẩm tăng dần theo UnitPrice, và tìm 20% dòng có UnitPrice cao nhất (Lưu ý: Dùng ROW_NUMBER )
SELECT *
FROM
( 
   SELECT RowNum, Id,OrderId,ProductId,max(RowNum) OVER (ORDER BY (SELECT 2)) as Rowlast
   FROM (
       SELECT ROW_NUMBER() OVER (ORDER BY Quantity) as RowNum,
	   Id,OrderId,ProductId
       FROM OrderItem
   ) as DerivedTable
) Report, Product as P
WHERE Report.RowNum >= 0.2*Rowlast and P.Id=Report.ProductId



-- 2. Với mỗi hóa đơn, xuất danh sách các sản phẩm, số lượng (Quantity) và số phần trăm của sản phẩm đó trong hóa đơn. 
-- (Gợi ý: ta lấy Quantity chia cho tổng Quantity theo hóa đơn * 100 + ‘%’. Dùng SUM … OVER)
SELECT ProductId, P.ProductName,P.Package,P.UnitPrice,Quantity,STR([Percent]*100,5,2) + '%' as [Percent]
FROM
( 
   SELECT ProductId,P.ProductName,P.Package, P.UnitPrice,Quantity,
   Quantity / (sum(Quantity) OVER (Partition by ProductId)) As [Percent]
   FROM[OrderItem],Product as P
) Report,Product as P
WHERE Report.ProductId=P.Id
ORDER BY ProductId

-- 3. Xuất danh sách các nhà cung cấp kèm theo các cột USA, UK, France, Germany, Others. 
-- Nếu nhà cung cấp nào thuộc các quốc gia  này thì ta đánh số 1 còn lại là 0 
-- (Gợi ý: Tạo bảng tạm theo chiều dọc trước với tên nhà cung cấp và thuộc quốc gia USA, UK, France, Germany hay Others. 
-- Sau đó PIVOT bảng tạm này để tạo kết quả theo chiều ngang)
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME=N'F')
begin 
    TRUNCATE TABLE F
end

 SELECT ContactName,(CASE 
	      When Country like 'Japan' then 'Others'
		  When Country like 'Spain' then 'Others'
		  When Country like 'Australia' then 'Others'
		  When Country like 'Italy' then 'Others'
		  When Country like 'Norway' then 'Others'
		  When Country like 'Sweden' then 'Others'
		  When Country like 'Singapore' then 'Others'
		  When Country like 'Denmark' then 'Others'
		  When Country like 'Netherlands' then 'Others'
		  When Country like 'Finland' then 'Others'
		  When Country like 'Canada' then 'Others'
		  When Country like 'UK' then 'UK'
		  When Country like 'USA' then 'USA'
		  When Country like 'Germany' then 'Germany'
		  When Country like 'France' then 'France'
		  When Country like 'Brazil' then 'Others'
	  End) as SupplierCountry
INTO F
FROM [Supplier]
  
SELECT *
FROM 
(SELECT ContactName, SupplierCountry, (CASE 
	      When SupplierCountry like 'Others' then '0'
		  When SupplierCountry like 'USA' then '1'
		  When SupplierCountry like 'UK' then '1'
		  When SupplierCountry like 'Germany' then '1'
		  When SupplierCountry like 'France' then '1'
	  End) as [Request] 
 FROM F
)as SOURCE_TABLE
PIVOT 
(
  max(SupplierCountry) for Request in ([0],[1])
) as B

-- 4. Xuất danh sách các hóa đơn gồm OrderNumber, OrderDate (format: dd mm yyyy), CustomerName, Address 
-- (format: “Phone: …… , City: …. and Country: ….”), TotalAmount làm tròn không chữ số thập phân và đơn vị theo kèm là Euro) 
SELECT OrderNumber,
       OrderDate=CONVERT(varchar(10),O.OrderDate,104),
       C.FirstName +' '+C.LastName as CustomerName,
	   Address='Phone' + ':' + SPACE(1)+ C.Phone + ',' +SPACE(1) + 'City' +':'+ SPACE(1)+C.City+SPACE(1)+ 'and' 
	   +SPACE(1)+'Country'+':'+SPACE(1)+C.Country,
	   TotalAmount=LTRIM(STR(CAST(O.TotalAmount as DECIMAL(10,0)),10,1)+SPACE(1)+'EUR')
FROM [Order] O
INNER JOIN [Customer] as C ON O.CustomerId=C.Id

-- 5. Xuất danh sách các sản phẩm dưới dạng đóng gói bags. Thay đổi chữ bags thành ‘túi’ 
-- (Lưu ý: để dùng tiếng việt có dấu ta ghi chuỗi dưới dạng N’túi’)
SELECT Id, ProductName, SupplierId, UnitPrice, 
       Package=STUFF(Package,CHARINDEX('bags',Package), len('bags'),N'Túi')
FROM Product
WHERE Package like '%bags%'

--6. Xuất danh sách các khách hàng theo tổng số hóa đơn mà khách hàng đó có, 
-- sắp xếp theo thứ tự giảm dần của tổng số hóa đơn,  kèm theo đó là  các thông tin phân hạng DENSE_RANK 
--và nhóm (chia thành 3 nhóm) (Gợi ý: dùng NTILE(3) để chia nhóm). 
SELECT OrderNumber,
       OrderDate=CONVERT(varchar(10),O.OrderDate,104),
       C.FirstName +' '+C.LastName as CustomerName,
	   Address='Phone' + ':' + SPACE(1)+ C.Phone + ',' +SPACE(1) + 'City' +':'+ SPACE(1)+C.City+SPACE(1)+ 'and' 
	   +SPACE(1)+'Country'+':'+SPACE(1)+C.Country,
	   [Rank]=DENSE_RANK() over (ORDER BY TotalAmount),
	   NTILE(3) OVER(
		ORDER BY TotalAmount DESC
	) [group]
FROM [Order] O
INNER JOIN [Customer] as C ON O.CustomerId=C.Id
ORDER BY TotalAmount DESC 

--LAB 4 – Truy Vấn Nâng Cao (Phần 2)
--1. Theo mỗi  OrderID cho biết số lượng Quantity của mỗi ProductID chiếm tỷ lệ bao nhiêu phần trăm
SELECT OrderId,ProductId, Quantity,
       SUM(Quantity) over (partition by ProductId) as QuantityByOrderId,
	   CAST ((Quantity / SUM(Quantity) over (partition by ProductId) *100)
	   as decimal(6,2)) as PercentByOrder
FROM [OrderItem] 
ORDER BY ProductId

--2. Xuất các hóa đơn kèm theo thông tin ngày trong tuần của hóa đơn là : Thứ 2, 3,4,5,6,7, Chủ Nhật
SELECT *,DATENAME(dw, OrderDate) AS [Day Name]
FROM [Order]

--3. Với mỗi ProductID trong OrderItem xuất các thông tin gồm OrderID, ProductID, ProductName, UnitPrice, Quantity, ContactInfo, ContactType. Trong đó ContactInfo ưu tiên Fax, nếu không thì dùng Phone của Supplier sản phẩm đó. Còn ContactType là ghi chú đó là loại ContactInfo nào
SELECT O.OrderId,O.ProductId,P.ProductName,P.UnitPrice,O.Quantity,
       COALESCE(Fax,Phone) as ContactInfo,
	   case COALESCE(Fax,Phone) when Fax then 'Fax' else 'Phone' end as ContactType
FROM [Supplier] S, [OrderItem] O
INNER JOIN [Product] P ON O.ProductId=P.Id

--4. Cho biết Id của database Northwind, Id của bảng Supplier, Id của User mà bạn đang đăng nhập là bao nhiêu. Cho biết luôn tên User mà đang đăng nhập
SELECT DB_ID('Northwind') as [Northwind], OBJECT_ID('Supplier') as [Supplier],
	   USER_ID() as [UserID], USER_NAME(1) as [UserName]

--5. Cho biết các thông tin user_update, user_seek, user_scan và user_lookup trên bảng Order trong database Northwind
SELECT [TableName] = OBJECT_NAME( object_id),
		user_updates, user_seeks, user_scans, user_lookups
FROM sys.dm_db_index_usage_stats as SIUS
WHERE database_id = DB_ID('Northwind')
and OBJECT_NAME( object_id)='Order'

--6. Dùng WITH phân chia cây như sau : Mức 0 là các Quốc Gia(Country), mức 1 là các Thành Phố (City) thuộc Country đó, và mức 2 là các Hóa Đơn (Order) thuộc khách hàng từ Country-City đó

WITH SupplierCategory(Country,City,Id,alevel)
AS(
   SELECT DISTINCT Country,
   City=CAST('' as nvarchar(255)),
   Id=CAST('' as varchar(255)),
   alevel=0
   FROM Supplier

   UNION ALL 

   SELECT S.Country,
   City=CAST(S.City as nvarchar(255)),
   Id=CAST('' as varchar(255)),
   alevel=SC.alevel+1
   FROM SupplierCategory as SC 
   INNER JOIN Supplier S ON SC.Country=S.Country
   WHERE SC.alevel=0

   UNION ALL 

   SELECT S.Country,
   City=CAST(S.City AS nvarchar(255)),
   Id=CAST(S.Id AS varchar(255)),
   alevel=SC.alevel+1
   FROM SupplierCategory as SC 
   INNER JOIN Supplier S ON SC.Country=S.Country and SC.City=S.Country
   WHERE SC.alevel=1
)
SELECT [Quoc Gia]= case when alevel=0 then Country else '--'end,
       [Thanh Pho]= case when alevel=1 then City else '--'end,
	   [Hoa Don]= Id,
	   Cap=alevel
FROM SupplierCategory
ORDER BY Country, City,Id,alevel

--7. Xuất những hóa đơn từ khách hàng France mà có tổng số lượng Quantity lớn hơn 50 của các sản phẩm thuộc hóa đơn ấy 
WITH QuantityFill as
(
     SELECT OI.Quantity
	 FROM [OrderItem] OI
	 INNER JOIN [Order] O ON O.Id=OI.OrderId
	 WHERE OI.Quantity > 50
),
CustomerFromFrance as
(     
     SELECT C.*
	 FROM Customer as C
	 INNER JOIN [Order] O ON O.CustomerId=C.Id
	 WHERE Country='France'
)
SELECT *
FROM CustomerFromFrance, QuantityFill as Q

-- LAB 5 – Sử dụng View trong SQL
--1. Tạo các view sau :
--a. uvw_DetailProductInOrder với các cột sau OrderId, OrderNumber, OrderDate, ProductId, 
-- ProductInfo ( = ProductName + Package. Ví dụ: Chai 10 boxes x 20 bags), UnitPrice và Quantity
CREATE VIEW uvw_DetailProductInOrder
as
   SELECT OI.OrderId,O.OrderNumber,O.OrderDate,OI.ProductId,
          ProductInfo=P.ProductName + SPACE(1) + P.Package,
		  OI.UnitPrice,OI.Quantity
   FROM [Order] O, [Product] P,[OrderItem] as OI 
   WHERE OI.OrderId=O.Id and OI.ProductId=P.Id
GO
SELECT * FROM uvw_DetailProductInOrder

--b. uvw_AllProductInOrder với các cột sau OrderId, OrderNumber, OrderDate, ProductList (ví dụ “11,42,72” với OrderId 1), 
-- và TotalAmount ( = SUM(UnitPrice * Quantity)) theo mỗi OrderId  (Gợi ý dùng FOR XML PATH để tạo cột ProductList)
CREATE VIEW uvw_AllProductInOrder
as
	SELECT D.OrderId, D.OrderNumber, D.OrderDate,
		   SUBSTRING
		   (	
		     (
				SELECT ','+ CONVERT(nvarchar(10), OI.ProductId )
				FROM OrderItem as OI
				WHERE OI.OrderId= D.OrderId
				for xml path('')
			 ),2,1000
		   )ProductList,
				sum( D.UnitPrice* D.Quantity) as [TotalAmount]
	FROM uvw_DetailProductInOrder as D
	GROUP BY D.OrderId, D.OrderNumber, D.OrderDate
GO
SELECT *
FROM uvw_AllProductInOrder


--2. Dùng view “uvw_DetailProductInOrder“ truy vấn những thông tin có OrderDate trong tháng 7 
SELECT *
FROM uvw_DetailProductInOrder
WHERE Month(OrderDate)=07

--3. Dùng view “uvw_AllProductInOrder” truy vấn những hóa đơn Order có ít nhất 3 product trở lên
SELECT * 
FROM uvw_AllProductInOrder
WHERE (LEN(ProductList) - LEN(replace(ProductList,',',''))+1)>=3

--4. Hai view trên đã readonly chưa ? Có những cách nào làm hai view trên thành readonly ?
CREATE TRIGGER dbo.uvw_DetailProductInOrder_Trigger_OnInsertOrUpdateOrDelete
on uvw_DetailProductInOrder
instead of insert,update,delete
as
begin
      raiserror ('You are not allow to update this view !',16,1)
end

CREATE TRIGGER dbo.uvw_uvw_AllProductInOrder_Trigger_OnInsertOrUpdateOrDelete
on uvw_AllProductInOrder
instead of insert,update,delete
as
begin
      raiserror ('You are not allow to update this view !',16,1)
end
--5. Thống kê về thời gian thực thi khi gọi hai view trên. View nào chạy nhanh hơn ? 
SET STATISTICS IO ON 
SET STATISTICS TIME ON 
GO

SELECT * FROM uvw_DetailProductInOrder
GO
SELECT * FROM uvw_AllProductInOrder
GO

SET STATISTICS IO OFF 
SET STATISTICS TIME OFF 
GO

--LAB 6 – Sử dụng Function trong SQL
--1. Viết hàm truyền vào một CustomerId và xuất ra tổng giá tiền (Total Amount)của các hóa đơn từ khách hàng đó. 
-- Sau đó dùng hàm này xuất ra tổng giá tiền từ các hóa đơn của tất cả khách hàng
CREATE FUNCTION ufn_TotalAmountByCustomer(@customerId int = 0)
Returns decimal(12,2)
as
begin
	declare @TotalAmount decimal(12,2)

	SELECT @TotalAmount=sum(o.TotalAmount)
	FROM [Order] as o
	WHERE o.CustomerId = @customerId

	return @TotalAmount
end

SELECT *, dbo.ufn_TotalAmountByCustomer(c.Id) as [TotalAmountByCustomer]
FROM Customer as c

--2. Viết hàm truyền vào hai số và xuất ra danh sách các sản phẩm có UnitPrice nằm trong khoảng hai số đó. 
CREATE FUNCTION ufn_ProductInRange(@min  decimal(12,2) = 0, @max  decimal(12,2) = 0)
Returns table
as
Return(
	SELECT *
	FROM Product as p
	WHERE p.UnitPrice >= @min and p.UnitPrice <= @max
)

SELECT * FROM ufn_ProductInRange(5,50)

--3. Viết hàm truyền vào một danh sách các tháng 'June;July;August;September' 
-- và xuất ra thông tin của các hóa đơn có trong những tháng đó. Viết cả hai hàm dưới dạng inline và multi statement sau đó cho biết thời gian thực thi của mỗi hàm, so sánh và đánh giá

CREATE FUNCTION ufn_OrderByMonths(@monthFilter nvarchar(max))
Returns @ResultTable Table (Id int, OrderDate datetime, OrderNumber nvarchar(max), CustomerId int, TotalAmount decimal(12,2))
as 
begin
	Set @monthFilter=LOWER(@monthFilter)

	Insert into @ResultTable
	SELECT Id, OrderDate, OrderNumber,CustomerId, TotalAmount
	FROM [Order]
	WHERE CHARINDEX(LTRIM(RTRIM( LOWER(DATENAME(MONTH, DATEADD(MONTH, 0, OrderDate))))),@monthFilter) > 0
	Return
end

CREATE FUNCTION ufn_OrderByMonths2(@monthFilter nvarchar(max))
Returns table
as 
Return
(
	SELECT * 
	FROM [Order] as o
	WHERE CHARINDEX(LTRIM(RTRIM(LOWER(DATENAME(MONTH, DATEADD(MONTH, 0, OrderDate))))),LOWER(@monthFilter)) > 0
)

Set STATISTICS TIME on
SELECT * FROM ufn_OrderByMonths('June;July;August;September')
SELECT * FROM ufn_OrderByMonths2('June;July;August;September')
Set STATISTICS TIME off

--4. Viết hàm kiểm tra mỗi hóa đơn không có quá 5 sản phẩm (kiểm tra trong bảng OrderItem).
-- Nếu insert quá 5 sản phẩm cho một hóa đơn thì báo lỗi và không cho insert. 

CREATE FUNCTION ufn_CheckItemQuantity(@Id int)
Returns BIT
as 
	begin
		Declare @OverNumber BIT;

		IF((Select count(oi.Id) From OrderItem as oi Where oi.OrderId=@Id)<=5)
			set @OverNumber=1;
		ELSE
			set @OverNumber=0;
		Return @OverNumber;
	end
GO

ALTER TABLE OrederItem
ADD CONSTRAINT CheckNumberOfItem
	CHECK (dbo.ufn_CheckItemQuantity(OrderId)=1);  
  
Set Identity_Insert [OrderItem] on
Insert INTO OrderItem Values(2156, 830,1,18.00,6)
Set Identity_Insert [OrderItem] off

--LAB 7 – Trigger-Transaction-Cursor-Temp Table
-- 1. Trigger
-- Viết trigger khi xóa một OrderId thì xóa luôn các thông tin của Order đó trong bảng OrderItem. 
GO
CREATE TRIGGER [dbo].[Trigger_OrderItemDelete]
on [dbo].[Order]
For delete 
as 

declare @DeletedOrderId int
select @DeletedOrderId = Id From deleted

Delete From [Order] Where Id = @DeletedOrderId
Delete From OrderItem Where OrderId = @DeletedOrderId

Print'Order, OrderItem with OrderId = '+LTRIM(RTRIM(@DeletedOrderId))+' have been deleted'

-- Nếu có Foreign Key Constraint xảy ra không cho xóa thì hãy xóa Foreign Key Constraint đó đi rồi thực thi. 

ALTER TABLE OrderItem drop constraint FK_ORDERITE_REFERENCE_ORDER

delete from [Order] where Id = 1
delete from [Order] where Id = 2
GO
SELECT * FROM [Order]
ORDER BY Id
SELECT * FROM [OrderItem]
ORDER BY OrderId


-- Viết trigger khi xóa hóa đơn của khách hàng Id = 1 thì báo lỗi không cho xóa sau đó ROLL BACK lại. 
-- Lưu ý: Đưa trigger này lên làm Trigger đầu tiên thực thi xóa dữ liệu trên bảng Order
GO
CREATE TRIGGER [dbo].[Trigger_CustomerIdDelete]
on [dbo].[Order]
for delete
as 
	declare @DeleteCustomerId int
	select @DeleteCustomerId = CustomerId From deleted

	If(@DeleteCustomerId=1)
	begin
		Raiserror('CustomerId = 1 cant be deleted',16,1);
		Rollback transaction
	end
GO
delete from [Order] where CustomerId=1

-- Viết trigger không cho phép cập nhật Phone là NULL hay trong Phone có chữ cái ở bảng Supplier. Nếu có thì báo lỗi và ROLL BACK lại
GO
CREATE TRIGGER [dbo].[SupplierPhoneUpdate]
on [dbo].[Supplier]
for update
as 
	declare @UpdatePhone nvarchar(30)
	if update(Phone)
	begin 
		Select @UpdatePhone = Phone From inserted
		If @UpdatePhone=null or @UpdatePhone ='NULL'
		Begin 
			Raiserror ('Phone must be a phone number',16,1);
			Rollback transaction
		End
	end

Update Supplier Set Phone ='NULL' Where Id = 1

--2. CURSOR
-- Viết một function với input vào Country và xuất ra danh sách các Id và Company Name ở thành phố đó theo dạng sau 
-- INPUT : ‘USA’
-- OUTPUT : Companies in USA are : New Orleans Cajun Delights(ID:2) ; Grandma Kelly's Homestead(ID:3) ...
GO
CREATE FUNCTION dbo.ufn_ListCompanyByCountry (@CountryDescr nvarchar(MAX))
Returns nvarchar(MAX)
as 
begin
	Declare @CompanyList nvarchar(MAX) = 'Companies in ' + @CountryDescr + ' are: ';
	Declare @Id int;
	Declare @CompanyName nvarchar(MAX);

	Declare CompanyCursor Cursor READ_ONLY
	For
	Select Id, CompanyName
	From Supplier
	Where Lower(Country) = RTRIM(LTRIM(LOWER(@CountryDescr)))
	
	Open CompanyCursor

	Fetch next From CompanyCursor into @Id, @CompanyName

	While @@FETCH_STATUS=0
	Begin
		Set @CompanyList = @CompanyList + @CompanyName + '(ID:' + LTRIM(STR(@Id)) + ')' + '; ';
		FETCH NEXT FROM CompanyCursor into @Id, @CompanyName
	End
	
	Close CompanyCursor
	Deallocate CompanyCursor

	Return @CompanyList
end
GO
SELECT dbo.ufn_ListCompanyByCountry('USA')

--3. Transaction:
-- Viết các dòng lệnh cập nhật Quantity của các sản phẩm trong bảng OrderItem mà có OrderID được đặt từ khách hàng USA. 
-- Quantity được cập nhật bằng cách input vào một @DFactor sau đó Quantity được tính theo công thức 
-- Quantity = Quantity / @DFactor. Ngoài ra còn xuất ra cho biết số lượng hóa đơn đã được cập nhật. 
-- (Sử dụng TRANSACTION để đảm bảo nếu có lỗi xảy ra thì ROLL BACK lại)

Begin try
	Begin Transaction UpdateQuantityTrans

		Set nocount on;

		Declare @NumOfUpdateRecords int =0;
		Declare @DFactor int;
		Set @DFactor=2;

		Update oi Set oi.Quantity = oi.Quantity / @DFactor
		From OrderItem oi
		inner join [Order] o on oi.OrderId = o.Id inner join Customer as c on o.CustomerId = c.Id
		Where c.Country like '%USA%'

		Set @NumOfUpdateRecords = @@ROWCOUNT
		Print 'Update successful. There are ' + LTRIM(RTRIM(@NumOfUpdateRecords)) + ' rows in OrderItem table';

	COMMIT TRANSACTION UpdateQuantityTrans
End try
Begin catch
	Rollback tran UpdateQuantityTran
	Print 'Update faile. See detail: ';
	Print ERROR_MESSAGE();
End catch

--4. Temp Table:
-- Viết TRANSACTION với Input là hai quốc gia. 
-- Sau đó xuất thông tin là quốc gia nào có số sản phẩm cung cấp (thông qua SupplierId) nhiều hơn. 
-- Cho biết luôn số lượng số sản phẩm cung cấp của mỗi quốc gia. Sử dụng cả hai dạng bảng tạm (# và @) 
Begin try
Begin transaction CompareTwoCountriesTrans

	Set nocount on
	declare @Country1 nvarchar(MAX)
	declare @Country2 nvarchar(MAX)

	set @Country1 = 'USA';
	set @Country2= 'UK';

	CREATE TABLE #CountryInfo1 --Create a physical table
	(
		Id int,
		ProductName nvarchar(50),
		SupplierId int
	)
	Declare @CountryInfo2 Table
	(
		Id int,
		ProductName nvarchar(50),
		SupplierId int
	)

	Insert into #CountryInfo1
	SELECT p.Id, p.ProductName, p.SupplierId
	FROM Product p inner join Supplier s on p.SupplierId = s.Id
	WHERE Lower(s.Country) = LTRIM(RTRIM(LOWER(@Country1)))
	
	Insert into @CountryInfo2
	SELECT p.Id, p.ProductName, p.SupplierId
	FROM Product p inner join Supplier s on p.SupplierId = s.Id
	WHERE Lower(s.Country) = LTRIM(RTRIM(LOWER(@Country2)))

	Declare @NumOfProduct1 int
	Set @NumOfProduct1 = (Select Count(*) From #CountryInfo1);
	Declare @NumOfProduct2 int
	Set @NumOfProduct2 = (Select Count(*) From @CountryInfo2);

	Print 'A quantity of product came from ' + LTRIM(@Country1) + ': ' + Convert(nvarchar,@NumOfProduct1)
	Print 'A quantity of product came from ' + LTRIM(@Country2) + ': ' + Convert(nvarchar,@NumOfProduct2)

	Print
	Case 
		When @NumOfProduct1 = @NumOfProduct2
			Then 'A quantity of product came from ' + LTRIM(STR(Convert(nvarchar,@Country1))) + ' and ' + LTRIM(STR(Convert(nvarchar,@Country2))) + 
			' are equal'
		When @NumOfProduct1 > @NumOfProduct2
			Then 'A quantity of product came from ' + LTRIM(@Country1) + ' is bigger than ' + LTRIM(@Country2)
		Else 'A quantity of product came from ' + LTRIM(@Country2) + ' is bigger than ' + LTRIM(@Country1)
	End

	Drop table #CountryInfo1
Commit transaction CompareTwoCountriesTrans
End Try
Begin Catch
	Rollback tran CompareTwoCountriesTrans
	Print 'There are some problems. See detail'
	Print ERROR_MESSAGE();
End catch

--LAB 8 – Stored Procedure
--1. Viết một stored procedure với Input là một mã khách hàng CustomerId 
--và Output là một hóa đơn OrderId của khách hàng đó có Total Amount là nhỏ nhất 
--và một hóa đơn OrderId của khách hàng đó có Total Amount là lớn nhất 
GO
CREATE PROCEDURE usp_GetOrderId_CustomerID_MaxAndMinTotalQuantity
	@CustomerId int,
	@MaxOrderId int output,
	@MaxTotalAmount decimal(12,2) output,
	@MinOrderId int output,
	@MinTotalAmount decimal(12,2) output
as
begin
	WITH OrderInfo(Id, CustomerId, TotalAmount)
	as
	(
		SELECT Id, CustomerId, TotalAmount
		FROM [Order]
		WHERE CustomerId = @CustomerId
	)

	SELECT @MaxOrderId = ( SELECT TOP 1 Id FROM OrderInfo ORDER BY TotalAmount DESC),
			@MaxTotalAmount = MAX(TotalAmount),
			@MinOrderId = (SELECT TOP 1 Id FROM OrderInfo ORDER BY TotalAmount ASC),
			@MinTotalAmount = MIN(TotalAmount)
	FROM OrderInfo
end

declare @CustomerId1 int
declare @MaxOrderId1 int
declare @MaxTotalAmount1 decimal(18,2)
declare @MinOrderId1 int
declare @MinTotalAmount1 decimal(18,2) 
SET @CustomerId1 = 8
exec usp_GetOrderId_CustomerID_MaxAndMinTotalQuantity @CustomerId1,
	@MaxOrderId1 output, @MaxTotalAmount1 output , @MinOrderId1 output, @MinTotalAmount1 output
select @CustomerId1 as CutomerID,
	@MaxOrderId1 as MaxOrderId ,@MinOrderId1 as MinOrderId ,
	@MaxTotalAmount1 as MaxTotalAmount, @MinTotalAmount1 as MinTotalAmount

--2. Viết một stored procedure để thêm vào một Customer với Input là FirstName, LastName, City, Country, và Phone. 
--Lưu ý nếu các input mà rỗng hoặc Input đó đã có trong bảng thì báo lỗi tương ứng và ROLL BACK lại
GO
CREATE PROCEDURE  usp_InsertNewCustomer
	@CustomerId int,
	@FirstName nvarchar(50),
	@Lastname nvarchar(50),
	@City nvarchar(50),
	@Country nvarchar(30),
	@Phone nvarchar(30)
as
begin
	if(exists(select * 
			  from Customer 
			  where FirstName = @FirstName and LastName = @Lastname and City = @City and Country = @Country and Phone = @Phone))
	begin
		print 'Customer already exist'
		return -1
	end
	if(len(@FirstName) = 0 or len(@Lastname) = 0 or len(@City) = 0 or len(@Country) = 0 or len(@Phone) = 0)
	begin
		print ' Customer description can not be blank'
		return -1
	end
	begin try
		begin transaction
			
			set IDENTITY_INSERT Customer on 
			insert into [dbo].[Customer]([Id],[FirstName],[LastName],[City],[Country],[Phone])
			values (@CustomerId, @FirstName ,@Lastname, @City ,@Country, @Phone)
			set identity_insert Customer off

			print 'Insert successful'

		commit transaction
	end try
	begin catch
		if @@TRANCOUNT > 0 rollback transaction
		declare @ERR nvarchar(MAX)
		set @ERR = ERROR_MESSAGE()
		print 'An error occurred after insert data to the Customer table: '
		raiserror(@ERR , 16 , 1)
		return -1
	end catch
end


declare @StateInsert1 int
exec @StateInsert1 = usp_InsertNewCustomer 92 , 'Paul' , 'Henriot', 'Reims', 'France', '26.47.15.10'

print @StateInsert1


declare @StateInsert2 int
exec @StateInsert2 = usp_InsertNewCustomer 92 , 'Bob' , 'Nixon', 'Portland', 'USA', '(071) 34 52 64 28'

print @StateInsert2

select * from Customer
--3. Viết Store Procedure cập nhật lại UnitPrice của sản phẩm trong bảng OrderItem. 
--Khi cập nhật lại UnitPrice này thì cũng phải cập nhật lại Total Amount trong bảng Order tương ứng
--với Total Amount = SUM (UnitPrice *Quantity)
GO
CREATE PROCEDURE  usp_UpdatePriceOrderItem
	@OrderItemId int,
	@UnitPrice decimal(12,2)
as 
begin
	if(not exists(select * from OrderItem where Id = @OrderItemId))
	begin
		print 'OrderItem does not exist'
		return -1 
	end

	declare @OrderId int
	declare @TotalAmount decimal(12,2)

	set @OrderId = (select OrderId from OrderItem where Id = @OrderItemId)
	begin try 
		begin transaction
			update OrderItem set UnitPrice = @UnitPrice where Id =@OrderItemId

			set @TotalAmount = (select top 1 sum(UnitPrice * Quantity) over (partition by OrderId)
								from [OrderItem]
								where OrderId = @OrderId)
			update [Order] set TotalAmount = @TotalAmount where Id = @OrderId
			print 'Update successfull'
		commit transaction
	end try
	begin catch
		if @@TRANCOUNT > 0 rollback transaction
		declare @ERR nvarchar(MAX)
		set @ERR = ERROR_MESSAGE()
		print 'Update failed. See details: '
		raiserror(@ERR,16,1) 
		return -1
	end catch
end
 

declare @StateInsert2 int
exec @StateInsert2 = usp_UpdatePriceOrderItem 2157 , 16.00
print @StateInsert2

declare @StateInsert1 int
exec @StateInsert1 = usp_UpdatePriceOrderItem 21 , 23.00

print @StateInsert1


SELECT * FROM OrderItem WHERE OrderId = 8
SELECT * FROM [Order] WHERE Id = 8
