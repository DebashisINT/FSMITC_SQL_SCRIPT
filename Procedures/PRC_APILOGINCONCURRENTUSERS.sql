IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APILOGINCONCURRENTUSERS]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APILOGINCONCURRENTUSERS] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_APILOGINCONCURRENTUSERS]
(
@ACTION NVARCHAR(100)=NULL,
@USER_ID NVARCHAR(50)=NULL,
@IMEI NVARCHAR(2000)=NULL,
@DATE_TIME DATETIME=NULL
) --WITH ENCRYPTION
AS
/****************************************************************************************************************
Written By : Debashis Talukder On 22/03/2022
Purpose : For Insert,Fetch & Delete User IMEI.Row No: 668 & 670
****************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	IF @ACTION='INSERTUSERIMEI'
		BEGIN
			IF NOT EXISTS(SELECT IMEI_NO FROM APP_LOGIN_CONCURRENTUSERS WITH(NOLOCK) WHERE USER_ID=@USER_ID AND IMEI_NO=@IMEI)
				BEGIN
					INSERT INTO APP_LOGIN_CONCURRENTUSERS(USER_ID,IMEI_NO,CREATEDATE)
					SELECT @USER_ID,@IMEI,@DATE_TIME

					SELECT USER_ID,IMEI_NO,CREATEDATE FROM APP_LOGIN_CONCURRENTUSERS WITH(NOLOCK) WHERE USER_ID=@USER_ID AND IMEI_NO=@IMEI
				END
		END
	IF @ACTION='FETCHUSERIMEI'
		BEGIN
			SELECT USER_ID,IMEI_NO,CREATEDATE FROM APP_LOGIN_CONCURRENTUSERS WITH(NOLOCK) WHERE USER_ID=@USER_ID
		END
	IF @ACTION='DELETEUSERIMEI'
		BEGIN
			IF EXISTS(SELECT USER_ID FROM APP_LOGIN_CONCURRENTUSERS WITH(NOLOCK) WHERE USER_ID=@USER_ID)
				BEGIN
					DELETE FROM APP_LOGIN_CONCURRENTUSERS WHERE USER_ID=@USER_ID

					SELECT 'Deleted' STRMESSAGE
				END
		END

	SET NOCOUNT OFF
END