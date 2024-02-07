IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[FSM_FetchProductsList]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [FSM_FetchProductsList] AS' 
END
GO

ALTER  Procedure [dbo].[FSM_FetchProductsList]
(
	@Products nvarchar(MAX)=''
)
AS
/*================================================================================================================================================================
	Written by Sanchita	V.0.39		28/02/2023     FSM >> Product Master : Listing - Implement Show Button. Refer: 25709

==================================================================================================================================================================*/
BEGIN
	DECLARE @DSql NVARCHAR(MAX)
	
	SET @DSql = ''

	SET @DSql = 'SELECT MP.sProducts_ID ,MP.sProducts_Code ,MP.sProducts_Name ,MP.sProducts_Description ,MP.sProducts_Type ,'
	SET @DSql += 'CASE WHEN MP.sProducts_Type =''A'' THEN ''Raw Material'' WHEN MP.sProducts_Type =''B'' THEN ''Work-In-Process'' WHEN  MP.sProducts_Type =''C'' THEN ''Finished Goods'' END AS sProducts_TypeFull '
	SET @DSql += ',MP.ProductClass_Code ,MPC.ProductClass_Name ,MP.sProducts_GlobalCode,MP.sProducts_TradingLot, MP.sProducts_TradingLotUnit,MP.sProducts_QuoteCurrency ,MP.sProducts_QuoteLot, '
    SET @DSql += 'MP.sProducts_QuoteLotUnit, MP.sProducts_DeliveryLot, MP.sProducts_DeliveryLotUnit ,MP.sProducts_Color ,MP.sProducts_Size,MP.sProducts_CreateUser ,MP.sProducts_CreateTime'
	SET @DSql += ',MP.sProducts_ModifyUser ,MP.sProducts_ModifyTime ,case ISNULL(MP.sProducts_HsnCode,'''')when '''' then ISNULL(SERVICE_CATEGORY_CODE,'''')else MP.sProducts_HsnCode end  HSNCODE '
	SET @DSql += ',Brand_Name ,case sProduct_IsInventory when 1 then ''Yes'' else ''No'' end sProduct_IsInventory '
	SET @DSql += ',case Is_ServiceItem when 1 then ''Yes'' else ''No'' end Is_ServiceItem ,case sProduct_IsCapitalGoods  when 1 then ''Yes'' else ''No'' end sProduct_IsCapitalGoods '
	SET @DSql += ',sInv_MainAccount,sRet_MainAccount,pInv_MainAccount,pRet_MainAccount '
	SET @DSql += 'FROM Master_sProducts MP '
	SET @DSql += 'left join Master_ProductClass MPC '
	SET @DSql += 'on MP.ProductClass_Code=MPC.ProductClass_ID  left outer join TBL_MASTER_SERVICE_TAX sac on '
	SET @DSql += 'MP.sProducts_serviceTax=sac.TAX_ID '
    SET @DSql += 'left outer join tbl_master_brand brand on MP.sProducts_Brand=brand.Brand_Id '
	IF (@Products <>'')
	BEGIN
		SET @Products = '''' + replace(@Products,',',''',''')  + ''''
		SET @DSql += 'where MP.sProducts_ID in ('+@Products+')'
	END
	SET @DSql += 'order by MP.sProducts_ID desc '

	--select @DSql
	Exec sp_executesql @Dsql
END

 