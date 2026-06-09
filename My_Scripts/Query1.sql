WITH
/*=========================Bảng lấy Data Audit Kênh GT - BU: NORTH|CENTRAL|GHCM|MKD (TOFT/TONT/MONT)=========================*/
	GT_Audit as
		(SELECT 
			FORMAT(Month,'yyyy-MM') as [Month],ZoneID,SRID,SRFullName
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
		(SELECT 
			FORMAT(Month,'yyyy-MM') as [Month],ZoneID,SRID,SRFullName
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
		(SELECT
			FORMAT(Month,'yyyy-MM') as [Month],ZoneID,SRID,SRFullName
			,OutletID,TRIM(Name) as [OutletName],FORMAT(AuditDate,'dd/MM/yyyy') as AuditDate,SegmentName,Tier
			,NND_Target,NND_Actual,NND
			,FS_Target,FS_Actual,FS
			,FS_Target2 as [FS_OS_Target],FS_Actual2 as [FS_OS_Actual] ,FS2 as [FS_OS]
			,VS_Target,VS_Actual,VS
			,PrCom_Target,PrCom_Actual,PrCom
			,NULL ProAc_Target, NULL  ProAc_Actual, NULL ProAc
		FROM [srp].[SRP-EOEAnswerFocusPerformanceAudit]),

/*================================Bảng lấy Data Audit NTW=================================*/
	Total_Audit as
		(SELECT * FROM MT_AUDIT
			UNION ALL
				SELECT * FROM GT_AUDIT
					UNION ALL
						SELECT * FROM MONT_AUDIT),

/*==============================Bảng Target PICOS theo Tháng===============================*/
	GT_Target as
		(SELECT 
			Channel
			,FORMAT(Month,'yyyy-MM') as Month
			,Audited_Outlet [OutletTarget]
			,Perfect_Outlet [OutletPerfect]
			,Target_PICOS [%Perfect]
		FROM [srp].[TF_PICOSTarget_GT&MONT]),
--============================================
	MT_Target as
		(Select
			FORMAT(Month,'yyyy-MM') as Month
			,ZoneID
			,Audited_Outlet [OutletTarget]
			,Perfect_Outlet [OutletPerfect]
			--,SRP_Outlet
			,Target_PICOS [%Perfect]
			,Target_Fundamental [%Fundamental]
		FROM [srp].[TF_PICOSTarget_MOFT])
--============================================
	MONT_Target as
SELECT TOP 10 * FROM MT_Target WHERE Month = '2026-04'