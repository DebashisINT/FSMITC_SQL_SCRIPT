--EXEC PRC_FTSTEAMVISITATTENDANCE_REPORT '2023-07-01','2023-08-10','','','1,4',378
--EXEC PRC_FTSTEAMVISITATTENDANCE_REPORT '2022-03-09','2022-03-09','1','EMA0000008,EMA0000016,EMA0000012,EMM0000002,EMA0000020','1,2,3,4,5,6,7,8',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSTEAMVISITATTENDANCE_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSTEAMVISITATTENDANCE_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSTEAMVISITATTENDANCE_REPORT]
(
@FROMDATE NVARCHAR(10)=NULL,
@TODATE NVARCHAR(10)=NULL,
@BRANCHID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@CHANNELID NVARCHAR(MAX)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder ON 04/03/2022
Module	   : Dynamic Team Visit Attendance.Refer: 0024720
1.0		v2.0.28		Debashis	25/03/2022		FSM : Team Visit report and Employee Attendance report Chages required:
												'Total Days absent' should be calculated (Total working days - (minus) Total Days Present).Refer: 0024763
2.0		v2.0.28		Debashis	28/03/2022		Implement field type number for Team Visit Report.Refer: 0024775
3.0		v2.0.29		Debashis	10/05/2022		FSM > MIS Reports > Team Visit Report
												There, two columns required after DS ID column :
												a) DS/TL Name [Contact table]
												b) DS/TL Type [FaceRegTypeID from tbl_master_user].Refer: 0024870
