IF NOT EXISTS (SELECT * FROM sys.objects  WHERE  object_id = OBJECT_ID(N'[dbo].[GET_MINSALESPRICEENTITYWISE]') AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
BEGIN
EXEC('CREATE FUNCTION [dbo].[GET_MINSALESPRICEENTITYWISE]() RETURNS NUMERIC(18,2) AS BEGIN RETURN 0 END')
END
GO

ALTER FUNCTION [dbo].[GET_MINSALESPRICEENTITYWISE]
(
@SHOP_ID VARCHAR(500),
@PRODUCT_ID VARCHAR(500),
@DATE DATETIME
)
RETURNS NUMERIC(18,2)
AS
/****************************************************************************************************************************************************************************
1.0		v2.0.40		Debashis		04-08-2023		Require PP (type 2) price in api.Refer: 0026696
****************************************************************************************************************************************************************************/
BEGIN
	DECLARE @MIN_SALES_PRICE NUMERIC(18,2)=0,@ProductID VARCHAR(200)='',@DiscSalesPrice NUMERIC(18,2) =0,@CustomerID VARCHAR(100)=''


	--DECLARE DB_CURSOR CURSOR FOR
--SELECT ProductID,DiscSalesPrice,CustomerID
--FROM FTS_trans_SaleRateLock WHERE  ValidFrom <=@DATE AND ValidUpto>=@DATE
--OPEN DB_CURSOR
--FETCH NEXT FROM DB_CURSOR INTO @ProductID,@DiscSalesPrice,@CustomerID
--WHILE @@FETCH_STATUS=0
--BEGIN

--IF(@ProductID='0')
--BEGIN
--  IF(@CustomerID='0' OR @CustomerID=@SHOP_ID)
--  BEGIN

--  SET @MIN_SALES_PRICE=@DiscSalesPrice
--  BREAK
--  END

--END
--ELSE IF(@ProductID=@PRODUCT_ID)
--BEGIN

--IF(@CustomerID='0' OR @CustomerID=@SHOP_ID)
--  BEGIN

--  SET @MIN_SALES_PRICE=@DiscSalesPrice
--  BREAK
--  END

--END


--FETCH NEXT FROM DB_CURSOR INTO @ProductID,@DiscSalesPrice,@CustomerID
--END
--CLOSE DB_CURSOR
--DEALLOCATE DB_CURSOR

	DECLARE @SHOP_TYPE VARCHAR(250)=(SELECT type FROM tbl_Master_shop WHERE Shop_Code=@SHOP_ID)
	DECLARE @SHOP_STATE VARCHAR(250)=(SELECT stateId FROM tbl_Master_shop WHERE Shop_Code=@SHOP_ID)

	--Rev 1.0 && A new Type has been added as Type=2
	SET @MIN_SALES_PRICE =(SELECT TOP 1 CASE WHEN @SHOP_TYPE='1' THEN SHOP_PRICE 
									   WHEN @SHOP_TYPE='2' THEN SUPER_PRICE 
									   WHEN @SHOP_TYPE='4' THEN DD_PRICE
									   ELSE 0 END
	FROM FTS_SPECIAL_PRICE_STATE_TYPE_PRODUCT_WISE WHERE PRODUCT_ID=@PRODUCT_ID AND STATE_ID=@SHOP_STATE)
 
	RETURN ISNULL(@MIN_SALES_PRICE,0)
END