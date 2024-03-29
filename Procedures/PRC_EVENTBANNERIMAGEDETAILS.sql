
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_MASTER_EVENTBANNERIMAGEDETAILS]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_MASTER_EVENTBANNERIMAGEDETAILS] AS' 
END
GO
USE [master]
GO

ALTER PROCEDURE [dbo].[PRC_MASTER_EVENTBANNERIMAGEDETAILS]
(
 @ACTION NVARCHAR(500)=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Sanchita on 27/04/2023 for V2.0.40 Event banner should dynamically change according to the date. Mantis id:25861
THIS PROCEDURE WILL RUN IN MASTER DATABASE
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF(@ACTION='GETEVENTIMAGE')
	BEGIN
		select '/assests/images/'+TRIM(IMG_FOLDER_NAME)+'/'+TRIM(IMG_NAME) AS [Value] from master..EVENT_BANNER_IMAGES
		where convert(date, GETDATE()) >= convert(date,FROM_DATE) AND convert(date, GETDATE()) <= convert(date,TO_DATE) AND ISACTIVE=1
	END		

	SET NOCOUNT OFF
END