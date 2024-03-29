IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_API_AreaList]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_API_AreaList] AS' 
END
GO

ALTER PROCEDURE [dbo].[prc_API_AreaList]
(
@User_Id BIGINT=NULL
) --WITH ENCRYPTION
AS
/***************************************************************************************
1.0				Tanmoy			04-12-2020		create procedure
***************************************************************************************/
BEGIN
	DECLARE @STATE BIGINT

	SET @STATE=(SELECT TOP(1)add_state FROM tbl_master_address ADRS
				INNER JOIN tbl_master_user USR ON USR.USER_CONTACTID=ADRS.add_cntId
				where ADRS.add_addressType='Office' AND USR.USER_ID=@User_Id)


	SELECT convert(nvarchar(10),AREA.area_id) AS id,AREA.area_name AS location,ISNULL(AREA.Lattitude,'0.00') AS lattitude,ISNULL(AREA.Longitude,'0.00') AS longitude
	FROM tbl_master_area AREA
	INNER JOIN tbl_master_city CTY ON AREA.city_id=CTY.city_id 
	WHERE CTY.state_id=@STATE AND AREA.area_name IS NOT NULL ORDER BY location
END