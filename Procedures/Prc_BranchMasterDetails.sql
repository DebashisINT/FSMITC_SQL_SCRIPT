
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Prc_BranchMasterDetails]') AND type in (N'P', N'PC')) 
 BEGIN 
 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Prc_BranchMasterDetails] AS'  
 END 
 GO 
ALTER PROCEDURE [dbo].[Prc_BranchMasterDetails]
@action NVARCHAR(MAX)=NULL,
@firstname nvarchar(100)=null,
@shortname nvarchar(100)=null
-- Rev 2.0
,@branch_internalId nvarchar(10)=''
-- End of Rev 2.0
AS
/************************************************************************************************************************************************************
1.0		Priti		V2.0.39		22-03-2023 		0025745:While click the Add button of Branch Master, it is taking some time to load the page & take the input
2.0		Sanchita	V2.0.39		22-03-2023		While creating a new Branch, that branch should be mapped automatically for System Admin Employee/User
												Refer: 25744
*************************************************************************************************************************************************************/
Begin
	IF @action='BranchHead'
	BEGIN
		Select ISNULL(cnt_firstName, '') + ' ' + ISNULL(cnt_middleName, '') + ' ' + ISNULL(cnt_lastName, '') +'['+cnt_shortName+']' AS Name, cnt_internalId as Id     
		from tbl_master_employee, tbl_master_contact,tbl_trans_employeeCTC  
		WHERE  tbl_master_employee.emp_contactId = tbl_trans_employeeCTC.emp_cntId and tbl_trans_employeeCTC.emp_cntId = tbl_master_contact.cnt_internalId    
		and cnt_contactType='EM' 
		and (emp_dateofLeaving is null or emp_dateofLeaving='1/1/1900 12:00:00 AM' OR emp_dateofLeaving>getdate()) 
		and (cnt_firstName Like '%'+ @firstname +'%' or cnt_shortName like '%'+ @shortname +'%')
	End
	-- Rev 2.0
	IF @action='UpdateEmployeeBranchMap'
	BEGIN
		DECLARE @BRANCH_ID BIGINT=0, @USER_CONTACTID NVARCHAR(100)='', @CONTACT_CNTID BIGINT=0

		SELECT @BRANCH_ID = BRANCH_ID FROM TBL_MASTER_BRANCH WHERE branch_internalId=@branch_internalId
		SELECT @USER_CONTACTID = USER_CONTACTID FROM TBL_MASTER_USER WHERE USER_ID=378  -- ADMIN
		SELECT @CONTACT_CNTID = CNT_ID FROM tbl_master_contact WHERE cnt_internalId=@USER_CONTACTID  -- ADMIN

		IF(@USER_CONTACTID<>'' AND @BRANCH_ID>0)
		BEGIN
			INSERT INTO FTS_EmployeeBranchMap (EmployeeId, BranchId, CreatedBy, CreatedOn, Emp_Contactid)
			VALUES(@CONTACT_CNTID, @BRANCH_ID, 378, GETDATE(), @USER_CONTACTID)
		END
	END
	-- End of Rev 2.0
END
go