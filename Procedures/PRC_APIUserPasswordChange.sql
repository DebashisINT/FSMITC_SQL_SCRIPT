--exec PRC_APIUserPasswordChange @user_id='SearchModule',@Old_password='54',@New_password='t'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_APIUserPasswordChange]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_APIUserPasswordChange] AS'  
END 
GO 

ALTER PROCEDURE [dbo].[PRC_APIUserPasswordChange]
(
@user_id BIGINT,
@Old_password NVARCHAR(MAX),
@New_password NVARCHAR(MAX)
) --WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	IF EXISTS (SELECT * FROM tbl_master_user WITH(NOLOCK) WHERE user_id=@user_id AND user_password=@Old_password)
		BEGIN
			UPDATE tbl_master_user WITH(TABLOCK) SET user_password=@New_password WHERE user_id=@user_id AND user_password=@Old_password

			SELECT 'Successfully changed password.' AS MSG
		END
	ELSE
		BEGIN
			SELECT 'Invalid password.' AS MSG
		END

	SET NOCOUNT OFF
END
