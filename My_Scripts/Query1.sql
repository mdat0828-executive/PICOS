with
	GT_Audit as
				(SELECT 
						Month,ZoneID,SRID,SRFullName
						,OutletID,AuditDate,Name,SegmentName,Tier
						,NND_Target,NND_Actual,NND
						,FS_Target,FS_Actual,FS
						--,FS_Target2,FS_Actual2,FS2
						,VS_Target,VS_Actual,VS
						,PrCom_Target,PrCom_Actual,PrCom
						,ProAc_Target,ProAc_Actual,ProAc
				 FROM [srp].[SRP-EOEAnswerFocusPerformanceAudit_SRP] ),
	MT_Audit as
				(SELECT
					Month,ZoneID,SRID,SRFullName
					,AuditDate,OutletID,Name,SegmentName,Tier
					,NND_Target,NND_Actual,NND
					,FS_Target,FS_Actual,FS
					,FS_Target2,FS_Actual2,FS2
					,VS_Target,VS_Actual,VS
					,PrCom_Target,PrCom_Actual,PrCom
				FROM [srp].[SRP-EOEAnswerFocusPerformanceAudit])
SELECT TOP 5 * FROM GT_AUDIT WHERE MONTH = '2026-05-01'
SELECT TOP 5 * FROM MT_AUDIT WHERE MONTH = '2026-05-01'