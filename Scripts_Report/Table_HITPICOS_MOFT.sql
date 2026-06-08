
---- Table 
WITH 
	TD_MOFT AS (
		SELECT
			FORMAT(Month, 'yyyy-MM') AS [Month], TargetTimeID, /*Tháng khảo sát & ID Tháng*/
			ZoneID, SRID, SRFullName, /*Infor Person: Khu vực - ID SR - SR Name*/
			OutletID,
			/*=====>KPI PICOS khảo sát trong Outlet<=====*/
				NND_Target, 
				NND_Actual,
				NND as [NND_Status],
				-------------------
				FS_Target, 
				FS_Actual,
				FS as [MS_Status],
				-------------------
				VS_Target, 
				VS_Actual,
				VS as [VS_Status],
				-------------------
				PrCom_Target,
				PrCom_Actual, 
				PrCom as [Prcom_Status],

			/*=====>KPI PICOS khảo sát trong Outlet<=====*/
				FS_Target2, 
				FS_Actual2,
				FS2 as [OS_Status],

			/*=====>Rule PICOS Score=====*/
			CASE 
				WHEN 
					ISNULL(NND,1) <> 0 and
					ISNULL(FS,1) <> 0 and
					ISNULL(VS,1) <> 0 and
					ISNULL(PrCom,1) <> 0 
				THEN 1
				ELSE 0
			END AS [Total_HitPICOS]
			FROM [srp].[SRP-EOEAnswerFocusPerformanceAudit]
		WHERE [Month] >='2026-01-01'
			 --@ID_Month -- ID tháng cần tính
		)
	-- By [Month], ZoneID
--SELECT
--		TargetTimeID,
--		[Month],
--		ZoneID,
--		COUNT(*) AS [TotalOutlet],
--		SUM(Total_HitPICOS) AS [Total_HitPICOS],
--		CAST(ROUND(SUM(Total_HitPICOS) * 100.0 / COUNT(*), 2) AS DECIMAL(10,2)) AS [%HitPICOS]
--	FROM TD_MOFT where 
--				--Month = '2026-04'
--				TargetTimeID in (148)

--GROUP BY [Month], ZoneID, TargetTimeID
--ORDER BY [Month], ZoneID,TargetTimeID;

	---- Group by ZoneID, SRID,SRFullName, [Month] ---

SELECT
    [Month], 
    ZoneID,
    SRID,
	SRFullName,
    COUNT(*) AS [TotalOutlet],
    SUM(Total_HitPICOS) AS [Total_HitPICOS],
    CAST(ROUND(SUM(Total_HitPICOS) * 100.0 / COUNT(*), 2) AS DECIMAL(10,2)) AS [%HitPICOS]
FROM TD_MOFT
GROUP BY SRID,SRFullName, [Month], ZoneID
ORDER BY [Month], ZoneID, SRID,SRFullName;
