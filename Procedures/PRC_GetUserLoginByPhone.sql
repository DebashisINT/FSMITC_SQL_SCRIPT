IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_GetUserLoginByPhone]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_GetUserLoginByPhone] AS'  
END 
GO 

ALTER PROCEDURE [dbo].[PRC_GetUserLoginByPhone]
(
@Phone NVARCHAR(15)
) --WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT user_id,'Successfully get user.' as MSG FROM tbl_master_user WITH(NOLOCK) WHERE user_loginId=@Phone

	SET NOCOUNT OFF
END