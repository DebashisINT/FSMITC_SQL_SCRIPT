--EXEC PRC_FTSBREAKAGETRACKREGISTER_REPORT '2021-01-01','2022-07-30','EMS0000070','25366',378
--EXEC PRC_FTSBREAKAGETRACKREGISTER_REPORT '2021-01-01','2022-07-30','','',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSBREAKAGETRACKREGISTER_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSBREAKAGETRACKREGISTER_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSBREAKAGETRACKREGISTER_REPORT]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@PRODID NVARCHAR(MAX)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder ON 15/07/2022
Module	   : Quotation Details.Refer: 0025033
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @SqlStr NVARCHAR(MAX),@SqlStrTable NVARCHAR(MAX)

	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)

	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @SqlStrTable=''
			SET @SqlStrTable='INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId FROM tbl_master_employee WHERE emp_contactId IN('+@EMPID+')'
			EXEC SP_EXECUTESQL @SqlStrTable
		END

	IF OBJECT_ID('tempdb..#Product_List') IS NOT NULL
		DROP TABLE #Product_List
	CREATE TABLE #Product_List (Product_Id BIGINT NULL)
	CREATE NONCLUSTERED INDEX Product_Id ON #Product_List (Product_Id ASC)
	
	IF @PRODID<>''
		BEGIN
			SET @PRODID=REPLACE(@PRODID,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable='INSERT INTO #Product_List SELECT sProducts_ID FROM Master_sProducts WHERE sProducts_ID IN('+@PRODID+') '
			EXEC SP_EXECUTESQL @sqlStrTable
		END

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		BEGIN
			DECLARE @empcodes VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@Userid)		
			CREATE TABLE #EMPHRS
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)

			CREATE TABLE #EMPHR_EDIT
			(
			EMPCODE VARCHAR(50),
			RPTTOEMPCODE VARCHAR(50)
			)
		
			INSERT INTO #EMPHRS
			SELECT emp_cntId EMPCODE,ISNULL(TME.emp_contactId,'') RPTTOEMPCODE 
			FROM tbl_trans_employeeCTC CTC LEFT JOIN tbl_master_employee TME on TME.emp_id= CTC.emp_reportTO WHERE emp_effectiveuntil IS NULL
		
			;with cte as(SELECT	EMPCODE,RPTTOEMPCODE FROM #EMPHRS WHERE EMPCODE IS NULL OR EMPCODE=@empcodes  
			UNION ALL
			SELECT a.EMPCODE,a.RPTTOEMPCODE FROM #EMPHRS a
			JOIN cte b ON a.RPTTOEMPCODE = b.EMPCODE
			) 
			INSERT INTO #EMPHR_EDIT
			SELECT EMPCODE,RPTTOEMPCODE FROM cte 
		END

	IF OBJECT_ID('tempdb..#TEMPCONTACT') IS NOT NULL
		DROP TABLE #TEMPCONTACT
	CREATE TABLE #TEMPCONTACT
		(
			cnt_internalId NVARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_branchid INT,
			cnt_firstName NVARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_middleName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_lastName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_contactType NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			cnt_UCC NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
		)
	CREATE NONCLUSTERED INDEX IX_PARTYID ON #TEMPCONTACT(cnt_internalId,cnt_contactType ASC)

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		BEGIN
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT
			INNER JOIN #EMPHR_EDIT ON cnt_internalId=EMPCODE WHERE cnt_contactType IN('EM')
		END
	ELSE
		BEGIN
			INSERT INTO #TEMPCONTACT
			SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN('EM')
		END

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID=OBJECT_ID(N'FTSBREAKAGETRACKREGISTER_REPORT') AND TYPE IN (N'U'))
		BEGIN
			CREATE TABLE FTSBREAKAGETRACKREGISTER_REPORT
			(
			  USERID INT,
			  SEQ BIGINT,
			  BRANCH_ID BIGINT,
			  BRANCHDESC NVARCHAR(300),
			  EMPUSERID BIGINT,
			  EMPCODE NVARCHAR(100) NULL,
			  EMPID NVARCHAR(100) NULL,
			  EMPNAME NVARCHAR(300) NULL,
			  STATEID INT,
			  STATE NVARCHAR(50) NULL,
			  DEG_ID INT,
			  DESIGNATION NVARCHAR(50) NULL,
			  DATEOFJOINING NVARCHAR(10),
			  REPORTTOID NVARCHAR(300) NULL,
			  REPORTTOUID NVARCHAR(100),
			  REPORTTO NVARCHAR(300) NULL,
			  RPTTODESG NVARCHAR(50) NULL,
			  BREAKAGE_NUMBER NVARCHAR(200) NULL,
			  DATE_TIME NVARCHAR(10) NULL,
			  SHOP_CODE NVARCHAR(100) NULL,
			  CUSTNAME NVARCHAR(3000) NULL,
			  PROD_ID BIGINT,
			  PRODNAME NVARCHAR(500) NULL,
			  CUSTOMER_FEEDBACK NVARCHAR(1000) NULL,
			  REMARKS NVARCHAR(1000) NULL,
			  DOCUMENTIMAGEPATH NVARCHAR(1000) NULL,
			  CREATEDBY BIGINT,
			  CREATEDON NVARCHAR(10),
			  CREATEDTIME NVARCHAR(10)
			)
			CREATE NONCLUSTERED INDEX IX1 ON FTSBREAKAGETRACKREGISTER_REPORT (SEQ)
		END
	DELETE FROM FTSBREAKAGETRACKREGISTER_REPORT WHERE USERID=@USERID

	SET @SqlStr=''
	SET @SqlStr='INSERT INTO FTSBREAKAGETRACKREGISTER_REPORT(USERID,SEQ,BRANCH_ID,BRANCHDESC,EMPUSERID,EMPCODE,EMPID,EMPNAME,STATEID,STATE,DEG_ID,DESIGNATION,DATEOFJOINING,REPORTTOID,REPORTTOUID,REPORTTO,'
	SET @SqlStr+='RPTTODESG,BREAKAGE_NUMBER,DATE_TIME,SHOP_CODE,CUSTNAME,PROD_ID,PRODNAME,CUSTOMER_FEEDBACK,REMARKS,DOCUMENTIMAGEPATH,CREATEDBY,CREATEDON,CREATEDTIME) '
	SET @SqlStr+='SELECT '+LTRIM(RTRIM(STR(@USERID)))+' AS USERID,ROW_NUMBER() OVER(ORDER BY CONVERT(NVARCHAR(10),BRKG.DATE_TIME,120)) AS SEQ,BR.BRANCH_ID,BR.BRANCH_DESCRIPTION,USR.USER_ID AS EMPUSERID,CNT.cnt_internalId AS EMPCODE,'
	SET @SqlStr+='CNT.cnt_UCC AS EMPID,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @SqlStr+='ISNULL(ST.ID,0) AS STATEID,ISNULL(ST.state,''State Undefined'') AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,CONVERT(NVARCHAR(10),EMP.emp_dateofJoining,105) AS DATEOFJOINING,'
	SET @SqlStr+='RPTTO.REPORTTOID,RPTTO.REPORTTOUID,RPTTO.REPORTTO,RPTTO.RPTTODESG,BRKG.BREAKAGE_NUMBER,CONVERT(NVARCHAR(10),BRKG.DATE_TIME,105) AS DATE_TIME,BRKG.SHOP_ID,MS.SHOP_NAME AS CUSTNAME,'
	SET @SqlStr+='BRKG.PRODUCT_ID,MP.sProducts_Name AS PRODNAME,BRKG.CUSTOMER_FEEDBACK,BRKG.REMARKS,BRKG.DOCUMENTIMAGEPATH,BRKG.CREATEDBY,CONVERT(NVARCHAR(10),BRKG.CREATEDON,105) AS CREATEDON,'
	SET @SqlStr+='CONVERT(NVARCHAR(8),CAST(BRKG.CREATEDON AS TIME),108) AS CREATEDTIME '
	SET @SqlStr+='FROM FSMBREAKAGEINFODETECTION BRKG '
	SET @SqlStr+='INNER JOIN tbl_Master_shop MS ON BRKG.SHOP_ID=MS.SHOP_CODE '
	SET @SqlStr+='INNER JOIN Master_sProducts MP ON BRKG.PRODUCT_ID=MP.sProducts_ID '
	SET @SqlStr+='INNER JOIN tbl_master_user USR ON BRKG.CREATEDBY=USR.USER_ID AND USR.user_inactive=''N'' '
	SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @SqlStr+='INNER JOIN tbl_master_employee EMP ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @SqlStr+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
	SET @SqlStr+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @SqlStr+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	SET @SqlStr+='INNER JOIN ( '
	SET @SqlStr+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
	SET @SqlStr+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @SqlStr+=') DESG ON DESG.emp_cntId=CNT.cnt_internalId '
	SET @SqlStr+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId AS REPORTTOID,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,'
	SET @SqlStr+='DESG.deg_designation AS RPTTODESG,CNT.cnt_UCC AS REPORTTOUID FROM tbl_master_employee EMP '
	SET @SqlStr+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @SqlStr+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @SqlStr+='INNER JOIN ('
	SET @SqlStr+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC AS cnt '
	SET @SqlStr+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id '
	SET @SqlStr+=') DESG ON DESG.emp_cntId=EMP.emp_contactId WHERE EMPCTC.emp_effectiveuntil IS NULL '
	SET @SqlStr+=') RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @SqlStr+='WHERE CONVERT(NVARCHAR(10),BRKG.DATE_TIME,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	IF @EMPID<>''
		SET @SqlStr+='AND EXISTS (SELECT emp_contactId FROM #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
	IF @PRODID<>''
		SET @SqlStr+='AND EXISTS (SELECT Product_Id FROM #Product_List AS PL WHERE PL.Product_Id=MP.sProducts_ID) '
	--SELECT @SqlStr
	EXEC SP_EXECUTESQL @SqlStr

	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		BEGIN
			DROP TABLE #EMPHR_EDIT
			DROP TABLE #EMPHRS
		END
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #Product_List
	DROP TABLE #TEMPCONTACT

	SET NOCOUNT OFF
END