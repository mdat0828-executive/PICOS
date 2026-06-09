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
		FROM [srp].[SRP-EOEAnswerFocusPerformanceAudit])


SELECT TOP 5 * FROM MT_AUDIT WHERE MONTH = '2026-06'
UNION ALL
SELECT TOP 100 * FROM GT_AUDIT WHERE MONTH = '2026-06'
UNION ALL
SELECT TOP 100 * FROM MONT_AUDIT WHERE MONTH = '2026-06'