IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PRC_FTSTblMasterUser_Audit]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PRC_FTSTblMasterUser_Audit] AS' 
END
GO

-- EXEC PRC_FTSTblMasterUser_Audit @UserId=378, @Action='I',@DOC_ID='54808'

--select * from Tbl_Master_User_Audit
--select * from FTS_UserPartyCreateAccess_Audit
--select * from Employee_ChannelMap_Audit
--select * from FTS_EMPSTATEMAPPING_Audit
--select * from FTS_EmployeeBranchMap_Audit

ALTER PROCEDURE [dbo].[PRC_FTSTblMasterUser_Audit]
	@TABLE_NAME NVARCHAR(200)=NULL,
	@USERID NVARCHAR(20)=NULL,
	@ACTION NVARCHAR(10)=NULL,
	@DOC_ID NVARCHAR(50)=NULL
 
AS
/****************************************************************************************************************************
Wrtiien by Sanchita	for v2.0.39	on	13-02-2023		Need Audit functionality in User Master. Refer: 25648
****************************************************************************************************************************/
BEGIN

	DECLARE @LOGGEDDATE NVARCHAR(50)=CONVERT(VARCHAR(32),GETDATE(),121)

	DECLARE @SQLSTAT NVARCHAR(max)=''
	
	IF (@TABLE_NAME='TBL_MASTER_USER')
		BEGIN
			--HEADER
			SET @SQLSTAT = '
			INSERT INTO DBO.[Tbl_Master_User_Audit] (user_id, user_name, user_loginId, user_password, user_contactId, user_branchId,
				user_group, user_lastsegement, user_LastFinYear, user_LastStno, user_LastStType, user_LastBatch, user_status,
				user_leavedate, user_TimeForTickerRefrsh, user_type, CreateDate, CreateUser, LastModifyDate, LastModifyUser,
				last_login_date, user_superUser, user_lastIP, user_EntryProfile, user_activity, user_AllowAccessIP, user_inactive,
				Mac_Address, DEviceType, SessionToken, user_imei_no, user_maclock, Gps_Accuracy, Custom_Configuration,
				HierarchywiseTargetSettings, autoRevisitDistanceInMeter, autoRevisitTimeInMinutes, IsAutoRevisitEnable,
				willLeaveApprovalEnable, IsShowPlanDetails, IsMoreDetailsMandatory, IsShowMoreDetailsMandatory, isMeetingAvailable,
				isRateNotEditable, IsShowTeamDetails, IsAllowPJPUpdateForTeam, willReportShow, isFingerPrintMandatoryForAttendance,
				isFingerPrintMandatoryForVisit, isSelfieMandatoryForAttendance, willTimesheetShow, isAttendanceFeatureOnly,
				isAttendanceReportShow, isPerformanceReportShow, isVisitReportShow, isOrderShow, isVisitShow, iscollectioninMenuShow,
				isShopAddEditAvailable, isEntityCodeVisible, isAreaMandatoryInPartyCreation, isShowPartyInAreaWiseTeam,
				isChangePasswordAllowed, isHomeRestrictAttendance, LateVisitSMS, isQuotationShow, IsStateMandatoryinReport, 
				homeLocDistance, shopLocAccuracy, isQuotationPopupShow, isOrderReplacedWithTeam,
				isMultipleAttendanceSelection, isDDShowForMeeting, isDDMandatoryForMeeting, isOfflineTeam, isAllTeamAvailable,
				isNextVisitDateMandatory, isRecordAudioEnable, isAchievementEnable, isTarVsAchvEnable, isShowCurrentLocNotifiaction,
				isUpdateWorkTypeEnable,  isLeaveEnable, isOrderMailVisible, isShopEditEnable, isTaskEnable, isAppInfoEnable,
				appInfoMins, willActivityShow, isDocumentRepoShow, willDynamicShow, isChatBotShow, isAttendanceBotShow,
				isVisitBotShow, isInstrumentCompulsory, isBankCompulsory, isComplementaryUser, min_accuracy, min_distance,
				max_distance, max_accuracy, isVisitPlanShow, isVisitPlanMandatory, isAttendanceDistanceShow, willTimelineWithFixedLocationShow,
				isShowOrderRemarks, isShowOrderSignature, isShowSmsForParty, isShowTimeline, willScanVisitingCard, isCreateQrCode,
				isScanQrForRevisit, isShowLogoutReason, willShowHomeLocReason, willShowShopVisitReason, minVisitDurationSpentTime,
				willShowPartyStatus, willShowEntityTypeforShop, isShowRetailerEntity, isShowDealerForDD, isShowBeatGroup,
				isShowShopBeatWise, isShowBankDetailsForShop, isShowOTPVerificationPopup, locationTrackInterval, isShowMicroLearing,
				homeLocReasonCheckMins, currentLocationNotificationMins, isMultipleVisitEnable, isShowVisitRemarks, isShowNearbyCustomer, 
				isServiceFeatureEnable, isPatientDetailsShowInOrder, isPatientDetailsShowInCollection, isAttachmentMandatory, isShopImageMandatory, 
				isLogShareinLogin, IsCompetitorenable, IsOrderStatusRequired, IsCurrentStockEnable, IsCurrentStockApplicableforAll, 
				IscompetitorStockRequired, IsCompetitorStockforParty, ShowFaceRegInMenu, IsFaceDetection, FaceImage, isFaceRegistered, 
				IsUserwiseDistributer, IsPhotoDeleteShow, IsAllDataInPortalwithHeirarchy, IsFaceDetectionWithCaptcha, IsDocRepoFromPortal, 
				IsDocRepShareDownloadAllowed, IsScreenRecorderEnable, Registration_Datetime, IsShowMenuAddAttendance, IsShowMenuAttendance, 
				IsShowMenuShops, IsShowMenuOutstandingDetailsPPDD, IsShowMenuStockDetailsPPDD, IsShowMenuTA, IsShowMenuMISReport, 
				IsShowMenuReimbursement, IsShowMenuAchievement, IsShowMenuMapView, IsShowMenuShareLocation, IsShowMenuHomeLocation, 
				IsShowMenuWeatherDetails, IsShowMenuChat, IsShowMenuScanQRCode, IsShowMenuPermissionInfo, IsShowMenuAnyDesk, 
				IsShowPartyOnAppDashboard, IsShowAttendanceOnAppDashboard, IsShowTotalVisitsOnAppDashboard, IsShowVisitDurationOnAppDashboard, 
				IsLeaveGPSTrack, IsShowActivitiesInTeam, IsShowLeaveInAttendance, IsShowDayStart, IsshowDayStartSelfie, IsShowDayEnd, 
				IsshowDayEndSelfie, IsShowMarkDistVisitOnDshbrd, IsActivateNewOrderScreenwithSize, IsFromPortal, RevisitRemarksMandatory, 
				GPSAlert, GPSAlertwithSound, IsTeamAttendance, FaceDetectionAccuracyUpper, FaceDetectionAccuracyLower, DistributorGPSAccuracy, 
				BatterySetting, PowerSaverSetting, AadharImage, isAadharRegistered, AadharRegistration_Datetime, Show_App_Logout_Notification, 
				IsShowTypeInRegistration, FaceRegTypeID, IsReturnEnableforParty, FaceRegistrationFrontCamera, MRPInOrder, 
				IsShowMyDetails, IslandlineforCustomer, IsprojectforCustomer, IsAttendVisitShowInDashboard, IsShowManualPhotoRegnInApp, 
				Leaveapprovalfromsupervisorinteam, Leaveapprovalfromsupervisor, IsTeamAttenWithoutPhoto, IsIMEICheck, 
				IsRestrictNearbyGeofence, IsAlternateNoForCustomer, IsWhatsappNoForCustomer, MarkAttendNotification, UpdateUserName, 
				IsNewQuotationNumberManual, ShowQuantityNewQuotation, ShowAmountNewQuotation, IsNewQuotationfeatureOn, IsAllowClickForPhotoRegister, 
				IsAllowClickForVisit, IsAllowClickForVisitForSpecificUser, HierarchywiseLoginInPortal, ShowUserwiseLeadMenu, 
				UpdateOtherID, UpdateUserID, AllowProfileUpdate, GeofencingRelaxationinMeter, LogoutWithLogFile, InAppUpdateApplicable, 
				IsFeedbackHistoryActivated, IsAutoLeadActivityDateTime, ShowAutoRevisitInDashboard, ShowAutoRevisitInAppMenu, IsShowNearByTeam, 
				IsShowRevisitRemarksPopup, IsAllowShopStatusUpdate, ShowTotalVisitAppMenu, OfflineShopAccuracy, AutoRevisitTimeInSeconds, 
				PartyUpdateAddrMandatory, IsHierarchyforHorizontalPerformanceReport, IsCollectionOrderWise, ShowCollectionOnlywithInvoiceDetails, 
				ShowCollectionAlert, ShowZeroCollectioninAlert, IsPendingCollectionRequiredUnderTeam, IsShowRepeatOrderinNotification, 
				IsShowRepeatOrdersNotificationinTeam, AutoDDSelect, ShowPurposeInShopVisit, WillRoomDBShareinLogin, GPSAlertwithVibration, 
				ShopScreenAftVisitRevisit, IsFeedbackAvailableInShop, IsAllowBreakageTracking, IsAllowBreakageTrackingunderTeam, 
				IsRateEnabledforNewOrderScreenwithSize, IgnoreNumberCheckwhileShopCreation, Showdistributorwisepartyorderreport, 
				IsShowHomeLocationMap, IsBeatRouteReportAvailableinTeam, ShowAttednaceClearmenu, CommonAINotification, IsFaceRecognitionOnEyeblink, 
				GPSNetworkIntervalMins, IsShowTypeInRegistrationForSpecificUser, IsFeedbackMandatoryforNewShop, IsLoginSelfieRequired, 
				IsJointVisitEnable, IsShowAllEmployeeforJointVisit, IsMultipleContactEnableforShop, IsContactPersonSelectionRequiredinRevisit, 
				IsContactPersonRequiredinQuotation, IsShowBeatInMenu, LoggedOn, LoggedBy, Action) 


			SELECT user_id, user_name, user_loginId, user_password, user_contactId, user_branchId,
				user_group, user_lastsegement, user_LastFinYear, user_LastStno, user_LastStType, user_LastBatch, user_status,
				user_leavedate, user_TimeForTickerRefrsh, user_type, CreateDate, CreateUser, LastModifyDate, LastModifyUser,
				last_login_date, user_superUser, user_lastIP, user_EntryProfile, user_activity, user_AllowAccessIP, user_inactive,
				Mac_Address, DEviceType, SessionToken, user_imei_no, user_maclock, Gps_Accuracy, Custom_Configuration,
				HierarchywiseTargetSettings, autoRevisitDistanceInMeter, autoRevisitTimeInMinutes, IsAutoRevisitEnable,
				willLeaveApprovalEnable, IsShowPlanDetails, IsMoreDetailsMandatory, IsShowMoreDetailsMandatory, isMeetingAvailable,
				isRateNotEditable, IsShowTeamDetails, IsAllowPJPUpdateForTeam, willReportShow, isFingerPrintMandatoryForAttendance,
				isFingerPrintMandatoryForVisit, isSelfieMandatoryForAttendance, willTimesheetShow, isAttendanceFeatureOnly,
				isAttendanceReportShow, isPerformanceReportShow, isVisitReportShow, isOrderShow, isVisitShow, iscollectioninMenuShow,
				isShopAddEditAvailable, isEntityCodeVisible, isAreaMandatoryInPartyCreation, isShowPartyInAreaWiseTeam,
				isChangePasswordAllowed, isHomeRestrictAttendance, LateVisitSMS, isQuotationShow, IsStateMandatoryinReport, 
				homeLocDistance, shopLocAccuracy, isQuotationPopupShow, isOrderReplacedWithTeam,
				isMultipleAttendanceSelection, isDDShowForMeeting, isDDMandatoryForMeeting, isOfflineTeam, isAllTeamAvailable,
				isNextVisitDateMandatory, isRecordAudioEnable, isAchievementEnable, isTarVsAchvEnable, isShowCurrentLocNotifiaction,
				isUpdateWorkTypeEnable,  isLeaveEnable, isOrderMailVisible, isShopEditEnable, isTaskEnable, isAppInfoEnable,
				appInfoMins, willActivityShow, isDocumentRepoShow, willDynamicShow, isChatBotShow, isAttendanceBotShow,
				isVisitBotShow, isInstrumentCompulsory, isBankCompulsory, isComplementaryUser, min_accuracy, min_distance,
				max_distance, max_accuracy, isVisitPlanShow, isVisitPlanMandatory, isAttendanceDistanceShow, willTimelineWithFixedLocationShow,
				isShowOrderRemarks, isShowOrderSignature, isShowSmsForParty, isShowTimeline, willScanVisitingCard, isCreateQrCode,
				isScanQrForRevisit, isShowLogoutReason, willShowHomeLocReason, willShowShopVisitReason, minVisitDurationSpentTime,
				willShowPartyStatus, willShowEntityTypeforShop, isShowRetailerEntity, isShowDealerForDD, isShowBeatGroup,
				isShowShopBeatWise, isShowBankDetailsForShop, isShowOTPVerificationPopup, locationTrackInterval, isShowMicroLearing,
				homeLocReasonCheckMins, currentLocationNotificationMins, isMultipleVisitEnable, isShowVisitRemarks, isShowNearbyCustomer, 
				isServiceFeatureEnable, isPatientDetailsShowInOrder, isPatientDetailsShowInCollection, isAttachmentMandatory, isShopImageMandatory, 
				isLogShareinLogin, IsCompetitorenable, IsOrderStatusRequired, IsCurrentStockEnable, IsCurrentStockApplicableforAll, 
				IscompetitorStockRequired, IsCompetitorStockforParty, ShowFaceRegInMenu, IsFaceDetection, FaceImage, isFaceRegistered, 
				IsUserwiseDistributer, IsPhotoDeleteShow, IsAllDataInPortalwithHeirarchy, IsFaceDetectionWithCaptcha, IsDocRepoFromPortal, 
				IsDocRepShareDownloadAllowed, IsScreenRecorderEnable, Registration_Datetime, IsShowMenuAddAttendance, IsShowMenuAttendance, 
				IsShowMenuShops, IsShowMenuOutstandingDetailsPPDD, IsShowMenuStockDetailsPPDD, IsShowMenuTA, IsShowMenuMISReport, 
				IsShowMenuReimbursement, IsShowMenuAchievement, IsShowMenuMapView, IsShowMenuShareLocation, IsShowMenuHomeLocation, 
				IsShowMenuWeatherDetails, IsShowMenuChat, IsShowMenuScanQRCode, IsShowMenuPermissionInfo, IsShowMenuAnyDesk, 
				IsShowPartyOnAppDashboard, IsShowAttendanceOnAppDashboard, IsShowTotalVisitsOnAppDashboard, IsShowVisitDurationOnAppDashboard, 
				IsLeaveGPSTrack, IsShowActivitiesInTeam, IsShowLeaveInAttendance, IsShowDayStart, IsshowDayStartSelfie, IsShowDayEnd, 
				IsshowDayEndSelfie, IsShowMarkDistVisitOnDshbrd, IsActivateNewOrderScreenwithSize, IsFromPortal, RevisitRemarksMandatory, 
				GPSAlert, GPSAlertwithSound, IsTeamAttendance, FaceDetectionAccuracyUpper, FaceDetectionAccuracyLower, DistributorGPSAccuracy, 
				BatterySetting, PowerSaverSetting, AadharImage, isAadharRegistered, AadharRegistration_Datetime, Show_App_Logout_Notification, 
				IsShowTypeInRegistration, FaceRegTypeID, IsReturnEnableforParty, FaceRegistrationFrontCamera, MRPInOrder, 
				IsShowMyDetails, IslandlineforCustomer, IsprojectforCustomer, IsAttendVisitShowInDashboard, IsShowManualPhotoRegnInApp, 
				Leaveapprovalfromsupervisorinteam, Leaveapprovalfromsupervisor, IsTeamAttenWithoutPhoto, IsIMEICheck, 
				IsRestrictNearbyGeofence, IsAlternateNoForCustomer, IsWhatsappNoForCustomer, MarkAttendNotification, UpdateUserName, 
				IsNewQuotationNumberManual, ShowQuantityNewQuotation, ShowAmountNewQuotation, IsNewQuotationfeatureOn, IsAllowClickForPhotoRegister, 
				IsAllowClickForVisit, IsAllowClickForVisitForSpecificUser, HierarchywiseLoginInPortal, ShowUserwiseLeadMenu, 
				UpdateOtherID, UpdateUserID, AllowProfileUpdate, GeofencingRelaxationinMeter, LogoutWithLogFile, InAppUpdateApplicable, 
				IsFeedbackHistoryActivated, IsAutoLeadActivityDateTime, ShowAutoRevisitInDashboard, ShowAutoRevisitInAppMenu, IsShowNearByTeam, 
				IsShowRevisitRemarksPopup, IsAllowShopStatusUpdate, ShowTotalVisitAppMenu, OfflineShopAccuracy, AutoRevisitTimeInSeconds, 
				PartyUpdateAddrMandatory, IsHierarchyforHorizontalPerformanceReport, IsCollectionOrderWise, ShowCollectionOnlywithInvoiceDetails, 
				ShowCollectionAlert, ShowZeroCollectioninAlert, IsPendingCollectionRequiredUnderTeam, IsShowRepeatOrderinNotification, 
				IsShowRepeatOrdersNotificationinTeam, AutoDDSelect, ShowPurposeInShopVisit, WillRoomDBShareinLogin, GPSAlertwithVibration, 
				ShopScreenAftVisitRevisit, IsFeedbackAvailableInShop, IsAllowBreakageTracking, IsAllowBreakageTrackingunderTeam, 
				IsRateEnabledforNewOrderScreenwithSize, IgnoreNumberCheckwhileShopCreation, Showdistributorwisepartyorderreport, 
				IsShowHomeLocationMap, IsBeatRouteReportAvailableinTeam, ShowAttednaceClearmenu, CommonAINotification, IsFaceRecognitionOnEyeblink, 
				GPSNetworkIntervalMins, IsShowTypeInRegistrationForSpecificUser, IsFeedbackMandatoryforNewShop, IsLoginSelfieRequired, 
				IsJointVisitEnable, IsShowAllEmployeeforJointVisit, IsMultipleContactEnableforShop, IsContactPersonSelectionRequiredinRevisit, 
				IsContactPersonRequiredinQuotation, IsShowBeatInMenu,GETDATE(),'''+@USERID+''','''+@ACTION+ ''' 
			FROM TBL_MASTER_USER WHERE USER_ID='''+@DOC_ID+''''

			--SELECT @SQLSTAT
			EXEC SP_EXECUTESQL @SQLSTAT
		END
	
	IF (@TABLE_NAME='FTS_UserPartyCreateAccess')
		BEGIN
			INSERT INTO FTS_UserPartyCreateAccess_Audit ([ID], [User_Id], [Shop_TypeId], [LoggedOn], [LoggedBy], [Action])
			SELECT [ID], [User_Id], [Shop_TypeId], GETDATE(), @USERID, @ACTION FROM FTS_UserPartyCreateAccess 
				WHERE ID=@DOC_ID
		END

	IF (@TABLE_NAME='Employee_ChannelMap')
		BEGIN
			INSERT INTO Employee_ChannelMap_Audit ([EP_MAPID], [EP_CH_ID], [EP_EMP_CONTACTID], [CreateDate], [CreateUser], [LoggedOn], [LoggedBy], [Action])
			SELECT [EP_MAPID], [EP_CH_ID], [EP_EMP_CONTACTID], [CreateDate], [CreateUser], GETDATE(), @USERID, @ACTION FROM Employee_ChannelMap 
				WHERE EP_MAPID=@DOC_ID
		END

	IF (@TABLE_NAME='FTS_EMPSTATEMAPPING')
		BEGIN
			INSERT INTO FTS_EMPSTATEMAPPING_Audit ([USER_ID], [STATE_ID], [SYS_DATE_TIME ], [AUTHOR ], [LoggedOn], [LoggedBy], [Action])
			SELECT [USER_ID], [STATE_ID], [SYS_DATE_TIME ], [AUTHOR ], GETDATE(), @USERID, @ACTION FROM FTS_EMPSTATEMAPPING 
				WHERE USER_ID=@DOC_ID
		END

	IF (@TABLE_NAME='FTS_EmployeeBranchMap')
		BEGIN
			INSERT INTO FTS_EmployeeBranchMap_Audit ([ID] ,[EmployeeId],[BranchId],[CreatedBy],[CreatedOn],[Emp_Contactid], [LoggedOn], [LoggedBy], [Action])
			SELECT [ID] ,[EmployeeId],[BranchId],[CreatedBy],[CreatedOn],[Emp_Contactid], GETDATE(), @USERID, @ACTION FROM FTS_EmployeeBranchMap 
				WHERE ID=@DOC_ID
		END
END

