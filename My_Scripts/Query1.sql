WITH
/*=========================Bảng lấy Data Audit Kênh GT (TOFT/TONT/MONT)=========================*/
	GT_Audit as
		(SELECT 
			Month,ZoneID,SRID,SRFullName
			,OutletID,Name,AuditDate,SegmentName,Tier
			,NND_Target,NND_Actual,NND
			,FS_Target,FS_Actual,FS
			,FS_Target2 as [FS_OS_Target],FS_Actual2 as [FS_OS_Actual] ,FS2 as [FS_OS]
			,VS_Target,VS_Actual,VS
			,PrCom_Target,PrCom_Actual,PrCom
			,ProAc_Target,ProAc_Actual,ProAc
		FROM [srp].[SRP-EOEAnswerFocusPerformanceAudit_SRP] ),

/*================================Bảng lấy Data Audit Kênh MT=================================*/
	MT_Audit as
		(SELECT
			Month,ZoneID,SRID,SRFullName
			,OutletID,Name,AuditDate,SegmentName,Tier
			,NND_Target,NND_Actual,NND
			,FS_Target,FS_Actual,FS
			,FS_Target2 as [FS_OS_Target],FS_Actual2 as [FS_OS_Actual] ,FS2 as [FS_OS]
			,VS_Target,VS_Actual,VS
			,PrCom_Target,PrCom_Actual,PrCom
			,NULL ProAc_Target, NULL  ProAc_Actual, NULL ProAc
		FROM [srp].[SRP-EOEAnswerFocusPerformanceAudit])
SELECT TOP 5 * FROM MT_AUDIT WHERE MONTH = '2026-05-01'
UNION ALL
SELECT TOP 5 * FROM GT_AUDIT WHERE MONTH = '2026-05-01'
