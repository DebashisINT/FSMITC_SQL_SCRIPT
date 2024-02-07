--EXEC PRC_FTSLEAVEDETAILSLIST @USERID=378,@FROMDATE='2022-01-01',@TODATE='2022-03-09'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSLEAVEDETAILSLIST]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSLEAVEDETAILSLIST] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSLEAVEDETAILSLIST]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
1.0		v2.0.7		TANMOY		11-02-2020		REPORT FOR LEAVE DETAILS
2.0		v2.0.27		Debashis	09-03-2022		Leave List report enhancement.Refer: 0024681
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
		
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TEMPCONTACT') AND TYPE IN (N'U'))
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
	(
		cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
		USER_ID BIGINT
	)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)
	INSERT INTO #TEMPCONTACT
	SELECT cnt_internalId,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,USR.user_id FROM TBL_MASTER_CONTACT CNT
	INNER JOIN tbl_master_user USR ON USR.user_contactId=CNT.cnt_internalId WHERE cnt_contactType IN('EM')

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSLEAVELIST_REPORT') AND TYPE IN (N'U'))
		BEGIN
			--Rev 2.0 && Some fields added as EMPID,EMPDESG,CONTACTNO,APPLIED_TIME,AEMPID,AEMPDESG,ACONTACTNO,APPROVEREJECT_DATE,APPROVEREJECT_TIME & APPROVER_REMARKS
			CREATE TABLE FTSLEAVELIST_REPORT
			(
			USERID BIGINT,
			SEQ INT,
			ID BIGINT NULL,
			EMPID NVARCHAR(50) NULL,
			EMPDESG NVARCHAR(50) NULL,
			CONTACTNO NVARCHAR(50) NULL,
			LEAVE_USERID BIGINT NULL,
			LEAVE_START_DATE DATETIME NULL,
			LEAVE_END_DATE DATETIME NULL,
			LEAVE_TYPE INT,
			LEAVE_REASON NVARCHAR(500) NULL,
			CREATED_DATE DATETIME NULL,
			APPLIED_TIME NVARCHAR(10) NULL,
			CURRENT_STATUS NVARCHAR(20) NULL,
			APPROVAL_USER BIGINT NULL,
			LeaveType NVARCHAR(100) NULL,
			EMP_NAME NVARCHAR(300) NULL,
			AEMPID NVARCHAR(50) NULL,
			AEMPDESG NVARCHAR(50) NULL,
			ACONTACTNO NVARCHAR(50) NULL,
			APPROVE_EMP_NAME NVARCHAR(300) NULL,
			APPROVEREJECT_DATE NVARCHAR(10) NULL,
			APPROVEREJECT_TIME NVARCHAR(10) NULL,
			APPROVER_REMARKS NVARCHAR(500) NULL
			)

			CREATE NONCLUSTERED INDEX IX1 ON FTSLEAVELIST_REPORT (SEQ)
		END
	DELETE FROM FTSLEAVELIST_REPORT WHERE USERID=@USERID

	--Rev 2.0
	--INSERT INTO FTSLEAVELIST_REPORT
	--select @USERID AS USERID,ROW_NUMBER() OVER(ORDER BY ID) AS SEQ,HEAD.ID,HEAD.USER_ID,HEAD.LEAVE_START_DATE,HEAD.LEAVE_END_DATE,HEAD.LEAVE_TYPE,HEAD.LEAVE_REASON,
	--HEAD.CREATED_DATE,HEAD.CURRENT_STATUS,HEAD.APPROVAL_USER,TYP.LeaveType,
	--ISNULL(TMP.cnt_firstName,'')+' '+ISNULL(TMP.cnt_middleName,'')+' '+ISNULL(TMP.cnt_lastName,'') AS EMP_NAME,
	--ISNULL(TEMP.cnt_firstName,'')+' '+ISNULL(TEMP.cnt_middleName,'')+' '+ISNULL(TEMP.cnt_lastName,'') AS APPROVE_EMP_NAME 
	--FROM FTS_USER_LEAVEAPPLICATION HEAD
	--LEFT OUTER JOIN tbl_FTS_Leavetype TYP ON TYP.Leave_Id=HEAD.LEAVE_TYPE
	--LEFT OUTER JOIN #TEMPCONTACT TMP ON TMP.USER_ID=HEAD.USER_ID
	--LEFT OUTER JOIN #TEMPCONTACT TEMP ON TEMP.USER_ID=HEAD.APPROVAL_USER
	--WHERE CAST(HEAD.CREATED_DATE AS DATE)>=@FROMDATE AND CAST(HEAD.CREATED_DATE AS DATE)<=@TODATE

	INSERT INTO FTSLEAVELIST_REPORT(USERID,SEQ,ID,EMPID,EMPDESG,CONTACTNO,LEAVE_USERID,LEAVE_START_DATE,LEAVE_END_DATE,LEAVE_TYPE,LEAVE_REASON,CREATED_DATE,APPLIED_TIME,CURRENT_STATUS,APPROVAL_USER,
	LeaveType,EMP_NAME,AEMPID,AEMPDESG,ACONTACTNO,APPROVE_EMP_NAME,APPROVEREJECT_DATE,APPROVEREJECT_TIME,APPROVER_REMARKS)

	SELECT @USERID AS USERID,ROW_NUMBER() OVER(ORDER BY ID) AS SEQ,HEAD.ID,EMP.emp_uniqueCode AS EMPID,DESG.deg_designation AS EMPDESG,USR.user_loginId AS CONTACTNO,HEAD.USER_ID,HEAD.LEAVE_START_DATE,
	HEAD.LEAVE_END_DATE,HEAD.LEAVE_TYPE,HEAD.LEAVE_REASON,HEAD.CREATED_DATE,CONVERT(NVARCHAR(10),HEAD.CREATED_DATE,108) AS APPLIED_TIME,HEAD.CURRENT_STATUS,HEAD.APPROVAL_USER,TYP.LeaveType,
	ISNULL(TMP.cnt_firstName,'')+' '+ISNULL(TMP.cnt_middleName,'')+' '+ISNULL(TMP.cnt_lastName,'') AS EMP_NAME,
	AEMP.emp_uniqueCode AS AEMPID,ADESG.deg_designation AS AEMPDESG,AUSR.user_loginId AS ACONTACTNO,
	ISNULL(TEMP.cnt_firstName,'')+' '+ISNULL(TEMP.cnt_middleName,'')+' '+ISNULL(TEMP.cnt_lastName,'') AS APPROVE_EMP_NAME,CONVERT(NVARCHAR(10),HEAD.APPROVAL_DATE_TIME,105) AS APPROVEREJECT_DATE,
	CONVERT(NVARCHAR(10),HEAD.APPROVAL_DATE_TIME,108) AS APPROVEREJECT_TIME,HEAD.APPROVER_REMARKS
	FROM FTS_USER_LEAVEAPPLICATION HEAD
	LEFT OUTER JOIN tbl_master_user USR ON HEAD.USER_ID=USR.user_id
	LEFT OUTER JOIN tbl_master_employee EMP ON USR.user_contactId=EMP.emp_contactId
	LEFT OUTER JOIN (
	SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) AS emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt 
	LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id 
	) DESG ON DESG.emp_cntId=EMP.emp_contactId 
	LEFT OUTER JOIN tbl_FTS_Leavetype TYP ON TYP.Leave_Id=HEAD.LEAVE_TYPE
	LEFT OUTER JOIN #TEMPCONTACT TMP ON TMP.USER_ID=HEAD.USER_ID
	LEFT OUTER JOIN #TEMPCONTACT TEMP ON TEMP.USER_ID=HEAD.APPROVAL_USER
	LEFT OUTER JOIN tbl_master_user AUSR ON HEAD.APPROVAL_USER=AUSR.user_id
	LEFT OUTER JOIN tbl_master_employee AEMP ON AUSR.user_contactId=AEMP.emp_contactId
	LEFT OUTER JOIN (
	SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) AS emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt 
	LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id 
	) ADESG ON ADESG.emp_cntId=AEMP.emp_contactId 
	WHERE CAST(HEAD.CREATED_DATE AS DATE)>=@FROMDATE AND CAST(HEAD.CREATED_DATE AS DATE)<=@TODATE
	--End of Rev 2.0

	SET NOCOUNT OFF

	DROP TABLE #TEMPCONTACT
END