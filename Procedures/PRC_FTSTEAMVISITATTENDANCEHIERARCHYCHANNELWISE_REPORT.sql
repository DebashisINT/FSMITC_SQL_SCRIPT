--EXEC PRC_FTSTEAMVISITATTENDANCEHIERARCHYCHANNELWISE_REPORT '2022-11-01','2022-11-16','','','',54685
--EXEC PRC_FTSTEAMVISITATTENDANCEHIERARCHYCHANNELWISE_REPORT '2022-11-01','2022-11-16','','','',54689
--EXEC PRC_FTSTEAMVISITATTENDANCEHIERARCHYCHANNELWISE_REPORT '2022-03-09','2022-03-09','1','EMA0000008,EMA0000016,EMA0000012,EMM0000002,EMA0000020','1,2,3,4,5,6,7,8',378
--EXEC PRC_FTSTEAMVISITATTENDANCEHIERARCHYCHANNELWISE_REPORT '2023-07-01','2023-08-04','','','',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSTEAMVISITATTENDANCEHIERARCHYCHANNELWISE_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSTEAMVISITATTENDANCEHIERARCHYCHANNELWISE_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSTEAMVISITATTENDANCEHIERARCHYCHANNELWISE_REPORT]
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
Written by : Debashis Talukder ON 16/11/2022
Module	   : Team Visit Attendance Hierarchy & Channel Wise.Refer: 0025220
1.0		v2.0.38		Debashis	23/12/2022		Total Days Present & Total Days Absent showing wrong in TEAM VISIT - HIERARCHY & CHANNEL WISE report.Refer: 0025541
2.0		v2.0.41		Debashis	09/08/2023		A coloumn named as Gender needs to be added in all the ITC reports.Refer: 0026680
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
	SET LOCK_TIMEOUT -1

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

	IF OBJECT_ID('tempdb..#TMPEHEADING') IS NOT NULL
		DROP TABLE #TMPEHEADING
	CREATE TABLE #TMPEHEADING
		(
			HEADID BIGINT,HEADNAME NVARCHAR(800),HEADSHRTNAME NVARCHAR(800),PARRENTID BIGINT
		)
	
	IF OBJECT_ID('tempdb..#EMPLOYEEATTENDANCETVHC') IS NOT NULL
	 DROP TABLE #EMPLOYEEATTENDANCETVHC
	
	--Rev 2.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
	CREATE TABLE #EMPLOYEEATTENDANCETVHC (BRANCH_ID BIGINT,BRANCH_DESCRIPTION NVARCHAR(300),USERID BIGINT,EMPCODE NVARCHAR(200),EMPID NVARCHAR(200),EMPNAME NVARCHAR(300),OUTLETEMPSEX TINYINT,
	GENDERDESC NVARCHAR(100),DSTLTYPE NVARCHAR(300),STATEID BIGINT,STATE NVARCHAR(300),DEG_ID BIGINT,DESIGNATION NVARCHAR(300),DATEOFJOINING NVARCHAR(10),CONTACTNO NVARCHAR(100),CH_ID BIGINT,
	CHANNEL NVARCHAR(100),REPORTTOIDWD NVARCHAR(100),REPORTTOUIDWD NVARCHAR(100),REPORTTOWD NVARCHAR(300),RPTTODESGWD NVARCHAR(100),REPORTTOIDAE NVARCHAR(100),REPORTTOUIDAE NVARCHAR(100),
	REPORTTOAE NVARCHAR(300),RPTTODESGAE NVARCHAR(100),SECTION NVARCHAR(MAX),CIRCLE NVARCHAR(MAX))
	CREATE NONCLUSTERED INDEX IX1 ON #EMPLOYEEATTENDANCETVHC (BRANCH_ID,EMPCODE)

	--FOR REPORT HEADER
	INSERT INTO #TMPEHEADING(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID)
	SELECT 1,'Employee Details [All Unit(s)]','Employee Details [All Unit(s)]',0
	UNION ALL
	SELECT 2,'Branch','BRANCH_DESCRIPTION',1
	UNION ALL
	SELECT 3,'AE ID','REPORTTOUIDAE',1
	UNION ALL
	SELECT 4,'WD ID','REPORTTOUIDWD',1
	UNION ALL
	SELECT 5,'DS/TL','EMPID',1
	UNION ALL
	SELECT 6,'DS/TL Name','EMPNAME',1
	--Rev 2.0
	--UNION ALL
	--SELECT 7,'DS/TL Type','DSTLTYPE',1
	--UNION ALL
	--SELECT 8,'Channel','CHANNEL',1
	--UNION ALL
	--SELECT 9,'Section','SECTION',1
	--UNION ALL
	--SELECT 10,'Circle','CIRCLE',1
	UNION ALL
	SELECT 7,'Gender','GENDERDESC',1
	UNION ALL
	SELECT 8,'DS/TL Type','DSTLTYPE',1
	UNION ALL
	SELECT 9,'Channel','CHANNEL',1
	UNION ALL
	SELECT 10,'Section','SECTION',1
	UNION ALL
	SELECT 11,'Circle','CIRCLE',1
	--End of Rev 2.0
	--FOR REPORT HEADER
	--Rev 2.0
	--SET @SLHEADID=10
	--SET @PARENTID=10
	SET @SLHEADID=11
	SET @PARENTID=11
	--End of Rev 2.0

	DECLARE @emp_contactId NVARCHAR(100)
	SET @COLUMN_DATE =@FROMDATE

	IF OBJECT_ID('tempdb..#TMPATTENDACETVHC') IS NOT NULL
		DROP TABLE #TMPATTENDACETVHC
	--Rev 2.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
	CREATE TABLE #TMPATTENDACETVHC(LOGIN_DATE NVARCHAR(10),BRANCH_ID BIGINT,BRANCH_DESCRIPTION NVARCHAR(300),USERID BIGINT,EMPCODE NVARCHAR(100),EMPID NVARCHAR(100),EMPNAME NVARCHAR(300),
	OUTLETEMPSEX TINYINT,GENDERDESC NVARCHAR(100),DSTLTYPE NVARCHAR(300),STATEID BIGINT,STATE NVARCHAR(100),DEG_ID BIGINT,DESIGNATION NVARCHAR(300),DATEOFJOINING NVARCHAR(10),CONTACTNO NVARCHAR(100),
	CH_ID BIGINT,CHANNEL NVARCHAR(100),PRESENTABSENT INT,REPORTTOIDWD NVARCHAR(100),REPORTTOUIDWD NVARCHAR(100),REPORTTOWD NVARCHAR(300),RPTTODESGWD NVARCHAR(100),REPORTTOIDAE NVARCHAR(100),
	REPORTTOUIDAE NVARCHAR(100),REPORTTOAE NVARCHAR(300),RPTTODESGAE NVARCHAR(100),SECTION NVARCHAR(MAX),CIRCLE NVARCHAR(MAX))
	CREATE NONCLUSTERED INDEX IX1 ON #TMPATTENDACETVHC (BRANCH_ID,EMPCODE)

	IF OBJECT_ID('tempdb..#TMPATTENDACEDETTVHC') IS NOT NULL
		DROP TABLE #TMPATTENDACEDETTVHC
	--Rev 2.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
	CREATE TABLE #TMPATTENDACEDETTVHC(LOGIN_DATE NVARCHAR(10),BRANCH_ID BIGINT,BRANCH_DESCRIPTION NVARCHAR(300),USERID BIGINT,EMPCODE NVARCHAR(100),EMPID NVARCHAR(100),EMPNAME NVARCHAR(300),
	OUTLETEMPSEX TINYINT,GENDERDESC NVARCHAR(100),DSTLTYPE NVARCHAR(300),STATEID BIGINT,STATE NVARCHAR(100),DEG_ID BIGINT,DESIGNATION NVARCHAR(300),DATEOFJOINING NVARCHAR(10),CONTACTNO NVARCHAR(100),
	CH_ID BIGINT,CHANNEL NVARCHAR(100),PRESENTABSENT INT,REPORTTOIDWD NVARCHAR(100),REPORTTOUIDWD NVARCHAR(100),REPORTTOWD NVARCHAR(300),RPTTODESGWD NVARCHAR(100),REPORTTOIDAE NVARCHAR(100),
	REPORTTOUIDAE NVARCHAR(100),REPORTTOAE NVARCHAR(300),RPTTODESGAE NVARCHAR(100),SECTION NVARCHAR(MAX),CIRCLE NVARCHAR(MAX))
	CREATE NONCLUSTERED INDEX IX1 ON #TMPATTENDACEDETTVHC (BRANCH_ID,EMPCODE)

	IF OBJECT_ID('tempdb..#TMPEMPATTENDACESUMMARYTVHC') IS NOT NULL
		DROP TABLE #TMPEMPATTENDACESUMMARYTVHC
	CREATE TABLE #TMPEMPATTENDACESUMMARYTVHC(BRANCH_ID BIGINT,BRANCH_DESCRIPTION NVARCHAR(300),USERID BIGINT,EMPCODE NVARCHAR(100),EMPID NVARCHAR(100),EMPNAME NVARCHAR(300),TOTWORKINGDAYS INT,
	PRESENTABSENT INT,ABSENTDAYS INT)
	CREATE NONCLUSTERED INDEX IX1 ON #TMPEMPATTENDACESUMMARYTVHC (BRANCH_ID,EMPCODE)

	INSERT INTO #TMPATTENDACEDETTVHC EXEC [PRC_FTSTEAMVISITATTENDANCEHIERARCHYCHANNELWISE_FETCH] @COLUMN_DATE,@TODATE,@BRANCHID,@EMPID,@CHANNELID,@USERID

	--Rev 1.0
	--INSERT INTO #TMPEMPATTENDACESUMMARYTVHC(BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,TOTWORKINGDAYS,PRESENTABSENT,ABSENTDAYS)
	--SELECT BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,@days AS TOTWORKINGDAYS,SUM(PRESENTABSENT) AS PRESENTABSENT,@days-SUM(PRESENTABSENT) AS ABSENTDAYS 
	--FROM #TMPATTENDACEDETTVHC 
	--GROUP BY BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME
	--ORDER BY EMPCODE
	INSERT INTO #TMPEMPATTENDACESUMMARYTVHC(BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,TOTWORKINGDAYS,PRESENTABSENT,ABSENTDAYS)
	SELECT DISTINCT BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,@days AS TOTWORKINGDAYS,SUM(DISTINCT PRESENTABSENT) AS PRESENTABSENT,@days-SUM(DISTINCT PRESENTABSENT) AS ABSENTDAYS 
	FROM #TMPATTENDACEDETTVHC 
	GROUP BY BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME
	ORDER BY EMPCODE
	--End of Rev 1.0

	SET @LOOPCOUNT=1
	IF @DAYCOUNT>0
		BEGIN
			WHILE @LOOPCOUNT<=@DAYCOUNT
				BEGIN				
					SET @SqlStrTable=''
					SET @SqlStrTable='ALTER TABLE #EMPLOYEEATTENDANCETVHC ADD '
					SET @SqlStrTable+='['+RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']' + ' NVARCHAR(50) NULL,'
					SET @SqlStrTable+='[PA_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'+ ' INT NULL ' 

					EXEC SP_EXECUTESQL @SqlStrTable

					SET @TODATE=@COLUMN_DATE

					--Rev 2.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
					INSERT INTO #TMPATTENDACETVHC(LOGIN_DATE,BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,OUTLETEMPSEX,GENDERDESC,DSTLTYPE,STATEID,STATE,DEG_ID,DESIGNATION,
					DATEOFJOINING,CONTACTNO,CH_ID,CHANNEL,PRESENTABSENT,REPORTTOIDWD,REPORTTOUIDWD,REPORTTOWD,RPTTODESGWD,REPORTTOIDAE,REPORTTOUIDAE,REPORTTOAE,RPTTODESGAE,SECTION,CIRCLE)
					SELECT LOGIN_DATE,BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,OUTLETEMPSEX,GENDERDESC,DSTLTYPE,STATEID,STATE,DEG_ID,DESIGNATION,DATEOFJOINING,CONTACTNO,CH_ID,
					CHANNEL,PRESENTABSENT,REPORTTOIDWD,REPORTTOUIDWD,REPORTTOWD,RPTTODESGWD,REPORTTOIDAE,REPORTTOUIDAE,REPORTTOAE,RPTTODESGAE,SECTION,CIRCLE FROM #TMPATTENDACEDETTVHC 
					WHERE LOGIN_DATE BETWEEN @COLUMN_DATE AND @TODATE

					IF (SELECT COUNT(0) FROM #EMPLOYEEATTENDANCETVHC A
						INNER JOIN #TMPATTENDACETVHC B ON A.BRANCH_ID=B.BRANCH_ID AND A.EMPCODE=B.EMPCODE AND B.LOGIN_DATE BETWEEN @COLUMN_DATE AND @TODATE)>0
						SET @FIRSTTIME=0
					ELSE
						SET @FIRSTTIME=1

					IF @FIRSTTIME=1
						BEGIN
							--Rev 2.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
							SET @SqlStrTable=''
							SET @SqlStrTable='INSERT INTO #EMPLOYEEATTENDANCETVHC(BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,OUTLETEMPSEX,GENDERDESC,DSTLTYPE,STATEID,STATE,DEG_ID,'
							SET @SqlStrTable+='DESIGNATION,DATEOFJOINING,CONTACTNO,CH_ID,CHANNEL,REPORTTOIDWD,REPORTTOUIDWD,REPORTTOWD,RPTTODESGWD,REPORTTOIDAE,REPORTTOUIDAE,REPORTTOAE,RPTTODESGAE,'
							SET @SqlStrTable+='SECTION,CIRCLE,[PA_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + '] '
							SET @SqlStrTable+=') '
							SET @SqlStrTable+='SELECT BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,OUTLETEMPSEX,GENDERDESC,DSTLTYPE,STATEID,STATE,DEG_ID,DESIGNATION,DATEOFJOINING,'
							SET @SqlStrTable+='CONTACTNO,CH_ID,CHANNEL,REPORTTOIDWD,REPORTTOUIDWD,REPORTTOWD,RPTTODESGWD,REPORTTOIDAE,REPORTTOUIDAE,REPORTTOAE,RPTTODESGAE,SECTION,CIRCLE,PRESENTABSENT '
							SET @SqlStrTable+='FROM #TMPATTENDACETVHC '

							EXEC SP_EXECUTESQL @SqlStrTable

							SET @FIRSTTIME=0					
						END
					ELSE IF @FIRSTTIME=0
						BEGIN
							--Rev 2.0 && Two new fields added as OUTLETEMPSEX & GENDERDESC
							SET @SqlStrTable=''
							SET @SqlStrTable='INSERT INTO #EMPLOYEEATTENDANCETVHC(BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,OUTLETEMPSEX,GENDERDESC,DSTLTYPE,STATEID,STATE,DEG_ID,'
							SET @SqlStrTable+='DESIGNATION,DATEOFJOINING,CONTACTNO,CH_ID,CHANNEL,REPORTTOIDWD,REPORTTOUIDWD,REPORTTOWD,RPTTODESGWD,REPORTTOIDAE,REPORTTOUIDAE,REPORTTOAE,RPTTODESGAE,'
							SET @SqlStrTable+='SECTION,CIRCLE,[PA_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + '] '
							SET @SqlStrTable+=') '
							SET @SqlStrTable+='SELECT BRANCH_ID,BRANCH_DESCRIPTION,USERID,EMPCODE,EMPID,EMPNAME,OUTLETEMPSEX,GENDERDESC,DSTLTYPE,STATEID,STATE,DEG_ID,DESIGNATION,DATEOFJOINING,'
							SET @SqlStrTable+='CONTACTNO,CH_ID,CHANNEL,REPORTTOIDWD,REPORTTOUIDWD,REPORTTOWD,RPTTODESGWD,REPORTTOIDAE,REPORTTOUIDAE,REPORTTOAE,RPTTODESGAE,SECTION,CIRCLE,PRESENTABSENT '
							SET @SqlStrTable+='FROM #TMPATTENDACETVHC WHERE NOT EXISTS(SELECT EMPCODE FROM #EMPLOYEEATTENDANCETVHC A WHERE A.BRANCH_ID=#TMPATTENDACETVHC.BRANCH_ID AND A.EMPCODE=#TMPATTENDACETVHC.EMPCODE) '

							EXEC SP_EXECUTESQL @SqlStrTable

							SET @SqlStrTable=''
							SET @SqlStrTable='UPDATE TEMP SET '
							SET @SqlStrTable+='TEMP.[PA_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']=T.PRESENTABSENT '
							SET @sqlStrTable+='FROM #EMPLOYEEATTENDANCETVHC TEMP '
							SET @sqlStrTable+='INNER JOIN #TMPATTENDACETVHC T ON TEMP.BRANCH_ID=T.BRANCH_ID AND TEMP.EMPCODE=T.EMPCODE '
						
							EXEC SP_EXECUTESQL @sqlStrTable
						END
						TRUNCATE TABLE #TMPATTENDACETVHC
						DELETE FROM #TMPATTENDACEDETTVHC WHERE LOGIN_DATE BETWEEN @COLUMN_DATE AND @TODATE

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

	ALTER TABLE #EMPLOYEEATTENDANCETVHC ADD Summary NVARCHAR(100)
	ALTER TABLE #EMPLOYEEATTENDANCETVHC ADD TOTWORKINGDAYS INT DEFAULT(0) WITH VALUES
	ALTER TABLE #EMPLOYEEATTENDANCETVHC ADD TOTDAYSPRESENT INT DEFAULT(0) WITH VALUES
	ALTER TABLE #EMPLOYEEATTENDANCETVHC ADD TOTDAYSABSENT INT DEFAULT(0) WITH VALUES

	UPDATE EMPATT SET EMPATT.TOTWORKINGDAYS=T.TOTWORKINGDAYS,EMPATT.TOTDAYSPRESENT=T.PRESENTABSENT,EMPATT.TOTDAYSABSENT=T.ABSENTDAYS FROM #EMPLOYEEATTENDANCETVHC AS EMPATT 
	INNER JOIN #TMPEMPATTENDACESUMMARYTVHC T ON EMPATT.BRANCH_ID=T.BRANCH_ID AND EMPATT.EMPCODE=T.EMPCODE

	SELECT * FROM #TMPEHEADING ORDER BY HEADID
	SELECT * FROM #EMPLOYEEATTENDANCETVHC ORDER BY EMPNAME

	DROP TABLE #EMPLOYEEATTENDANCETVHC
	DROP TABLE #TMPEHEADING
	DROP TABLE #TMPSHOWSUNDAY
	DROP TABLE #TMPEMPATTENDACESUMMARYTVHC
	DROP TABLE #TMPATTENDACETVHC
	DROP TABLE #TMPATTENDACEDETTVHC

	SET NOCOUNT OFF
END