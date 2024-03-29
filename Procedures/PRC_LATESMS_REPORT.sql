IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_LATESMS_REPORT]') AND type in (N'P', N'PC')) 
BEGIN 
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_LATESMS_REPORT] AS'  
END 
GO

ALTER PROCEDURE [dbo].[PRC_LATESMS_REPORT]
(
@fromdate DateTime=NULL,
@todate  DateTime=NULL,
@user_Id  VARCHAR(50)=NULL
) --WITH ENCRYPTION
AS

BEGIN

	delete from LATESMS_REPORT where user_id=@user_id

	insert into LATESMS_REPORT
	(
	Date,Emp_Name,Login_ID,SMS_time,SMS_time_type,USER_ID
	)
	SELECT 
	CONVERT(VARCHAR(10),date_time,105),
	RTRIM(LTRIM(
						CONCAT(
							LTRIM(COALESCE(CNT.cnt_firstName + ' ', ''))
							, LTRIM(COALESCE(CNT.cnt_middleName + ' ', ''))
							, COALESCE(CNT.cnt_lastName, '')
						)
					)) user_name
	,user_loginId
	,CONVERT(varchar(8),visit_time,108)
	,CASE WHEN late_for='First' then 'Morning' else 'Evening' End
	,@user_Id
	 FROM FTS_LATEMARKETVISITLOG LOG
	 INNER JOIN TBL_MASTER_USER USR ON USR.user_id=LOG.user_id
	 INNER JOIN tbl_master_contact CNT ON CNT.cnt_internalId=USR.user_contactId
	 where cast(date_time as date)>=cast(@fromdate as date)
	 and cast(date_time as date)<=cast(@todate as date)
END