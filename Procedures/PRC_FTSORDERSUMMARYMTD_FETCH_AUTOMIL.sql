IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSORDERSUMMARYMTD_FETCH_AUTOMIL]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSORDERSUMMARYMTD_FETCH_AUTOMIL] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSORDERSUMMARYMTD_FETCH_AUTOMIL]
(
@MONTH NVARCHAR(3)=NULL,
@YEARS NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/***************************************************************************************************************************************************
Written by : Sanchita on 04/07/2023. Order Summary push mail configuration required for Honeywell. Refer: 26478
***************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	DECLARE @Strsql NVARCHAR(MAX),@sqlStrTable NVARCHAR(MAX),@MONTHNAME NVARCHAR(3),@MONTHNO INT=0,@FROMDATE NVARCHAR(10),@TODATE NVARCHAR(10)
	DECLARE @IsActivateNewOrderScreenwithSize BIT

	SELECT @IsActivateNewOrderScreenwithSize=IsActivateNewOrderScreenwithSize FROM tbl_master_user WITH(NOLOCK) WHERE USER_ID=@USERID

	SET @MONTHNAME=@MONTH
	SET @MONTHNO=DATEPART(MM,@MONTHNAME+'01 1900')
	SET @FROMDATE=CONVERT(VARCHAR(10),DATEADD(MONTH, CONVERT(INT,@MONTHNO) - 1, @YEARS),120)
	SET @TODATE=CONVERT(VARCHAR(10),DATEADD(DAY, -1, DATEADD(MONTH, CONVERT(INT,@MONTHNO), @YEARS)),120)

	IF OBJECT_ID('tempdb..#STATEID_LIST') IS NOT NULL
		DROP TABLE #STATEID_LIST
	CREATE TABLE #STATEID_LIST (State_Id INT)
	CREATE NONCLUSTERED INDEX IX1 ON #STATEID_LIST (State_Id ASC)
	IF @STATEID <> ''
		BEGIN
			SET @STATEID=REPLACE(@STATEID,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #STATEID_LIST SELECT id from tbl_master_state where id in('+@STATEID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END
	
	IF OBJECT_ID('tempdb..#DESIGNATION_LIST') IS NOT NULL
		DROP TABLE #DESIGNATION_LIST
	CREATE TABLE #DESIGNATION_LIST (deg_id INT)
	CREATE NONCLUSTERED INDEX IX2 ON #DESIGNATION_LIST (deg_id ASC)
	IF @DESIGNID <> ''
		BEGIN
			SET @DESIGNID=REPLACE(@DESIGNID,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #DESIGNATION_LIST SELECT deg_id from tbl_master_designation where deg_id in('+@DESIGNID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

	IF OBJECT_ID('tempdb..#EMPLOYEE_LIST') IS NOT NULL
		DROP TABLE #EMPLOYEE_LIST
	CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	IF @EMPID <> ''
		BEGIN
			SET @EMPID = REPLACE(''''+@EMPID+'''',',',''',''')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@EMPID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
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
	SET @sqlStrTable=''
	SET @sqlStrTable='INSERT INTO #TEMPCONTACT(cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC) '
	SET @sqlStrTable+='SELECT cnt_internalId,cnt_branchid,cnt_firstName,cnt_middleName,cnt_lastName,cnt_contactType,cnt_UCC FROM TBL_MASTER_CONTACT WHERE cnt_contactType IN(''EM'') '
	IF @EMPID<>''
		SET @sqlStrTable+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=TBL_MASTER_CONTACT.cnt_internalId) '
	
	--SELECT @sqlStrTable
	EXEC SP_EXECUTESQL @sqlStrTable

	IF ((select IsAllDataInPortalwithHeirarchy from tbl_master_user where user_id=@USERID)=1)
		BEGIN
			DECLARE @empcodes VARCHAR(50)=(select user_contactId from Tbl_master_user where user_id=@USERID)		
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
		
			;with cte as(select	
			EMPCODE,RPTTOEMPCODE
			from #EMPHRS 
			where EMPCODE IS NULL OR EMPCODE=@empcodes  
			union all
			select	
			a.EMPCODE,a.RPTTOEMPCODE
			from #EMPHRS a
			join cte b
			on a.RPTTOEMPCODE = b.EMPCODE
			) 
			INSERT INTO #EMPHR_EDIT
			select EMPCODE,RPTTOEMPCODE  from cte 

		END

	IF OBJECT_ID('tempdb..#TMPATTENLOGINOUT') IS NOT NULL
		DROP TABLE #TMPATTENLOGINOUT

	CREATE TABLE #TMPATTENLOGINOUT(USERID BIGINT,LOGGEDIN NVARCHAR(10),LOGEDOUT NVARCHAR(10),cnt_internalId NVARCHAR(10),Login_datetime NVARCHAR(10),WORKDATEORDBY NVARCHAR(10))
	CREATE NONCLUSTERED INDEX IX1 ON #TMPATTENLOGINOUT(USERID,cnt_internalId,Login_datetime)

	SET @Strsql=''
	SET @Strsql='INSERT INTO #TMPATTENLOGINOUT(USERID,LOGGEDIN,LOGEDOUT,cnt_internalId,Login_datetime,WORKDATEORDBY) '
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,MIN(CONVERT(VARCHAR(5),CAST(ATTEN.Login_datetime AS TIME),108)) AS LOGGEDIN,NULL AS LOGEDOUT,CNT.cnt_internalId,'
	SET @Strsql+='CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) AS WORKDATEORDBY '
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='AND Login_datetime IS NOT NULL AND Logout_datetime IS NULL AND Isonleave=''false'' '
	SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) '
	SET @Strsql+='UNION ALL '
	SET @Strsql+='SELECT ATTEN.User_Id AS USERID,NULL AS LOGGEDIN,MAX(CONVERT(VARCHAR(5),CAST(ATTEN.Logout_datetime AS TIME),108)) AS LOGEDOUT,CNT.cnt_internalId,'
	SET @Strsql+='CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105) AS Login_datetime,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) AS WORKDATEORDBY '
	SET @Strsql+='FROM tbl_fts_UserAttendanceLoginlogout ATTEN '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_id=ATTEN.User_Id AND USR.user_inactive=''N'' '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
	SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
	SET @Strsql+='AND Login_datetime IS NULL AND Logout_datetime IS NOT NULL AND Isonleave=''false'' '
	SET @Strsql+='GROUP BY ATTEN.User_Id,CNT.cnt_internalId,CONVERT(NVARCHAR(10),ATTEN.Work_datetime,105),CONVERT(NVARCHAR(10),ATTEN.Work_datetime,120) '

	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	IF OBJECT_ID('tempdb..#TMPORDER') IS NOT NULL
		DROP TABLE #TMPORDER
	CREATE TABLE #TMPORDER(USER_ID BIGINT,CNT_INTERNALID NVARCHAR(10),SHOP_CODE NVARCHAR(200),ORDER_DATE DATETIME,ORDERVALUE DECIMAL(18,2))
	CREATE NONCLUSTERED INDEX IX1 ON #TMPORDER (USER_ID ASC)

	IF @IsActivateNewOrderScreenwithSize=1
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO #TMPORDER(USER_ID,CNT_INTERNALID,SHOP_CODE,ORDER_DATE,ORDERVALUE) '
			SET @Strsql+='SELECT ORDH.USER_ID,CNT.cnt_internalId,ORDH.SHOP_ID,ORDH.ORDER_DATE,SUM(ISNULL(ORDD.Ordervalue,0)) AS ORDERVALUE FROM ORDERPRODUCTATTRIBUTE ORDH WITH(NOLOCK) '
			SET @Strsql+='INNER JOIN(SELECT ORDD.ID,ORDD.USER_ID,ORDD.ORDER_ID,(ORDD.QTY*ORDD.RATE) AS Ordervalue FROM ORDERPRODUCTATTRIBUTEDET ORDD WITH(NOLOCK) '
			SET @Strsql+=') ORDD ON ORDH.ID=ORDD.ID AND ORDH.USER_ID=ORDD.USER_ID AND ORDH.ORDER_ID=ORDD.ORDER_ID '
			SET @Strsql+='INNER JOIN tbl_master_user USR WITH(NOLOCK) ON USR.user_id=ORDH.USER_ID '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDH.ORDER_DATE,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			IF @EMPID<>''
				SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
			SET @Strsql+='GROUP BY ORDH.USER_ID,CNT.cnt_internalId,ORDH.SHOP_ID,ORDH.ORDER_DATE '

			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	ELSE IF @IsActivateNewOrderScreenwithSize=0
		BEGIN
			SET @Strsql=''
			SET @Strsql='INSERT INTO #TMPORDER(USER_ID,CNT_INTERNALID,SHOP_CODE,ORDER_DATE,ORDERVALUE) '
			SET @Strsql+='SELECT ORDH.userID,CNT.cnt_internalId,ORDH.Shop_Code,ORDH.Orderdate AS ORDDATE,SUM(ISNULL(Ordervalue,0)) AS ORDERVALUE '
			SET @Strsql+='FROM tbl_trans_fts_Orderupdate ORDH WITH(NOLOCK) '
			SET @Strsql+='INNER JOIN tbl_master_user USR WITH(NOLOCK) ON USR.user_id=ORDH.userID '
			SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=USR.user_contactId '
			SET @Strsql+='WHERE CONVERT(NVARCHAR(10),ORDH.Orderdate,120) BETWEEN CONVERT(NVARCHAR(10),'''+@FROMDATE+''',120) AND CONVERT(NVARCHAR(10),'''+@TODATE+''',120) '
			IF @EMPID<>''
				SET @Strsql+='AND EXISTS (SELECT emp_contactId from #EMPLOYEE_LIST AS EMP WHERE EMP.emp_contactId=CNT.cnt_internalId) '
			SET @Strsql+='GROUP BY ORDH.userID,CNT.cnt_internalId,ORDH.Shop_Code,ORDH.Orderdate '

			--SELECT @Strsql
			EXEC SP_EXECUTESQL @Strsql
		END
	
	SET @Strsql=''
	SET @Strsql='SELECT WORKDATE,WORKDATEORDBY,USERID,EMPCODE,EMPID,EMPNAME,CONTACTNO,DEG_ID,DESIGNATION,STATEID,STATE,REPORTTOID,REPORTTOUID,REPORTTO,RPTTODESG,'
	SET @Strsql+='CASE WHEN UNIQUEORDCNT<>0 THEN CAST((CAST(ORDERVALUEPERDAY AS DECIMAL(18,2))/CAST(UNIQUEORDCNT AS DECIMAL(18,2))) AS DECIMAL(18,2)) ELSE 0 END AS AVGBILLVALUE,'
	SET @Strsql+='TOTALSHPCNT,UNIQUEORDCNT,ORDCNT,'
	SET @Strsql+='CASE WHEN TOTALSHPCNT<>0 THEN CAST((CAST(UNIQUEORDCNT AS DECIMAL(18,2))/CAST(TOTALSHPCNT AS DECIMAL(18,2))) AS DECIMAL(18,2)) ELSE 0 END AS PERCENTOFBILLCUST,'
	SET @Strsql+='ORDERVALUEPERDAY FROM('
	SET @Strsql+='SELECT CNT.cnt_internalId AS EMPCODE,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+(CASE WHEN ISNULL(CNT.CNT_MIDDLENAME,'''')<>'''' THEN '' '' ELSE '''' END)+ISNULL(CNT.CNT_LASTNAME,'''') AS EMPNAME,'
	SET @Strsql+='ST.ID AS STATEID,ST.state AS STATE,DESG.DEG_ID,DESG.deg_designation AS DESIGNATION,USR.user_loginId AS CONTACTNO,RPTTO.REPORTTOID,RPTTO.REPORTTOUID,RPTTO.REPORTTO,'
	SET @Strsql+='RPTTO.RPTTODESG,ATTEN.WORKDATE,ATTEN.WORKDATEORDBY,ATTEN.LOGGEDIN AS LOGGEDIN,ATTEN.LOGEDOUT AS LOGEDOUT,EMP.emp_uniqueCode AS EMPID,USR.user_id AS USERID,'
	SET @Strsql+='ISNULL(SHOP.SHPCNT,0) AS TOTALSHPCNT,ISNULL(ORDCNT.UNIQUEORDCNT,0) AS UNIQUEORDCNT,ISNULL(ORDCNT.ORDCNT,0) AS ORDCNT,ISNULL(ORDHEAD.ORDERVALUE,0) AS ORDERVALUEPERDAY '
	SET @Strsql+='FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN tbl_master_branch BR ON CNT.cnt_branchid=BR.branch_id '
	SET @Strsql+='INNER JOIN tbl_master_user USR ON USR.user_contactId=EMP.emp_contactId AND USR.user_inactive=''N'' '
	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		SET @Strsql+='INNER JOIN #EMPHR_EDIT EMPHR ON EMPHR.EMPCODE=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN tbl_master_address ADDR ON ADDR.add_cntId=CNT.cnt_internalid AND ADDR.add_addressType=''Office'' '
	SET @Strsql+='INNER JOIN tbl_master_state ST ON ST.id=ADDR.add_state '
	IF @STATEID<>''
		SET @Strsql+='AND EXISTS (SELECT State_Id from #STATEID_LIST AS STA WHERE STA.State_Id=ST.id) '
	SET @Strsql+='INNER JOIN ( '
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	IF @DESIGNID<>''
		SET @Strsql+='AND EXISTS (SELECT deg_id from #DESIGNATION_LIST AS DS WHERE DS.deg_id=DESG.deg_id) '
	SET @Strsql+='LEFT OUTER JOIN (SELECT EMPCTC.emp_cntId,EMPCTC.emp_reportTo,CNT.cnt_internalId AS REPORTTOID,ISNULL(CNT.CNT_FIRSTNAME,'''')+'' ''+ISNULL(CNT.CNT_MIDDLENAME,'''')+'' ''+ISNULL(CNT.CNT_LASTNAME,'''') AS REPORTTO,'
	SET @Strsql+='DESG.deg_designation AS RPTTODESG,CNT.cnt_UCC AS REPORTTOUID FROM tbl_master_employee EMP '
	SET @Strsql+='INNER JOIN tbl_trans_employeeCTC EMPCTC ON EMP.emp_id=EMPCTC.emp_reportTo '
	SET @Strsql+='INNER JOIN #TEMPCONTACT CNT ON CNT.cnt_internalId=EMP.emp_contactId '
	SET @Strsql+='INNER JOIN ( '
	SET @Strsql+='SELECT cnt.emp_cntId,desg.deg_designation,MAX(emp_id) as emp_id,desg.deg_id FROM tbl_trans_employeeCTC as cnt '
	SET @Strsql+='LEFT OUTER JOIN tbl_master_designation desg ON desg.deg_id=cnt.emp_Designation WHERE cnt.emp_effectiveuntil IS NULL GROUP BY emp_cntId,desg.deg_designation,desg.deg_id) DESG ON DESG.emp_cntId=EMP.emp_contactId '
	SET @Strsql+='WHERE EMPCTC.emp_effectiveuntil IS NULL) RPTTO ON RPTTO.emp_cntId=CNT.cnt_internalId '
	SET @Strsql+='INNER JOIN ('
	SET @Strsql+='SELECT USERID,MIN(LOGGEDIN) AS LOGGEDIN,MAX(LOGEDOUT) AS LOGEDOUT,cnt_internalId,WORKDATE,WORKDATEORDBY FROM('
	SET @Strsql+='SELECT USERID,LOGGEDIN,LOGEDOUT,cnt_internalId,Login_datetime AS WORKDATE,WORKDATEORDBY FROM #TMPATTENLOGINOUT '
	SET @Strsql+=') LOGINLOGOUT GROUP BY USERID,cnt_internalId,WORKDATE,WORKDATEORDBY '
	SET @Strsql+=') ATTEN ON ATTEN.cnt_internalId=CNT.cnt_internalId AND ATTEN.USERID=USR.user_id '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT USER_ID,CNT_INTERNALID,UNIQUEORDCNT,ORDCNT FROM('
	SET @Strsql+='SELECT USER_ID,CNT_INTERNALID,COUNT(DISTINCT SHOP_CODE) AS UNIQUEORDCNT,COUNT(SHOP_CODE) AS ORDCNT  '
	SET @Strsql+='FROM #TMPORDER '
	SET @Strsql+='GROUP BY USER_ID,CNT_INTERNALID '
	SET @Strsql+=') AA '
	SET @Strsql+=') ORDCNT ON CNT.cnt_internalId=ORDCNT.CNT_INTERNALID '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT DISTINCT COUNT(shop.Shop_Code) AS SHPCNT,shop.Shop_CreateUser '
	SET @Strsql+='FROM tbl_Master_shop shop '
	SET @Strsql+='GROUP BY shop.Shop_CreateUser '
	SET @Strsql+=') SHOP ON SHOP.Shop_CreateUser=USR.user_id '
	SET @Strsql+='LEFT OUTER JOIN ('
	SET @Strsql+='SELECT USER_ID,CNT_INTERNALID,SUM(ISNULL(ORDERVALUE,0)) AS ORDERVALUE,CONVERT(NVARCHAR(10),ORDH.ORDER_DATE,105) AS ORDER_DATE '
	SET @Strsql+='FROM #TMPORDER ORDH '
	SET @Strsql+='GROUP BY USER_ID,CNT_INTERNALID,CONVERT(NVARCHAR(10),ORDH.ORDER_DATE,105) '
	SET @Strsql+=') ORDHEAD ON CNT.cnt_internalId=ORDHEAD.cnt_internalId AND ATTEN.WORKDATE=ORDHEAD.ORDER_DATE '
	SET @Strsql+=') AS DB '
	SET @Strsql+='ORDER BY WORKDATE '

	--SELECT @Strsql
	EXEC SP_EXECUTESQL @Strsql

	DROP TABLE #DESIGNATION_LIST
	DROP TABLE #EMPLOYEE_LIST
	DROP TABLE #STATEID_LIST
	DROP TABLE #TEMPCONTACT
	IF ((SELECT IsAllDataInPortalwithHeirarchy FROM tbl_master_user WHERE user_id=@USERID)=1)
		BEGIN
			DROP TABLE #EMPHR_EDIT
			DROP TABLE #EMPHRS
		END
	DROP TABLE #TMPATTENLOGINOUT
	DROP TABLE #TMPORDER

	SET NOCOUNT OFF
END