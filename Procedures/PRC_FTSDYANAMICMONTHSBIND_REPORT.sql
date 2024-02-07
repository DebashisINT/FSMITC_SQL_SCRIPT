--EXEC PRC_FTSDYANAMICMONTHSBIND_REPORT
-- EXEC PRC_FTSDYANAMICMONTHSBIND_REPORT @YEARS='2022'

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSDYANAMICMONTHSBIND_REPORT]') AND TYPE in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSDYANAMICMONTHSBIND_REPORT] AS' 
END
GO

ALTER PROCEDURE [dbo].[PRC_FTSDYANAMICMONTHSBIND_REPORT]
-- Rev 1.0
(
	@YEARS NVARCHAR(20) = ''
)
-- End of Rev 1.0
WITH ENCRYPTION
AS
/****************************************************************************************************************************************************************************
Written by : Debashis Talukder on 28/10/2022
Module	   : Dynamic Months Parameter Bind.

Rev 1.0		Sanchita	V2.0.39		16/03/2023		All months are not showing for Previous year while selecting parameter in Dealer/Distributor wise Sales report
													Refer: 25732
****************************************************************************************************************************************************************************/
BEGIN
	SET NOCOUNT ON
		IF OBJECT_ID('tempdb..#TMPMONTHNAME') IS NOT NULL
			DROP TABLE #TMPMONTHNAME
		CREATE TABLE #TMPMONTHNAME(ID INT,MID NVARCHAR(3),MONTHNAMEOFYEAR NVARCHAR(50))
		DECLARE @CURRENTNO INT,@TOTALMONTHS INT,@CURRENTMONTHNAME NVARCHAR(50),@TOTALDAYSOFMONTH INT,@CURRENTDAYOFMONTH INT
		-- Rev 1.0
		IF(@YEARS = YEAR(GETDATE()))
		BEGIN
		-- End of Rev 1.0
		
			SET @CURRENTNO=1
			SET @TOTALMONTHS=(SELECT DATEDIFF(MONTH,DATEFROMPARTS(YEAR(GETDATE()), 1, 1),GETDATE())+1)
			SET @CURRENTMONTHNAME=(SELECT DATENAME(MONTH,GETDATE()))
			SET @TOTALDAYSOFMONTH=(SELECT DATEDIFF(DAY, GETDATE(), DATEADD(MONTH, 1, GETDATE())))
			SET @CURRENTDAYOFMONTH=(SELECT DAY(GETDATE()))
			WHILE @CURRENTNO<=@TOTALMONTHS
				BEGIN
					INSERT INTO #TMPMONTHNAME(ID,MID,MONTHNAMEOFYEAR)
					SELECT @CURRENTNO,
					CASE WHEN @CURRENTNO=1 THEN 'JAN' WHEN @CURRENTNO=2 THEN 'FEB' WHEN @CURRENTNO=3 THEN 'MAR' WHEN @CURRENTNO=4 THEN 'APR'WHEN @CURRENTNO=5 THEN 'MAY' WHEN @CURRENTNO=6 THEN 'JUN' 
					WHEN @CURRENTNO=7 THEN 'JUL' WHEN @CURRENTNO=8 THEN 'AUG' WHEN @CURRENTNO=9 THEN 'SEP' WHEN @CURRENTNO=10 THEN 'OCT' WHEN @CURRENTNO=11 THEN 'NOV' WHEN @CURRENTNO=12 THEN 'DEC' END,
					CASE WHEN @CURRENTNO=1 THEN 'January' WHEN @CURRENTNO=2 THEN 'February' WHEN @CURRENTNO=3 THEN 'March' WHEN @CURRENTNO=4 THEN 'April'
					WHEN @CURRENTNO=5 THEN 'May' WHEN @CURRENTNO=6 THEN 'June' WHEN @CURRENTNO=7 THEN 'July' WHEN @CURRENTNO=8 THEN 'August' WHEN @CURRENTNO=9 THEN 'September'
					WHEN @CURRENTNO=10 THEN 'October' WHEN @CURRENTNO=11 THEN 'November' WHEN @CURRENTNO=12 THEN 'December' END
					SET @CURRENTNO=@CURRENTNO+1
				END

			IF @TOTALDAYSOFMONTH>@CURRENTDAYOFMONTH
				DELETE FROM #TMPMONTHNAME WHERE MONTHNAMEOFYEAR=@CURRENTMONTHNAME
		-- Rev 1.0
		END
		else IF(@YEARS < YEAR(GETDATE()))
		BEGIN
			SET @CURRENTNO=1
			WHILE @CURRENTNO<=12
				BEGIN
					INSERT INTO #TMPMONTHNAME(ID,MID,MONTHNAMEOFYEAR)
					SELECT @CURRENTNO,
					CASE WHEN @CURRENTNO=1 THEN 'JAN' WHEN @CURRENTNO=2 THEN 'FEB' WHEN @CURRENTNO=3 THEN 'MAR' WHEN @CURRENTNO=4 THEN 'APR'WHEN @CURRENTNO=5 THEN 'MAY' WHEN @CURRENTNO=6 THEN 'JUN' 
					WHEN @CURRENTNO=7 THEN 'JUL' WHEN @CURRENTNO=8 THEN 'AUG' WHEN @CURRENTNO=9 THEN 'SEP' WHEN @CURRENTNO=10 THEN 'OCT' WHEN @CURRENTNO=11 THEN 'NOV' WHEN @CURRENTNO=12 THEN 'DEC' END,
					CASE WHEN @CURRENTNO=1 THEN 'January' WHEN @CURRENTNO=2 THEN 'February' WHEN @CURRENTNO=3 THEN 'March' WHEN @CURRENTNO=4 THEN 'April'
					WHEN @CURRENTNO=5 THEN 'May' WHEN @CURRENTNO=6 THEN 'June' WHEN @CURRENTNO=7 THEN 'July' WHEN @CURRENTNO=8 THEN 'August' WHEN @CURRENTNO=9 THEN 'September'
					WHEN @CURRENTNO=10 THEN 'October' WHEN @CURRENTNO=11 THEN 'November' WHEN @CURRENTNO=12 THEN 'December' END
					SET @CURRENTNO=@CURRENTNO+1
				END
		END
		-- End of Rev 1.0

		SELECT MID,MONTHNAMEOFYEAR FROM #TMPMONTHNAME

	SET NOCOUNT OFF
END