4.0		v2.0.33		Debashis	10/10/2022		'Section' and 'Circle' columns required [After the 'Channel' column].Refer: 0025219
5.0		v2.0.33		Debashis	18/10/2022		Team Visit - data shall be generated based on attendance IN data.Refer: 0025387
6.0		v2.0.35		Debashis	15/11/2022		Need to optimized Employee Attendance, Team Visit and Qualified Attendance reports in ITC Portal.Refer: 0025453
7.0		v2.0.41		Debashis	09/08/2023		A coloumn named as Gender needs to be added in all the ITC reports.Refer: 0026680
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	--Rev 6.0
	SET LOCK_TIMEOUT -1
	--End of Rev 6.0
	DECLARE @DAYCOUNT INT,@LOOPCOUNT INT,@FIRSTTIME BIT=1
	DECLARE @SqlStrTable NVARCHAR(MAX)
	DECLARE @COLUMN_DATE NVARCHAR(10)=@FROMDATE
	DECLARE @SLHEADID BIGINT,@PARENTID BIGINT

	DECLARE @days AS INT,@FIRSTDATEOFMONTH DATETIME,@CURRENTDATEOFMONTH DATETIME,@EMP_IDs NVARCHAR(MAX)
	SELECT @FIRSTDATEOFMONTH = @FROMDATE
	SELECT @CURRENTDATEOFMONTH = @TODATE

	;WITH CTE AS (SELECT 1 AS DAYID,@FIRSTDATEOFMONTH AS FROMDATE,DATENAME(DW, @FIRSTDATEOFMONTH) AS DAYNAME
	UNION ALL
	SELECT CTE.DAYID + 1 AS DAYID,DATEADD(D, 1 ,CTE.FROMDATE),DATENAME(DW, DATEADD(D, 1 ,CTE.FROMDATE)) AS DAYNAME
	FROM CTE
	WHERE DATEADD(D,1,CTE.FROMDATE) <= @CURRENTDATEOFMONTH
	)
	SELECT FROMDATE AS SUNDAYDATE,DAYNAME INTO #TMPSHOWSUNDAY
	FROM CTE
	WHERE DAYNAME IN ('Sunday')
	OPTION (MAXRECURSION 1000)

	SELECT @DAYCOUNT=DATEDIFF(D, @FROMDATE, @TODATE) +1

	SET @days=(SELECT @DAYCOUNT-COUNT(DAYNAME) FROM #TMPSHOWSUNDAY)

	--Rev 6.0
	--SET @EMP_IDs=@EMPID
	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#EMPLOYEE_LIST') AND TYPE IN (N'U'))
	--	DROP TABLE #EMPLOYEE_LIST
	--CREATE TABLE #EMPLOYEE_LIST (emp_contactId NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS)
	--IF @EMP_IDs <> ''
	--	BEGIN
	--		SET @EMP_IDs = REPLACE(''''+@EMP_IDs+'''',',',''',''')
	--		SET @SqlStrTable=''
	--		SET @SqlStrTable='INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId from tbl_master_employee where emp_contactId in('+@EMP_IDs+')'
	--		EXEC SP_EXECUTESQL @SqlStrTable
	--	END
	--ELSE
	--	BEGIN
	--		SET @SqlStrTable=''
	--		SET @SqlStrTable='INSERT INTO #EMPLOYEE_LIST SELECT emp_contactId FROM tbl_master_employee '
	--		EXEC SP_EXECUTESQL @SqlStrTable
	--	END

	--IF OBJECT_ID('tempdb..#CHANNEL_LIST') IS NOT NULL
	--	DROP TABLE #CHANNEL_LIST
	--CREATE TABLE #CHANNEL_LIST (CH_ID BIGINT)

	--IF @CHANNELID <> ''
	--	BEGIN
	--		SET @CHANNELID=REPLACE(@CHANNELID,'''','')
	--		SET @SqlStrTable=''
	--		SET @SqlStrTable='INSERT INTO #CHANNEL_LIST SELECT CH_ID FROM Employee_Channel WHERE CH_ID IN('+@CHANNELID+')'
	--		EXEC SP_EXECUTESQL @SqlStrTable
	--	END	

	--IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#TMPMASTEMPLOYEE') AND TYPE IN (N'U'))
	--	DROP TABLE #TMPMASTEMPLOYEE
	--CREATE TABLE #TMPMASTEMPLOYEE(EMP_ID NUMERIC(18, 0) NOT NULL,EMP_UNIQUECODE VARCHAR(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,EMP_CONTACTID NVARCHAR(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL)
	--CREATE NONCLUSTERED INDEX IX1 ON #TMPMASTEMPLOYEE (EMP_CONTACTID ASC)

	--INSERT INTO #TMPMASTEMPLOYEE SELECT EMP_ID,EMP_UNIQUECODE,EMP_CONTACTID FROM tbl_master_employee
	--End of Rev 6.0

	IF OBJECT_ID('tempdb..#TMPEHEADING') IS NOT NULL
		DROP TABLE #TMPEHEADING
	CREATE TABLE #TMPEHEADING
		(
			HEADID BIGINT,HEADNAME NVARCHAR(800),HEADSHRTNAME NVARCHAR(800),PARRENTID BIGINT
		)
	
	IF OBJECT_ID('tempdb..#EMPLOYEEATTENDANCE') IS NOT NULL
	 DROP TABLE #EMPLOYEEATTENDANCE
	
	--Rev 3.0 && A new field added as DSTLTYPE
	--Rev 4.0 && Two new fields added as SECTION & CIRCLE
	--Rev 7.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
	CREATE TABLE #EMPLOYEEATTENDANCE (BRANCH_ID BIGINT,BRANCH_DESCRIPTION NVARCHAR(300),USERID BIGINT,EMPCODE NVARCHAR(200),EMPID NVARCHAR(200),EMPNAME NVARCHAR(300),OUTLETEMPSEX TINYINT,
	GENDERDESC NVARCHAR(100),DSTLTYPE NVARCHAR(300),STATEID BIGINT,STATE NVARCHAR(300),DEG_ID BIGINT,DESIGNATION NVARCHAR(300),DATEOFJOINING NVARCHAR(10),CONTACTNO NVARCHAR(100),CH_ID BIGINT,
	CHANNEL NVARCHAR(100),REPORTTOID NVARCHAR(100),REPORTTOUID NVARCHAR(100),REPORTTO NVARCHAR(300),RPTTODESG NVARCHAR(100),SECTION NVARCHAR(MAX),CIRCLE NVARCHAR(MAX))
	CREATE NONCLUSTERED INDEX IX1 ON #EMPLOYEEATTENDANCE (BRANCH_ID,EMPCODE)

	--FOR REPORT HEADER
	INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID)
	SELECT 1,'Employee Details [All Unit(s)]','Employee Details [All Unit(s)]',0
	UNION ALL
	SELECT 2,'Branch','BRANCH_DESCRIPTION',1	
	UNION ALL
	SELECT 3,'WD ID','REPORTTOUID',1
	UNION ALL
	SELECT 4,'DS/TL','EMPID',1
	--Rev 3.0
	--UNION ALL
	--SELECT 5,'Channel','CHANNEL',1
	----FOR REPORT HEADER
	--SET @SLHEADID=5
	--SET @PARENTID=5
	UNION ALL
	SELECT 5,'DS/TL Name','EMPNAME',1
	--Rev 7.0
	--UNION ALL
	--SELECT 6,'DS/TL Type','DSTLTYPE',1
	--UNION ALL
	--SELECT 7,'Channel','CHANNEL',1
	----Rev 4.0
	--UNION ALL
	--SELECT 8,'Section','SECTION',1
	--UNION ALL
	--SELECT 9,'Circle','CIRCLE',1
	UNION ALL
	SELECT 6,'Gender','GENDERDESC',1
	UNION ALL
	SELECT 7,'DS/TL Type','DSTLTYPE',1
	UNION ALL
	SELECT 8,'Channel','CHANNEL',1
	UNION ALL
	SELECT 9,'Section','SECTION',1
	UNION ALL
	SELECT 10,'Circle','CIRCLE',1
	--End of Rev 7.0
	--End of Rev 4.0
	--FOR REPORT HEADER
	--Rev 4.0
	--SET @SLHEADID=7
	--SET @PARENTID=7
	--Rev 7.0
	--SET @SLHEADID=9
	--SET @PARENTID=9
	SET @SLHEADID=10
	SET @PARENTID=10
	--End of Rev 7.0
	--End of Rev 4.0
	--End of Rev 3.0

	DECLARE @emp_contactId NVARCHAR(100)
	SET @COLUMN_DATE =@FROMDATE

	IF OBJECT_ID('tempdb..#TMPATTENDACE') IS NOT NULL
		DROP TABLE #TMPATTENDACE
	--Rev 3.0 && A new field added as DSTLTYPE
	--Rev 4.0 && Two new fields added as SECTION & CIRCLE
	--Rev 6.0 && A new column has been added as LOGIN_DATE NVARCHAR(10)
	--Rev 7.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
	CREATE TABLE #TMPATTENDACE(LOGIN_DATE NVARCHAR(10),BRANCH_ID BIGINT,BRANCH_DESCRIPTION NVARCHAR(300),USERID BIGINT,EMPCODE NVARCHAR(100),EMPID NVARCHAR(100),EMPNAME NVARCHAR(300),OUTLETEMPSEX TINYINT,
	GENDERDESC NVARCHAR(100),DSTLTYPE NVARCHAR(300),STATEID BIGINT,STATE NVARCHAR(100),DEG_ID BIGINT,DESIGNATION NVARCHAR(300),DATEOFJOINING NVARCHAR(10),CONTACTNO NVARCHAR(100),CH_ID BIGINT,
	CHANNEL NVARCHAR(100),PRESENTABSENT INT,REPORTTOID NVARCHAR(100),REPORTTOUID NVARCHAR(100),REPORTTO NVARCHAR(300),RPTTODESG NVARCHAR(100),SECTION NVARCHAR(MAX),CIRCLE NVARCHAR(MAX))
	CREATE NONCLUSTERED INDEX IX1 ON #TMPATTENDACE (BRANCH_ID,EMPCODE)

	--Rev 6.0
	--IF OBJECT_ID('tempdb..#TMPEMPATTENDACESUMMARY') IS NOT NULL
	--	DROP TABLE #TMPEMPATTENDACESUMMARY
	--CREATE TABLE #TMPEMPATTENDACESUMMARY(BRANCH_ID BIGINT,BRANCH_DESCRIPTION NVARCHAR(300),USERID BIGINT,EMPCODE NVARCHAR(100),EMPID NVARCHAR(100),EMPNAME NVARCHAR(300),ATTEN_STATUS NVARCHAR(300),
	--TOTWORKINGDAYS INT)
	--CREATE NONCLUSTERED INDEX IX1 ON #TMPEMPATTENDACESUMMARY (BRANCH_ID,EMPCODE)

	IF OBJECT_ID('tempdb..#TMPATTENDACEDET') IS NOT NULL
		DROP TABLE #TMPATTENDACEDET
	--Rev 7.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
	CREATE TABLE #TMPATTENDACEDET(LOGIN_DATE NVARCHAR(10),BRANCH_ID BIGINT,BRANCH_DESCRIPTION NVARCHAR(300),USERID BIGINT,EMPCODE NVARCHAR(100),EMPID NVARCHAR(100),EMPNAME NVARCHAR(300),OUTLETEMPSEX TINYINT,
	GENDERDESC NVARCHAR(100),DSTLTYPE NVARCHAR(300),STATEID BIGINT,STATE NVARCHAR(100),DEG_ID BIGINT,DESIGNATION NVARCHAR(300),DATEOFJOINING NVARCHAR(10),CONTACTNO NVARCHAR(100),CH_ID BIGINT,
	CHANNEL NVARCHAR(100),PRESENTABSENT INT,REPORTTOID NVARCHAR(100),REPORTTOUID NVARCHAR(100),REPORTTO NVARCHAR(300),RPTTODESG NVARCHAR(100),SECTION NVARCHAR(MAX),CIRCLE NVARCHAR(MAX))
	CREATE NONCLUSTERED INDEX IX1 ON #TMPATTENDACEDET (BRANCH_ID,EMPCODE)

	IF OBJECT_ID('tempdb..#TMPEMPATTENDACESUMMARY') IS NOT NULL
		DROP TABLE #TMPEMPATTENDACESUMMARY
	CREATE TABLE #TMPEMPATTENDACESUMMARY(BRANCH_ID BIGINT,BRANCH_DESCRIPTION NVARCHAR(300),USERID BIGINT,EMPCODE NVARCHAR(100),EMPID NVARCHAR(100),EMPNAME NVARCHAR(300),TOTWORKINGDAYS INT,
	PRESENTABSENT INT,ABSENTDAYS INT)
	CREATE NONCLUSTERED INDEX IX1 ON #TMPEMPATTENDACESUMMARY (BRANCH_ID,EMPCODE)

	INSERT INTO #TMPATTENDACEDET EXEC [PRC_FTSTEAMVISITATTENDANCE_FETCH] @COLUMN_DATE,@TODATE,@BRANCHID,@EMPID,@CHANNELID,@USERID

	INSERT INTO #TMPEMPATTENDACESUMMARY(BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,TOTWORKINGDAYS,PRESENTABSENT,ABSENTDAYS)
	SELECT BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,@days AS TOTWORKINGDAYS,SUM(PRESENTABSENT) AS PRESENTABSENT,@days-SUM(PRESENTABSENT) AS ABSENTDAYS FROM #TMPATTENDACEDET 
	GROUP BY BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME
	ORDER BY EMPCODE
	--End of Rev 6.0

	SET @LOOPCOUNT=1
	IF @DAYCOUNT>0
		BEGIN
			WHILE @LOOPCOUNT<=@DAYCOUNT
				BEGIN				
					SET @SqlStrTable=''
					SET @SqlStrTable='ALTER TABLE #EMPLOYEEATTENDANCE ADD '
					SET @SqlStrTable+='['+RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']' + ' NVARCHAR(50) NULL,'
					--Rev 2.0
					--SET @SqlStrTable+='[PA_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'+ ' NVARCHAR(30) NULL ' 
					SET @SqlStrTable+='[PA_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'+ ' INT NULL ' 
					--End of Rev 2.0

					EXEC SP_EXECUTESQL @SqlStrTable

					--Rev 5.0
					SET @TODATE=@COLUMN_DATE
					--End of Rev 5.0

					--Rev 6.0
					--INSERT INTO #TMPATTENDACE EXEC [PRC_FTSTEAMVISITATTENDANCE_FETCH] @COLUMN_DATE,@TODATE,@BRANCHID,@EMPID,@CHANNELID,@USERID
					--Rev 7.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
					INSERT INTO #TMPATTENDACE(LOGIN_DATE,BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,OUTLETEMPSEX,GENDERDESC,DSTLTYPE,STATEID,STATE,DEG_ID,DESIGNATION,DATEOFJOINING,
					CONTACTNO,CH_ID,CHANNEL,PRESENTABSENT,REPORTTOID,REPORTTOUID,REPORTTO,RPTTODESG,SECTION,CIRCLE)
					SELECT LOGIN_DATE,BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,OUTLETEMPSEX,GENDERDESC,DSTLTYPE,STATEID,STATE,DEG_ID,DESIGNATION,DATEOFJOINING,CONTACTNO,CH_ID,
					CHANNEL,PRESENTABSENT,REPORTTOID,REPORTTOUID,REPORTTO,RPTTODESG,SECTION,CIRCLE FROM #TMPATTENDACEDET WHERE LOGIN_DATE BETWEEN @COLUMN_DATE AND @TODATE

					IF (SELECT COUNT(0) FROM #EMPLOYEEATTENDANCE A
						INNER JOIN #TMPATTENDACE B ON A.BRANCH_ID=B.BRANCH_ID AND A.EMPCODE=B.EMPCODE AND B.LOGIN_DATE BETWEEN @COLUMN_DATE AND @TODATE)>0
						SET @FIRSTTIME=0
					ELSE
						SET @FIRSTTIME=1
					--End of Rev 6.0

					IF @FIRSTTIME=1
						BEGIN
							--Rev 3.0 && A new field added as DSTLTYPE
							--Rev 4.0 && Two new fields added as SECTION & CIRCLE
							--Rev 7.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
							SET @SqlStrTable=''
							SET @SqlStrTable='INSERT INTO #EMPLOYEEATTENDANCE(BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,OUTLETEMPSEX,GENDERDESC,DSTLTYPE,STATEID,STATE,DEG_ID,'
							SET @SqlStrTable+='DESIGNATION,DATEOFJOINING,CONTACTNO,CH_ID,CHANNEL,REPORTTOID,REPORTTOUID,REPORTTO,RPTTODESG,SECTION,CIRCLE,'
							SET @SqlStrTable+='[PA_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + '] '
							SET @SqlStrTable+=') '
							SET @SqlStrTable+='SELECT BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,OUTLETEMPSEX,GENDERDESC,DSTLTYPE,STATEID,STATE,DEG_ID,DESIGNATION,DATEOFJOINING,'
							SET @SqlStrTable+='CONTACTNO,CH_ID,CHANNEL,REPORTTOID,REPORTTOUID,REPORTTO,RPTTODESG,SECTION,CIRCLE,PRESENTABSENT '
							SET @SqlStrTable+='FROM #TMPATTENDACE '

							EXEC SP_EXECUTESQL @SqlStrTable

							SET @FIRSTTIME=0					
						END
					ELSE IF @FIRSTTIME=0
						BEGIN
							--Rev 6.0
							--Rev 7.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
							SET @SqlStrTable=''
							SET @SqlStrTable='INSERT INTO #EMPLOYEEATTENDANCE(BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,OUTLETEMPSEX,GENDERDESC,DSTLTYPE,STATEID,STATE,DEG_ID,'
							SET @SqlStrTable+='DESIGNATION,DATEOFJOINING,CONTACTNO,CH_ID,CHANNEL,REPORTTOID,REPORTTOUID,REPORTTO,RPTTODESG,SECTION,CIRCLE,'
							SET @SqlStrTable+='[PA_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + '] '
							SET @SqlStrTable+=') '
							SET @SqlStrTable+='SELECT BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,OUTLETEMPSEX,GENDERDESC,DSTLTYPE,STATEID,STATE,DEG_ID,DESIGNATION,DATEOFJOINING,'
							SET @SqlStrTable+='CONTACTNO,CH_ID,CHANNEL,REPORTTOID,REPORTTOUID,REPORTTO,RPTTODESG,SECTION,CIRCLE,PRESENTABSENT '
							SET @SqlStrTable+='FROM #TMPATTENDACE WHERE NOT EXISTS(SELECT EMPCODE FROM #EMPLOYEEATTENDANCE A WHERE A.BRANCH_ID=#TMPATTENDACE.BRANCH_ID AND A.EMPCODE=#TMPATTENDACE.EMPCODE) '

							EXEC SP_EXECUTESQL @SqlStrTable
							--End of Rev 6.0

							SET @SqlStrTable=''
							SET @SqlStrTable='UPDATE TEMP SET '
							SET @SqlStrTable+='TEMP.[PA_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']=T.PRESENTABSENT '
							SET @sqlStrTable+='FROM #EMPLOYEEATTENDANCE TEMP '
							SET @sqlStrTable+='INNER JOIN #TMPATTENDACE T ON TEMP.BRANCH_ID=T.BRANCH_ID AND TEMP.EMPCODE=T.EMPCODE '
						
							EXEC SP_EXECUTESQL @sqlStrTable
						END
						TRUNCATE TABLE #TMPATTENDACE
						--Rev 6.0
						DELETE FROM #TMPATTENDACEDET WHERE LOGIN_DATE BETWEEN @COLUMN_DATE AND @TODATE
						--End of Rev 6.0

						--FOR REPORT HEADER
						SET @PARENTID=@SLHEADID+1
					
						INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
						SELECT @SLHEADID+1 AS HEADID,CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105) AS HEADNAME,RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,0 AS PARRENTID 

						INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
						SELECT @SLHEADID+2 AS HEADID,'Present/Absent' AS HEADNAME,'PA_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 

						SET @SLHEADID=@SLHEADID+2

						--FOR REPORT HEADER

						SET @COLUMN_DATE=CONVERT(NVARCHAR(10),(SELECT DATEADD(D, 1, @COLUMN_DATE)),120)
						SET @LOOPCOUNT=@LOOPCOUNT+1
				END
		END

	INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID)
	SELECT @SLHEADID+1,'Summary','Summary',0
	UNION ALL
	SELECT @SLHEADID+2,'Total Working Days','TOTWORKINGDAYS',@SLHEADID+1
	UNION ALL
	SELECT @SLHEADID+3,'Total Days Present','TOTDAYSPRESENT',@SLHEADID+1
	UNION ALL
	SELECT @SLHEADID+4,'Total Days Absent','TOTDAYSABSENT',@SLHEADID+1

	ALTER TABLE #EMPLOYEEATTENDANCE ADD Summary NVARCHAR(100)
	ALTER TABLE #EMPLOYEEATTENDANCE ADD TOTWORKINGDAYS INT DEFAULT(0) WITH VALUES
	ALTER TABLE #EMPLOYEEATTENDANCE ADD TOTDAYSPRESENT INT DEFAULT(0) WITH VALUES
	ALTER TABLE #EMPLOYEEATTENDANCE ADD TOTDAYSABSENT INT DEFAULT(0) WITH VALUES

	--Rev 6.0
	--INSERT INTO #TMPEMPATTENDACESUMMARY EXEC [PRC_FTSTEAMVISITATTENDANCESUMMARY_FETCH] @FROMDATE,@TODATE,@BRANCHID,@EMPID,@CHANNELID,@USERID

	--UPDATE EMPATT SET EMPATT.TOTWORKINGDAYS=T.TOTWORKINGDAYS FROM #EMPLOYEEATTENDANCE AS EMPATT 
	--INNER JOIN #TMPEMPATTENDACESUMMARY T ON EMPATT.BRANCH_ID=T.BRANCH_ID AND EMPATT.EMPCODE=T.EMPCODE

	--UPDATE EMPATT SET EMPATT.TOTDAYSPRESENT=T.TOTWORKINGDAYS FROM #EMPLOYEEATTENDANCE AS EMPATT 
	--INNER JOIN (SELECT BRANCH_ID,EMPCODE,COUNT(ATTEN_STATUS) AS TOTWORKINGDAYS FROM #TMPEMPATTENDACESUMMARY WHERE ATTEN_STATUS='Present' GROUP BY BRANCH_ID,EMPCODE) T ON EMPATT.BRANCH_ID=T.BRANCH_ID 
	--AND EMPATT.EMPCODE=T.EMPCODE

	----Rev 1.0
	----UPDATE EMPATT SET EMPATT.TOTDAYSABSENT=T.TOTDAYSABSENT FROM #EMPLOYEEATTENDANCE AS EMPATT 
	----INNER JOIN (SELECT BRANCH_ID,EMPCODE,COUNT(ATTEN_STATUS) AS TOTDAYSABSENT FROM #TMPEMPATTENDACESUMMARY WHERE ATTEN_STATUS='Not Logged In' GROUP BY BRANCH_ID,EMPCODE) T ON EMPATT.BRANCH_ID=T.BRANCH_ID 
	----AND EMPATT.EMPCODE=T.EMPCODE
	--UPDATE EMPATT SET EMPATT.TOTDAYSABSENT=T.TOTDAYSABSENT FROM #EMPLOYEEATTENDANCE AS EMPATT 
	--INNER JOIN (
	--SELECT ABSNT.BRANCH_ID,ABSNT.EMPCODE,(SUM(ABSNT.TOTWORKINGDAYS)-SUM(ABSNT.TOTDAYSPRESENT)) AS TOTDAYSABSENT FROM(
	--SELECT BRANCH_ID,EMPCODE,(TOTWORKINGDAYS) AS TOTWORKINGDAYS,0 AS TOTDAYSPRESENT FROM #TMPEMPATTENDACESUMMARY GROUP BY BRANCH_ID,EMPCODE,TOTWORKINGDAYS
	--UNION ALL
	--SELECT BRANCH_ID,EMPCODE,0 AS TOTWORKINGDAYS,COUNT(ATTEN_STATUS) AS TOTDAYSPRESENT FROM #TMPEMPATTENDACESUMMARY WHERE ATTEN_STATUS='Present' GROUP BY BRANCH_ID,EMPCODE
	--) ABSNT GROUP BY ABSNT.BRANCH_ID,ABSNT.EMPCODE
	--) T ON EMPATT.BRANCH_ID=T.BRANCH_ID 
	--AND EMPATT.EMPCODE=T.EMPCODE
	----End of Rev 1.0

	UPDATE EMPATT SET EMPATT.TOTWORKINGDAYS=T.TOTWORKINGDAYS,EMPATT.TOTDAYSPRESENT=T.PRESENTABSENT,EMPATT.TOTDAYSABSENT=T.ABSENTDAYS FROM #EMPLOYEEATTENDANCE AS EMPATT 
	INNER JOIN #TMPEMPATTENDACESUMMARY T ON EMPATT.BRANCH_ID=T.BRANCH_ID AND EMPATT.EMPCODE=T.EMPCODE
	--End of Rev 6.0

	SELECT * FROM #TMPEHEADING ORDER BY HEADID
	--Rev 6.0
	--SELECT * FROM #EMPLOYEEATTENDANCE
	SELECT * FROM #EMPLOYEEATTENDANCE ORDER BY EMPNAME
	--End of Rev 6.0

	DROP TABLE #EMPLOYEEATTENDANCE
	DROP TABLE #TMPEHEADING
	DROP TABLE #TMPSHOWSUNDAY
	DROP TABLE #TMPEMPATTENDACESUMMARY
	--Rev 6.0
	DROP TABLE #TMPATTENDACE
	DROP TABLE #TMPATTENDACEDET
	--End of Rev 6.0

	SET NOCOUNT OFF
END