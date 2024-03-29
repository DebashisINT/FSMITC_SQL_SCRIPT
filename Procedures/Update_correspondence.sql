IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Update_correspondence]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Update_correspondence] AS' 
END
GO

ALTER procedure [dbo].[Update_correspondence]
@insuId varchar(50),
@Type varchar(50),
@contacttype varchar(50),
@Address1 varchar(500),
@Address2 varchar(500),
@Address3 varchar(500),
@LandMark varchar(500),
@Address4 varchar(200)=null,
@City int,
@area int,
@contactperson varchar(50)=null,
@Country int,
@State int,
@PinCode varchar(50),
@CreateUser decimal,
@Isdefault int=0,
@Branch int=0,
@Phone varchar(50)=null,
@add_Email  varchar(100)=null,
@add_Website  varchar(200)=null,
@add_Designation int=null,
@Id int=null

as
/**************************************************************************************************************************************
Rev 1.0		20-04-2023		Sanchita	V2.0.40		Employee Office address shall be updated along with City Long Lat in employee 
													address table. Refer: 25826
**************************************************************************************************************************************/
Begin
		-- Rev 1.0
		declare @City_Lat nvarchar(max)='0.0', @City_Long nvarchar(max)='0.0'

		if(LTRIM(RTRIM(UPPER(@contacttype)))='EMPLOYEE')
		BEGIN
			set @City_Lat = (select top 1 isnull(City_lat,'0.0') from tbl_master_city where city_id=@City )
			set @City_Long = (select top 1 isnull(City_Long,'0.0') from tbl_master_city where city_id=@City )
		END
		-- End of Rev 1.0

		-- Rev 1.0 [ columns City_lat and City_Long added in query]
		update tbl_master_address set Isdefault=@Isdefault,contactperson=@contactperson,add_entity=@contacttype,add_addressType=@Type,
		add_address1=@Address1,add_address2=@Address2,
		add_address3=@Address3,add_city=@City,add_landMark=@LandMark,add_country=@Country,add_state=@State,add_pin=@PinCode,add_area=@area,
		CreateDate=getdate(),CreateUser=@CreateUser,add_Phone=@Phone,add_Email=@add_Email,add_Website=@add_Website,add_Designation=@add_Designation
		,add_address4=@Address4,add_Lat=@City_Lat,add_Long=@City_Long where add_Id=@Id
		
		if(@Isdefault=1) 
		BEGIN
			update tbl_master_address  set Isdefault=0 where add_addressType=@Type and add_cntId=@insuId and add_Id!=@Id
		END

end
