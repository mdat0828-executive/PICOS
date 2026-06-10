DECLARE @Month as Date
Set @Month = '2026-05-01'

;WITH
/*============================================================================Bảng lấy Data Audit Kênh GT - BU: NORTH|CENTRAL|GHCM|MKD (TOFT/TONT/MONT)============================================================================*/
	GT_Audit as
		(SELECT 'GT' as Channel
			,Month as [Month],ZoneID,SRID,SRFullName
			,OutletID,TRIM(Name) as [OutletName],FORMAT(AuditDate,'dd/MM/yyyy') as AuditDate,SegmentName,Tier
			,NND_Target,NND_Actual,NND
			,FS_Target,FS_Actual,FS
			,FS_Target2 as [FS_OS_Target],FS_Actual2 as [FS_OS_Actual] ,FS2 as [FS_OS]
			,VS_Target,VS_Actual,VS
			,PrCom_Target,PrCom_Actual,PrCom
			,ProAc_Target,ProAc_Actual,ProAc
		FROM [srp].[SRP-EOEAnswerFocusPerformanceAudit_SRP]
		WHERE ZoneID NOT LIKE ('MO_')),

/*=========================Bảng lấy Data Audit Kênh MONT - BU: MONT=========================*/
	MONT_Audit as
		(SELECT 'MONT' as Channel
			,Month as [Month],ZoneID,SRID,SRFullName
			,OutletID,TRIM(Name) as [OutletName],FORMAT(AuditDate,'dd/MM/yyyy') as AuditDate,SegmentName,Tier
			,NND_Target,NND_Actual,NND
			,FS_Target,FS_Actual,FS
			,FS_Target2 as [FS_OS_Target],FS_Actual2 as [FS_OS_Actual] ,FS2 as [FS_OS]
			,VS_Target,VS_Actual,VS
			,PrCom_Target,PrCom_Actual,PrCom
			,ProAc_Target,ProAc_Actual,ProAc
		FROM [srp].[SRP-EOEAnswerFocusPerformanceAudit_SRP]
		WHERE ZoneID LIKE ('MO_')),

/*================================Bảng lấy Data Audit Kênh MT - BU: MOFT=================================*/
	MT_Audit as
		(SELECT 'MOFT' as Channel
			,Month as [Month],ZoneID,SRID,SRFullName
			,OutletID,TRIM(Name) as [OutletName],FORMAT(AuditDate,'dd/MM/yyyy') as AuditDate,SegmentName,Tier
			,NND_Target,NND_Actual,NND
			,FS_Target,FS_Actual,FS
			,FS_Target2 as [FS_OS_Target],FS_Actual2 as [FS_OS_Actual] ,FS2 as [FS_OS]
			,VS_Target,VS_Actual,VS
			,PrCom_Target,PrCom_Actual,PrCom
			,NULL ProAc_Target, NULL  ProAc_Actual, NULL ProAc
		FROM [srp].[SRP-EOEAnswerFocusPerformanceAudit]
		WHERE MONTH >'2024-12-01'),

/*================================>> Bảng lấy Data Audit NTW <<=================================*/
	Total_Audit as
		(SELECT * FROM MT_AUDIT
			UNION ALL
				SELECT * FROM GT_AUDIT
					UNION ALL
						SELECT * FROM MONT_AUDIT),
/*================================>> Bảng lấy Structures <<=================================*/
	/*Mapping giữa Structure và những sale không trong SRP*/
	Structured as
		(SELECT
		Month ,BU ,Region ,ZoneID 
		,PersonID_RCM ,RCMName ,PersonID_ASM ,ASMName ,PersonID_SS ,SSName ,PersonID ,SRName ,Title
		,CASE WHEN [TRACKING] IS NULL THEN 1 ELSE 0 END as Note_SRP
		FROM 
			(SELECT 
				s.* 
				,e.Title AS [TRACKING]
			FROM [srp].[SRP_FullStructure_SR_DSM] AS s
			left join [srp].[SRP_SR_DSM_Exclude] as e on s.Month = e.Month and s.PersonID = e.PersonID
			WHERE s.MONTH = @MONTH /*and e.Title IS NULL*/) as srp),

/*=========================================================================================================Bảng Target PICOS theo Tháng========================================================================================*/
	GT_Target as
		(SELECT
			Month as Month
			,Channel
			,Audited_Outlet [OutletTarget]
			,Perfect_Outlet [OutletPerfect]
			,Target_PICOS [%Perfect]
		FROM [srp].[TF_PICOSTarget_GT&MONT]),
--============================================
	MT_Target as
		(Select 'MOFT' as Channel
			,Month as Month
			,ZoneID
			,Audited_Outlet [OutletTarget]
			,Perfect_Outlet [OutletPerfect]
			--,SRP_Outlet
			,Target_PICOS [%Perfect]
			,Target_Fundamental [%Fundamental]
		FROM [srp].[TF_PICOSTarget_MOFT]),
/*============================================*/
	MONT_Target as
		(SELECT
			Month AS [Month]
			,Channel
			,Audited_Outlet AS OutletTarget
			,Perfect_Outlet AS OutletPerfect
			,Target_PICOS AS [%Perfect]
		FROM [srp].[TF_PICOSTarget_GT&MONT]
		WHERE Month < '2026-06-01'
			UNION ALL
	--==============Update Target Mới nếu có thay đổi==============
		SELECT DISTINCT
			Month AS [Month]
			,'MONT' AS Channel
			,40 AS OutletTarget
			,30 AS OutletPerfect
			,0.75 AS [%Perfect]
		FROM [srp].[TF_PICOSTarget_GT&MONT]
		WHERE Month = '2026-06-01'),
/*----------------------------------------------------------------------------| Query chạy rule tính |--------------------------------------------------------------------------------*/
	Result_PICOS_GT as
		(SELECT 
			g.*
			,tg.[OutletTarget]
			,tg.[OutletPerfect]
			,tg.[%Perfect]
			FROM GT_AUDIT as g
			left join GT_Target as tg on tg.Month = g.[Month]
		--WHERE g.Month = @Month
		UNION ALL
		SELECT 
			MO.*
			,tg1.[OutletTarget]
			,tg1.[OutletPerfect]
			,tg1.[%Perfect]
			FROM MONT_AUDIT as MO
			left join MONT_Target as tg1 on tg1.Month = MO.[Month]
		--WHERE MO.Month = @Month
		)

	
		SELECT * FROM Result_PICOS_GT WHERE MONTH = @MONTH and ZoneID like ('MO_')