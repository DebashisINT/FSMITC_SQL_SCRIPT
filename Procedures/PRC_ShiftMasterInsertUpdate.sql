IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_ShiftMasterInsertUpdate]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_ShiftMasterInsertUpdate] AS' 
END
GO

ALTER Procedure [dbo].[PRC_ShiftMasterInsertUpdate]
(
	@UserID nvarchar(10)=null,
	@ShiftId BIGINT=null,
	@Action nvarchar(100)=null,
	@ShiftName NVARCHAR(100)=NULL,
	--Rev 4.0
	--@PARAMTABLE [dbo].[udt_ShiftMasterDetails]	ReadONLY,
	@PARAMTABLE [dbo].[udt_ShiftMasterDetails_New]	ReadONLY,
	--End Rev 4.0
	@ReturnMessage nvarchar(500) Output,
	@ReturnCode int Output
)   
AS
BEGIN TRY

/************************************************************************************************
1.0		Tanmoy		14-05-2020	       Enhancements in Shift Module
2.0		Tanmoy		19-05-2020		Multi day shift save 
3.0		Tanmoy		20-05-2020		List show only HH:mm format 
4.0		v2.0.32		Pratik		12-08-2022		Add columns FullDayWorkingHour,HalfDayWorkingHour,AbsentWorkingHour
************************************************************************************************/ 
DECLARE @SCOPEIDENTITY BIGINT
Declare @isInsert INT=0,@grc int=0

