--EXEC PRC_SHOPRATING_REPORT 'GENERATEDATA','9','2022',11722

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_SHOPRATING_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_SHOPRATING_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_SHOPRATING_REPORT]
(
@ACTION NVARCHAR(100)='GENERATEDATA',
@MONTH NVARCHAR(10), 
@YEAR NVARCHAR(10),
@user_id BIGINT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0		Debashis	v2.0.33		Dashboard Order analytics tab would consider the new Sales Order table (Lavos type order).Refer: 0025229
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	--Rev 1.0
	DECLARE @IsActivateNewOrderScreenwithSize BIT
	SELECT @IsActivateNewOrderScreenwithSize=IsActivateNewOrderScreenwithSize FROM tbl_master_user WHERE user_id=@user_id
	--End of Rev 1.0

	IF(@ACTION='GENERATEDATA')
		BEGIN
			DECLARE @new_month NVARCHAR(10)=@month

			IF(LEN(@month)=1)
			  SET @new_month='0'+@new_month

			DECLARE @start_date DATETIME=@year+'-'+@new_month + '-01' 
			DECLARE @end_date DATETIME = DATEADD(DAY,-1,DATEADD(MONTH,1,@start_date))
			
			DELETE FROM SHOPRATING_REPORT WHERE user_id=@user_id

			--Rev 1.0
			IF @IsActivateNewOrderScreenwithSize=0
				BEGIN
			--End of Rev 1.0
					INSERT INTO SHOPRATING_REPORT(Code,MonthYear,Name,Type,Order_Value,Rating,user_id)
					SELECT tbl.Shop_Code,DATENAME( MONTH , DATEADD( MONTH , CAST(@MONTH AS INT) , 0 ) - 1 ) +','+@YEAR,Shop_Name,ty.Name,tbl.Amount,dbo.GETSHOPRATING(@month,@YEAR,tbl.Shop_Code,tbl.Amount),
					@user_id FROM (
					SELECT Shop_Code,SUM(ordervalue) AS Amount FROM tbl_trans_fts_Orderupdate WHERE CAST(Orderdate AS DATE)>=CAST(@start_date AS DATE) AND CAST(Orderdate AS DATE)>=CAST(@end_date AS DATE)
					GROUP BY Shop_Code) tbl
					INNER JOIN tbl_Master_shop shop ON shop.Shop_Code=tbl.Shop_Code
					INNER JOIN tbl_shoptype ty ON ty.shop_typeId=shop.type
			--Rev 1.0
				END
			ELSE IF @IsActivateNewOrderScreenwithSize=1
				BEGIN
					INSERT INTO SHOPRATING_REPORT(Code,MonthYear,Name,Type,Order_Value,Rating,user_id)
					SELECT tbl.Shop_Code,DATENAME(MONTH,DATEADD(MONTH,CAST(@MONTH AS INT),0) - 1 ) +','+@YEAR,Shop_Name,ty.Name,tbl.Amount,dbo.GETSHOPRATING(@month,@YEAR,tbl.Shop_Code,tbl.Amount),
					@user_id FROM (
					SELECT ORDHEAD.SHOP_ID AS Shop_Code,SUM(ORDVALUE) AS Amount FROM ORDERPRODUCTATTRIBUTE ORDHEAD
					INNER JOIN (SELECT ORDDET.ID,ORDDET.USER_ID,ORDDET.ORDER_ID,(ORDDET.QTY*ORDDET.RATE) AS ORDVALUE FROM ORDERPRODUCTATTRIBUTEDET ORDDET 
					) DET ON ORDHEAD.ID=DET.ID AND ORDHEAD.USER_ID=DET.USER_ID AND ORDHEAD.ORDER_ID=DET.ORDER_ID 
					WHERE CAST(ORDHEAD.ORDER_DATE AS DATE)>=CAST(@start_date AS DATE) AND CAST(ORDHEAD.ORDER_DATE AS DATE)>=CAST(@end_date AS DATE)
					GROUP BY ORDHEAD.SHOP_ID) tbl
					INNER JOIN tbl_Master_shop shop ON shop.Shop_Code=tbl.Shop_Code
					INNER JOIN tbl_shoptype ty ON ty.shop_typeId=shop.type
				END
			--End of Rev 1.0
		END

	SET NOCOUNT OFF
END