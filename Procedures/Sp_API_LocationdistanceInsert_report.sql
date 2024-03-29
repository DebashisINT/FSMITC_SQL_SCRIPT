IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Sp_API_LocationdistanceInsert_report]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Sp_API_LocationdistanceInsert_report] AS'  
END 
GO

ALTER PROCEDURE [dbo].[Sp_API_LocationdistanceInsert_report]
(
 @locationdetdatatable   udt_FTSLocationdistanceUpdateDetails READONLY,
 @userid varchar(50)=NULL,
 @date varchar(50)=NULL
 ) --WITH ENCRYPTION
 AS

 BEGIN

 BEGIN TRAN

 IF EXISTS(select UserId  from tbl_locationdistancecalculation where userid =@userid and cast(VisitDate as date)=@date)

 BEGIN

 delete  from tbl_locationdistancecalculation  where userid =@userid and cast(VisitDate as date)=@date
 END

 insert into tbl_locationdistancecalculation(Latitude,Longitude,VisitDate,UserId,DistanceinKm) 
 SELECT  Latitude,Longitude,@date,@userid,distanceKm from @locationdetdatatable


 if  @@ROWCOUNT>0
 BEGIN

 COMMIT TRAN
 END

 END