BEGIN TRANSACTION

	If(@Action='Add')
	BEGIN
		 IF EXISTS(SELECT 1 FROM tbl_EmpWorkingHours where [Name]=@ShiftName)
		BEGIN
				Set @ReturnCode='-1'
				Set @ReturnMessage='Shift name already exist.'
				Set @isInsert=1
				return
		END
		--IF (@ShiftEndTime<@ShiftStartTime)
		--BEGIN
		--		Set @ReturnCode='-1'
		--		Set @ReturnMessage='Shift end time should be greater than shift start time.'
		--		Set @isInsert=1
		--		return
		--END
		ELSE IF(@isInsert)=0
		BEGIN
			
			INSERT INTO tbl_EmpWorkingHours ([Name]) VALUES (@ShiftName)

			SET @SCOPEIDENTITY=SCOPE_IDENTITY();
			--Rev 4.0
			--INSERT INTO tbl_EmpWorkingHoursDetails(hourId,DayWeek,BeginTime,EndTime,BreakTime,Grace,ALT_BeginTime,ALT_EndTime,ALT_BreakTime,ALT_Grace)
			--SELECT @SCOPEIDENTITY,ID,InTime,OutTime,BreakTime,grace,AltInTime,AltOutTime,AltBreakTime,Altgrace FROM @PARAMTABLE where ISNULL(ShiftDay,'')<>''
			INSERT INTO tbl_EmpWorkingHoursDetails(hourId,DayWeek,BeginTime,EndTime,BreakTime,Grace,ALT_BeginTime,ALT_EndTime,ALT_BreakTime,ALT_Grace,FullDayWorkingHour,HalfDayWorkingHour,AbsentWorkingHour)
			SELECT @SCOPEIDENTITY,ID,InTime,OutTime,BreakTime,grace,AltInTime,AltOutTime,AltBreakTime,Altgrace,FullDayWorkingHour,HalfDayWorkingHour,AbsentWorkingHour FROM @PARAMTABLE where ISNULL(ShiftDay,'')<>''
			--End of Rev 4.0
								   
			SET @ReturnCode='1'	   
			SET @ReturnMessage='Success'
		END						  
	End							  
								  
	ELSE IF(@Action='Edit')		  
	BEGIN						   
		--IF (@ShiftEndTime<@ShiftStartTime)
		--	BEGIN
		--		SET @ReturnCode='-1'
		--		SET @ReturnMessage='Shift end time should be greater than shift start time.'
		--	END
		--ELSE
			BEGIN
				DELETE FROM tbl_EmpWorkingHoursDetails WHERE hourId=@ShiftId
				--Rev 4.0
				--INSERT INTO tbl_EmpWorkingHoursDetails(hourId,DayWeek,BeginTime,EndTime,BreakTime,Grace,ALT_BeginTime,ALT_EndTime,ALT_BreakTime,ALT_Grace)
				--SELECT @ShiftId,ID,InTime,OutTime,BreakTime,grace,AltInTime,AltOutTime,AltBreakTime,Altgrace FROM @PARAMTABLE where ISNULL(ShiftDay,'')<>''
				INSERT INTO tbl_EmpWorkingHoursDetails(hourId,DayWeek,BeginTime,EndTime,BreakTime,Grace,ALT_BeginTime,ALT_EndTime,ALT_BreakTime,ALT_Grace,FullDayWorkingHour,HalfDayWorkingHour,AbsentWorkingHour)
				SELECT @ShiftId,ID,InTime,OutTime,BreakTime,grace,AltInTime,AltOutTime,AltBreakTime,Altgrace,FullDayWorkingHour,HalfDayWorkingHour,AbsentWorkingHour FROM @PARAMTABLE where ISNULL(ShiftDay,'')<>''
				--End of Rev 4.0
				SET @ReturnCode='1'
				SET @ReturnMessage='Success'
			END	
	END

	Else if(@Action='Delete')
	BEGIN

		IF(select count(1) from tbl_trans_employeeCTC where emp_workinghours=@ShiftId) > 0
		BEGIN
			
			Set @ReturnMessage='Shift is linked with employee connot delete.'
			Set @ReturnCode='-1'

		END
		ELSE
		BEGIN
			
			delete from tbl_EmpWorkingHoursDetails where hourId=@ShiftId
			DELETE FROM tbl_EmpWorkingHours WHERE Id=@ShiftId

			Set @ReturnMessage='Success'
			Set @ReturnCode='1'
		END
		
	END

	Else if(@Action='GetShiftById')
	BEGIN
		--select dtls.Id AS ShiftID,dtls.hourId,dtls.DayWeek AS ShiftDay,
		--dtls.BeginTime AS ShiftStartTime,dtls.EndTime AS ShiftEndTime,
		--dtls.BreakTime AS ShiftBreak,'00:'+convert(nvarchar(2),dtls.Grace)+':00' as Grace,HEAD.Name AS ShiftName
		--from tbl_EmpWorkingHoursDetails dtls
		--INNER JOIN tbl_EmpWorkingHours HEAD ON HEAD.ID=dtls.HOURID
		--where dtls.Id=@ShiftId

		

		SELECT * FROM tbl_EmpWorkingHours WHERE ID=@ShiftId

		SELECT hourId,DayWeek,Convert(varchar(5), BeginTime, 108) as BeginTime,Convert(varchar(5), EndTime, 108) as EndTime,
		Convert(varchar(5), BreakTime, 108) as BreakTime,Grace,Convert(varchar(5), ALT_BeginTime, 108) as ALT_BeginTime,
		Convert(varchar(5), ALT_EndTime, 108) as ALT_EndTime,Convert(varchar(5), ALT_BreakTime, 108) as ALT_BreakTime,ALT_Grace,
		--Rev 4.0
		Convert(varchar(8), FullDayWorkingHour, 108) as FullDayWorkingHour,Convert(varchar(8), HalfDayWorkingHour, 108) as HalfDayWorkingHour,Convert(varchar(8), AbsentWorkingHour, 108) as AbsentWorkingHour,
		--End of Rev 4.0
		CASE WHEN DayWeek=1 THEN 'Sunday' WHEN DayWeek=2 THEN 'Monday' WHEN DayWeek=3 THEN 'Tuesday'
		WHEN DayWeek=4 THEN 'Wednesday' WHEN DayWeek=5 THEN 'Thursday' WHEN DayWeek=6 THEN 'Friday'
		WHEN DayWeek=7 THEN 'Saturday' END AS ShiftDay FROM tbl_EmpWorkingHoursDetails
		WHERE hourId=@ShiftId

		Set @ReturnMessage='Success'
		Set @ReturnCode='1'

	END
	Else if(@Action='GetLeavingLateShiftByID')
	BEGIN

		
		Set @ReturnMessage='Success'
		Set @ReturnCode='1'

	END
	Else if(@Action='GetRotationalShiftShiftByID')
	BEGIN

		
		Set @ReturnMessage='Success'
		Set @ReturnCode='1'

	END

COMMIT TRANSACTION
END TRY
	
BEGIN CATCH
ROLLBACK TRANSACTION
Set @ReturnCode='-10'
	Set @ReturnMessage='Please try again later'

	SELECT @ReturnCode 'ReturnValue', @ReturnMessage  'ReturnMessage'

        DECLARE @ErrorMessage NVARCHAR(4000) ;
        DECLARE @ErrorSeverity INT ;
        DECLARE @ErrorState INT ;
        SELECT  @ErrorMessage = ERROR_MESSAGE() ,
                @ErrorSeverity = ERROR_SEVERITY() ,
                @ErrorState = ERROR_STATE() ;
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState) ;
END CATCH ;
RETURN ;
