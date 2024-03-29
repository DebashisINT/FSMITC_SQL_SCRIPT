IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTS_Area_Userwise]') AND type in (N'P', N'PC'))
BEGIN
	EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTS_Area_Userwise] AS' 
END
GO

---EXEC  [PRC_FTS_Area_Userwise] @Action='GetAreaByBranch',@BranchId='119'
ALTER Proc [dbo].[PRC_FTS_Area_Userwise]
(
@CITYID nvarchar(MAX)=NULL,
@Action nvarchar(100)=NULL,
@BranchId nvarchar(MAX)=NULL
)  
As
/***********************************************************************************************************************
1.0		Priti	    V2.0.40		20-05-2023		0026145: Modification in the ‘Configure Travelling Allowance’ page.
***************************************************************************************************************************/
Begin
	DECLARE @Strsql NVARCHAR(MAX), @sqlStrTable NVARCHAR(MAX)
	CREATE TABLE #CITYID_LIST (City_Id INT)
		CREATE NONCLUSTERED INDEX IX1 ON #CITYID_LIST (City_Id ASC)

	if(isnull(@Action,'')='')
	BEGIN
		select cast(area_id as varchar(50)) as AreaID,area_name as AreaName from tbl_master_area
		order by area_name
	END

	ELSE IF (isnull(@Action,'')='AreabyCity')
	BEGIN
		

		IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#CITYID_LIST') AND TYPE IN (N'U'))
		DROP TABLE #CITYID_LIST
		--CREATE TABLE #CITYID_LIST (City_Id INT)
		--CREATE NONCLUSTERED INDEX IX1 ON #CITYID_LIST (City_Id ASC)
		IF @CITYID <> ''
		BEGIN
			SET @CITYID=REPLACE(@CITYID,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #CITYID_LIST SELECT City_Id from tbl_master_city where city_id in('+@CITYID+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END


		SET @Strsql='select  cast(area_id as varchar(50)) as AreaID,area_name as AreaName from tbl_master_area'
		if(isnull(@CITYID,'')<>'')
		BEGIN
		SET  @Strsql +='  WHERE EXISTS (select City_Id from #CITYID_LIST CTY where CTY.City_Id=tbl_master_area.city_id)'
		END

		SET  @Strsql +='  order by area_name'

		--select @Strsql
		EXEC SP_EXECUTESQL @Strsql

	END
	--Rev 1.0
	if(isnull(@Action,'')='GetAreaByBranch')
	BEGIN
		

		IF EXISTS (SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'#CITYID_LIST') AND TYPE IN (N'U'))
		DROP TABLE #CITYID_LIST

		

		IF @BranchId <> ''
		BEGIN
			SET @BranchId=REPLACE(@BranchId,'''','')
			SET @sqlStrTable=''
			SET @sqlStrTable=' INSERT INTO #CITYID_LIST SELECT branch_city from TBL_MASTER_BRANCH where branch_id in('+@BranchId+')'
			EXEC SP_EXECUTESQL @sqlStrTable
		END

		if(isnull(@BranchId,'')<>'')
		BEGIN
			SET @Strsql='select  cast(area_id as varchar(50)) as AreaID,area_name as AreaName from tbl_master_area'		
			SET  @Strsql +='  WHERE EXISTS (select City_Id from #CITYID_LIST CTY where CTY.City_Id=tbl_master_area.city_id)'
			SET  @Strsql +='  order by area_name'
		END
		Else
		Begin
			 select '' as AreaID,'' as AreaName 
		End

		

		--select @Strsql
		EXEC SP_EXECUTESQL @Strsql
	END
	--Rev 1.0 End
END
