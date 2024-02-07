--EXEC PRC_FTSPERFORMANCESUMMARYMTD_REPORT 'MAY','2023','','','',378

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSPERFORMANCESUMMARYMTD_REPORT]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSPERFORMANCESUMMARYMTD_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSPERFORMANCESUMMARYMTD_REPORT]
(
@MONTH NVARCHAR(3)=NULL,
@YEARS NVARCHAR(10)=NULL,
@STATEID NVARCHAR(MAX)=NULL,
@DESIGNID NVARCHAR(MAX)=NULL,
@EMPID NVARCHAR(MAX)=NULL,
@USERID INT
) --WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 03/07/2023
Module	   : Employee Performance Month to Date.Refer: 0026427
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON

	SET LOCK_TIMEOUT -1

	DECLARE @SqlStrTable NVARCHAR(MAX),@COLUMN_DATE NVARCHAR(10),@DAYCOUNT INT,@LOOPCOUNT INT,@FIRSTTIME BIT=1,@MONTHNAME NVARCHAR(3),@MONTHNO INT=0,@FROMDATE NVARCHAR(10),@TODATE NVARCHAR(10)
	DECLARE @SLHEADID BIGINT,@PARENTID BIGINT

	SET @MONTHNAME=@MONTH
	SET @MONTHNO=DATEPART(MM,@MONTHNAME+'01 1900')
	SET @FROMDATE=CONVERT(VARCHAR(10),DATEADD(MONTH, CONVERT(INT,@MONTHNO) - 1, @YEARS),120)
	SET @TODATE=CONVERT(VARCHAR(10),DATEADD(DAY, -1, DATEADD(MONTH, CONVERT(INT,@MONTHNO), @YEARS)),120)
	SET @COLUMN_DATE=@FROMDATE

	SELECT @DAYCOUNT=DATEDIFF(D, @FROMDATE, @TODATE) +1

	IF OBJECT_ID('tempdb..#TMPHEADINGPMTD') IS NOT NULL
		DROP TABLE #TMPHEADINGPMTD
	CREATE TABLE #TMPHEADINGPMTD
		(
			HEADID BIGINT,HEADNAME NVARCHAR(800),HEADSHRTNAME NVARCHAR(800),PARRENTID BIGINT
		)
	
	IF OBJECT_ID('tempdb..#EMPPERFORMANCEMTD') IS NOT NULL
	 DROP TABLE #EMPPERFORMANCEMTD
	
	CREATE TABLE #EMPPERFORMANCEMTD (WORKDATE NVARCHAR(10),WORKDATEORDBY NVARCHAR(10),USERID BIGINT,EMPCODE NVARCHAR(100),EMPID NVARCHAR(100),EMPNAME NVARCHAR(300),CONTACTNO NVARCHAR(100),
	DEG_ID BIGINT,DESIGNATION NVARCHAR(300),STATEID BIGINT,STATE NVARCHAR(100),REPORTTOID NVARCHAR(100),REPORTTOUID NVARCHAR(100),REPORTTO NVARCHAR(300),RPTTODESG NVARCHAR(100),TOTALSHPCNT INT,
	UNIQUESHOPCNT INT,PERCENTOFCOVERAGE DECIMAL(18,2),TOTAL_VISIT INT)
	CREATE NONCLUSTERED INDEX IX1 ON #EMPPERFORMANCEMTD (EMPCODE)

	--FOR REPORT HEADER
	INSERT INTO #TMPHEADINGPMTD(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID)
	SELECT 1,'Employee Details','Employee Details',0
	UNION ALL
	SELECT 2,'Reporting Manager','REPORTTO',1	
	UNION ALL
	SELECT 3,'Employee name','EMPNAME',1
	UNION ALL
	SELECT 4,'Employee Code','EMPID',1
	UNION ALL
	SELECT 5,'Customer Base','TOTALSHPCNT',1
	UNION ALL
	SELECT 6,'Unique Customer','UNIQUESHOPCNT',1
	UNION ALL
	SELECT 7,'% of Coverage','PERCENTOFCOVERAGE',1
	UNION ALL
	SELECT 8,'Total Visit','TOTAL_VISIT',1
	SET @SLHEADID=8
	SET @PARENTID=8

	DECLARE @emp_contactId NVARCHAR(100)
	SET @COLUMN_DATE =@FROMDATE

	IF OBJECT_ID('tempdb..#TMPPERFORMANCEMTD') IS NOT NULL
		DROP TABLE #TMPPERFORMANCEMTD
	CREATE TABLE #TMPPERFORMANCEMTD(WORKDATE NVARCHAR(10),WORKDATEORDBY NVARCHAR(10),USERID BIGINT,EMPCODE NVARCHAR(100),EMPID NVARCHAR(100),EMPNAME NVARCHAR(300),CONTACTNO NVARCHAR(100),
	DEG_ID BIGINT,DESIGNATION NVARCHAR(300),STATEID BIGINT,STATE NVARCHAR(100),REPORTTOID NVARCHAR(100),REPORTTOUID NVARCHAR(100),REPORTTO NVARCHAR(300),RPTTODESG NVARCHAR(100),TOTALSHPCNT INT,
	UNIQUESHOPCNT INT,PERCENTOFCOVERAGE DECIMAL(18,2),VISITPERDAY INT)
	CREATE NONCLUSTERED INDEX IX1 ON #TMPPERFORMANCEMTD (EMPCODE)

	IF OBJECT_ID('tempdb..#TMPPERFORMANCEMTDDET') IS NOT NULL
		DROP TABLE #TMPPERFORMANCEMTDDET
	CREATE TABLE #TMPPERFORMANCEMTDDET(WORKDATE NVARCHAR(10),WORKDATEORDBY NVARCHAR(10),USERID BIGINT,EMPCODE NVARCHAR(100),EMPID NVARCHAR(100),EMPNAME NVARCHAR(300),CONTACTNO NVARCHAR(100),
	DEG_ID BIGINT,DESIGNATION NVARCHAR(300),STATEID BIGINT,STATE NVARCHAR(100),REPORTTOID NVARCHAR(100),REPORTTOUID NVARCHAR(100),REPORTTO NVARCHAR(300),RPTTODESG NVARCHAR(100),TOTALSHPCNT INT,
	UNIQUESHOPCNT INT,PERCENTOFCOVERAGE DECIMAL(18,2),VISITPERDAY INT)
	CREATE NONCLUSTERED INDEX IX1 ON #TMPPERFORMANCEMTDDET (EMPCODE)

	IF OBJECT_ID('tempdb..#TMPPERFORMANCEMTDSUM') IS NOT NULL
		DROP TABLE #TMPPERFORMANCEMTDSUM
	CREATE TABLE #TMPPERFORMANCEMTDSUM(USERID BIGINT,EMPCODE NVARCHAR(100),EMPID NVARCHAR(100),EMPNAME NVARCHAR(300),TOTVISITDAYS INT)
	CREATE NONCLUSTERED INDEX IX1 ON #TMPPERFORMANCEMTDSUM (EMPCODE)

	INSERT INTO #TMPPERFORMANCEMTDDET EXEC [PRC_FTSPERFORMANCESUMMARYMTD_FETCH] @MONTH,@YEARS,@STATEID,@DESIGNID,@EMPID,@USERID

	INSERT INTO #TMPPERFORMANCEMTDSUM(USERID,EMPCODE,EMPID,EMPNAME,TOTVISITDAYS)
	SELECT USERID,EMPCODE,EMPID,EMPNAME,SUM(VISITPERDAY) AS TOTVISITDAYS FROM #TMPPERFORMANCEMTDDET 
	GROUP BY USERID,EMPCODE,EMPID,EMPNAME
	ORDER BY EMPCODE

	SET @LOOPCOUNT=1
	IF @DAYCOUNT>0
		BEGIN
			WHILE @LOOPCOUNT<=@DAYCOUNT
				BEGIN
					SET @SqlStrTable=''
					SET @SqlStrTable='ALTER TABLE #EMPPERFORMANCEMTD ADD '
					SET @SqlStrTable+='['+RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']' + ' NVARCHAR(50) NULL,'
					SET @SqlStrTable+='[VC_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']'+ ' INT NULL ' 

					EXEC SP_EXECUTESQL @SqlStrTable					

					SET @TODATE=@COLUMN_DATE

					INSERT INTO #TMPPERFORMANCEMTD(WORKDATE,WORKDATEORDBY,USERID,EMPCODE,EMPID,EMPNAME,CONTACTNO,DEG_ID,DESIGNATION,STATEID,STATE,REPORTTOID,REPORTTOUID,REPORTTO,RPTTODESG,
					TOTALSHPCNT,UNIQUESHOPCNT,PERCENTOFCOVERAGE,VISITPERDAY)
					SELECT WORKDATE,WORKDATEORDBY,USERID,EMPCODE,EMPID,EMPNAME,CONTACTNO,DEG_ID,DESIGNATION,STATEID,STATE,REPORTTOID,REPORTTOUID,REPORTTO,RPTTODESG,TOTALSHPCNT,UNIQUESHOPCNT,
					PERCENTOFCOVERAGE,VISITPERDAY FROM #TMPPERFORMANCEMTDDET WHERE WORKDATEORDBY BETWEEN @COLUMN_DATE AND @TODATE

					IF (SELECT COUNT(0) FROM #EMPPERFORMANCEMTD A
						INNER JOIN #TMPPERFORMANCEMTD B ON A.EMPCODE=B.EMPCODE AND B.WORKDATEORDBY BETWEEN @COLUMN_DATE AND @TODATE)>0
						SET @FIRSTTIME=0
					ELSE
						SET @FIRSTTIME=1

					IF @FIRSTTIME=1
						BEGIN
							SET @SqlStrTable=''
							SET @SqlStrTable='INSERT INTO #EMPPERFORMANCEMTD(WORKDATE,WORKDATEORDBY,USERID,EMPCODE,EMPID,EMPNAME,CONTACTNO,DEG_ID,DESIGNATION,STATEID,STATE,REPORTTOID,REPORTTOUID,'
							SET @SqlStrTable+='REPORTTO,RPTTODESG,TOTALSHPCNT,UNIQUESHOPCNT,PERCENTOFCOVERAGE,'
							SET @SqlStrTable+='[VC_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + '] '
							SET @SqlStrTable+=') '
							SET @SqlStrTable+='SELECT WORKDATE,WORKDATEORDBY,USERID,EMPCODE,EMPID,EMPNAME,CONTACTNO,DEG_ID,DESIGNATION,STATEID,STATE,REPORTTOID,REPORTTOUID,REPORTTO,RPTTODESG,'
							SET @SqlStrTable+='TOTALSHPCNT,UNIQUESHOPCNT,PERCENTOFCOVERAGE,VISITPERDAY '
							SET @SqlStrTable+='FROM #TMPPERFORMANCEMTD '

							EXEC SP_EXECUTESQL @SqlStrTable

							SET @FIRSTTIME=0
						END
					ELSE IF @FIRSTTIME=0
						BEGIN
							SET @SqlStrTable=''
							SET @SqlStrTable='INSERT INTO #EMPPERFORMANCEMTD(WORKDATE,WORKDATEORDBY,USERID,EMPCODE,EMPID,EMPNAME,CONTACTNO,DEG_ID,DESIGNATION,STATEID,STATE,REPORTTOID,REPORTTOUID,'
							SET @SqlStrTable+='REPORTTO,RPTTODESG,TOTALSHPCNT,UNIQUESHOPCNT,PERCENTOFCOVERAGE,'
							SET @SqlStrTable+='[VC_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + '] '
							SET @SqlStrTable+=') '
							SET @SqlStrTable+='SELECT WORKDATE,WORKDATEORDBY,USERID,EMPCODE,EMPID,EMPNAME,CONTACTNO,DEG_ID,DESIGNATION,STATEID,STATE,REPORTTOID,REPORTTOUID,REPORTTO,RPTTODESG,'
							SET @SqlStrTable+='TOTALSHPCNT,UNIQUESHOPCNT,PERCENTOFCOVERAGE,VISITPERDAY '
							SET @SqlStrTable+='FROM #TMPPERFORMANCEMTD WHERE NOT EXISTS(SELECT EMPCODE FROM #EMPPERFORMANCEMTD A WHERE A.EMPCODE=#TMPPERFORMANCEMTD.EMPCODE) '
							
							EXEC SP_EXECUTESQL @sqlStrTable

							SET @SqlStrTable=''
							SET @SqlStrTable='UPDATE TEMP SET '
							SET @SqlStrTable+='TEMP.[VC_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) + ']=T.VISITPERDAY '
							SET @sqlStrTable+='FROM #EMPPERFORMANCEMTD TEMP '
							SET @sqlStrTable+='INNER JOIN #TMPPERFORMANCEMTD T ON TEMP.EMPCODE=T.EMPCODE '
						
							EXEC SP_EXECUTESQL @sqlStrTable
						END
						TRUNCATE TABLE #TMPPERFORMANCEMTD
						DELETE FROM #TMPPERFORMANCEMTDDET WHERE WORKDATEORDBY BETWEEN @COLUMN_DATE AND @TODATE

						--FOR REPORT HEADER
						SET @PARENTID=@SLHEADID+1
					
						INSERT INTO #TMPHEADINGPMTD(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
						SELECT @SLHEADID+1 AS HEADID,CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105) AS HEADNAME,RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,0 AS PARRENTID 

						INSERT INTO #TMPHEADINGPMTD(HEADID,HEADNAME,HEADSHRTNAME,PARRENTID) 
						SELECT @SLHEADID+2 AS HEADID,'Visit Count' AS HEADNAME,'VC_' +RTRIM(LTRIM(REPLACE(CONVERT(NVARCHAR(10),CAST(@COLUMN_DATE AS DATE),105),'-','_'))) AS HEADSHRTNAME,@PARENTID AS PARRENTID 

						SET @SLHEADID=@SLHEADID+2

						--FOR REPORT HEADER

						SET @COLUMN_DATE=CONVERT(NVARCHAR(10),(SELECT DATEADD(D, 1, @COLUMN_DATE)),120)
						SET @LOOPCOUNT=@LOOPCOUNT+1
				END
		END		

	UPDATE PERMTD SET PERMTD.TOTAL_VISIT=T.TOTVISITDAYS FROM #EMPPERFORMANCEMTD AS PERMTD 
	INNER JOIN #TMPPERFORMANCEMTDSUM T ON PERMTD.EMPCODE=T.EMPCODE

	SELECT * FROM #TMPHEADINGPMTD ORDER BY HEADID
	SELECT * FROM #EMPPERFORMANCEMTD ORDER BY EMPNAME

	DROP TABLE #EMPPERFORMANCEMTD
	DROP TABLE #TMPHEADINGPMTD
	DROP TABLE #TMPPERFORMANCEMTD
	DROP TABLE #TMPPERFORMANCEMTDDET
	DROP TABLE #TMPPERFORMANCEMTDSUM

	SET NOCOUNT OFF
END