IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_Task]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_Task] AS' 
END
GO

ALTER PROCEDURE [dbo].[Proc_Task]
(
@Action varchar(500)=null,
@APP_ID varchar(500)=null,
@USER_ID varchar(500)=null,
@TASK_DATE varchar(500)=null,
@TASK varchar(500)=null,
@DETAILS varchar(500)=null,
@CURRENT_STATUS varchar(500)=null,
@STATUS_DATE varchar(500)=null,
@isCompleted varchar(500)=null,
@Event_Id NVARCHAR(100)=null
) --WITH ENCRYPTION
AS
/*****************************************************************************************************
1.0					TANMOY		06-11-2020		ADD EXTRA COLUMN Event_Id
2.0		v2.0.39		Debashis	15-05-2023		New Action has been added.Row: 828
*****************************************************************************************************/
BEGIN
	IF(@Action='Add')
		BEGIN
		   SET @CURRENT_STATUS =case when @isCompleted='true' then 'Completed' else 'Pending' END
		   SET @STATUS_DATE =GETDATE()
		   INSERT INTO FTS_TASK(APP_ID,USER_ID,TASK_DATE,TASK,DETAILS,CURRENT_STATUS,STATUS_DATE,Event_Id)
		   VALUES (@APP_ID,@USER_ID,@TASK_DATE,@TASK,@DETAILS,@CURRENT_STATUS,@STATUS_DATE,@Event_Id)
		END
	ELSE IF(@Action='Update')
		BEGIN
		   SET @CURRENT_STATUS =case when @isCompleted='true' then 'Completed' else 'Pending' END
		   SET @STATUS_DATE =GETDATE()
		   UPDATE FTS_TASK
		   set TASK_DATE=@TASK_DATE,TASK=@TASK,DETAILS=@DETAILS,CURRENT_STATUS=@CURRENT_STATUS,STATUS_DATE=@STATUS_DATE
		   ,Event_Id=@Event_Id
		   WHERE APP_ID=@APP_ID and USER_ID=@USER_ID
		END
	ELSE IF(@Action='delete')
		BEGIN
		   delete from FTS_TASK		   
		   WHERE APP_ID=@APP_ID and USER_ID=@USER_ID
		END
	ELSE IF(@Action='UpdateStatus')
		BEGIN
		   SET @CURRENT_STATUS =case when @isCompleted='true' then 'Completed' else 'Pending' END
		   SET @STATUS_DATE =GETDATE()
		   UPDATE FTS_TASK	SET
		   CURRENT_STATUS=@CURRENT_STATUS,STATUS_DATE=@STATUS_DATE
		   WHERE APP_ID=@APP_ID and USER_ID=@USER_ID
		END
	ELSE IF(@Action='List')
		BEGIN		   
		   SELECT convert(varchar(15),APP_ID) id,
			TASK task,
			DETAILS details,
			case when CURRENT_STATUS ='Completed' then 'true' else 'false' end isCompleted,
			CONVERT(VARCHAR(10),TASK_DATE,120) date 
			,Event_Id
			FROM FTS_TASK WHERE USER_ID=@USER_ID AND CAST(TASK_DATE AS DATE)=CAST(@TASK_DATE AS DATE)
		END
	--Rev 2.0
	ELSE IF(@Action='TaskPriorityList')
		BEGIN
			SELECT TASKPRIORITY_ID AS task_priority_id,TASKPRIORITY_FROM AS task_priority_name FROM MASTER_TASKPRIORITY
		END
	--End of Rev 2.0
END