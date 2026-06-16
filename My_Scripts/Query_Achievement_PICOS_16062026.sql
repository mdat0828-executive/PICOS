/*====================================================================
    PARAMETERS
====================================================================*/
DECLARE @Month DATE = '2026-05-01';
/*====================================================================
    STEP 01 - LOAD AUDIT DATA
====================================================================*/

WITH
/*====================================================================
    GT_Target
	MONT_Target
    Bảng Target PICOS theo Tháng
====================================================================*/
GT_Target AS 
(
    -- GT
    SELECT
        [Month],
        Channel,
        Audited_Outlet AS OutletTarget,
        Perfect_Outlet AS OutletPerfect,
        Target_PICOS AS [%Perfect]
    FROM [srp].[TF_PICOSTarget_GT&MONT]
    WHERE Channel = 'GT'
),
MONT_Target AS
(
	SELECT
	[Month],
	'MONT' AS Channel,
	'MO8' AS ZoneID,
	Audited_Outlet AS OutletTarget,
	Perfect_Outlet AS OutletPerfect,
	Target_PICOS AS [%Perfect]
	FROM [srp].[TF_PICOSTarget_GT&MONT]
	WHERE Channel = 'GT'
	AND [Month] < '2026-06-01'
	UNION ALL
	SELECT
	[Month],
	'MONT' AS Channel,
	'MO6' AS ZoneID,
	Audited_Outlet AS OutletTarget,
	Perfect_Outlet AS OutletPerfect,
	Target_PICOS AS [%Perfect]
	FROM [srp].[TF_PICOSTarget_GT&MONT]
	WHERE Channel = 'GT'
	AND [Month] < '2026-06-01'
	UNION ALL
	-- MONT target mới
	SELECT
	CAST('2026-06-01' AS DATE) AS [Month],
	'MONT' AS Channel,
	'MO6' AS ZoneID,
	40 AS OutletTarget,
	30 AS OutletPerfect,
	0.75 AS [%Perfect]
	UNION ALL
	-- MONT target mới
	SELECT
	CAST('2026-06-01' AS DATE) AS [Month],
	'MONT' AS Channel,
	'MO8' AS ZoneID,
	40 AS OutletTarget,
	30 AS OutletPerfect,
	0.75 AS [%Perfect]
),
/*====================================================================
						|GT_Audit||
    Channel : GT
    BU      : NORTH | CENTRAL | GHCM | MKD
    Rule    : Exclude MONT Zone (MO_)
====================================================================*/
GT_Audit AS 
(	
	Select 
		r.BusinessUnitName as [BU], r.RegionName As[Region] , a.*
		FROM 
		(
			SELECT
				FORMAT([Month],'yyyy-MM-dd') AS [Month],
				/*Organization*/ ZoneID, SRID, SRFullName,
				/*Outlet Information*/ OutletID, TRIM(Name) AS OutletName, FORMAT(AuditDate, 'yyyy-MM-dd') AS AuditDate, SegmentName, Tier,
				/*NND*/ NND_Target,NND_Actual,NND,
				/*FS*/ FS_Target,FS_Actual,FS,
				/*FS Out Of Stock*/ FS_Target2 AS FS_OS_Target,FS_Actual2 AS FS_OS_Actual,FS2 AS FS_OS,
				/*Visibility*/ VS_Target,VS_Actual,VS,
				/*Product Communication*/ PrCom_Target,PrCom_Actual,PrCom,
				/*Promotion Activity*/ ProAc_Target,ProAc_Actual,ProAc,
			'GT' AS Channel
			FROM [srp].[SRP-EOEAnswerFocusPerformanceAudit_SRP] WHERE ZoneID NOT LIKE 'MO_'
		) As a
			LEFT JOIN [srp].[v_TD_Region_Area] r ON a.ZoneID = r.AreaID
),
/*====================================================================
						|||MONT_Audit||
    Channel : MONT
    BU      : MODERN ON TRADE
    Rule    : MO6 | MO8
====================================================================*/
MONT_Audit AS
(	
	Select 
		'[MODERN ON TRADE]' As [BU], r.RegionName As[Region], a.*
		FROM 
		(
			SELECT
				FORMAT([Month],'yyyy-MM-dd') AS [Month],
				/*Organization*/ ZoneID, SRID, SRFullName,
				/*Outlet Information*/ OutletID, TRIM(Name) AS OutletName, FORMAT(AuditDate, 'yyyy-MM-dd') AS AuditDate, SegmentName, Tier,
				/*NND*/ NND_Target,NND_Actual,NND,
				/*FS*/ FS_Target,FS_Actual,FS,
				/*FS Out Of Stock*/ FS_Target2 AS FS_OS_Target,FS_Actual2 AS FS_OS_Actual,FS2 AS FS_OS,
				/*Visibility*/ VS_Target,VS_Actual,VS,
				/*Product Communication*/ PrCom_Target,PrCom_Actual,PrCom,
				/*Promotion Activity*/ ProAc_Target,ProAc_Actual,ProAc,
			'MONT' AS Channel
			FROM [srp].[SRP-EOEAnswerFocusPerformanceAudit_SRP] WHERE ZoneID LIKE 'MO_'
		) As a
			LEFT JOIN [srp].[v_TD_Region_Area] r ON a.ZoneID = r.AreaID
),
/*====================================================================
						|Nationwide|
    Channel : MONT & GT
    BU      : MODERN ON TRADE | NORTH | CENTRAL | GHCM | MKD
====================================================================*/
PICOS_AUDIT AS
(
		SELECT * FROM GT_Audit
			UNION ALL
		SELECT * FROM MONT_Audit 
),
/*====================================================================
						|Structured|
    Mapping giữa Structure và những sale không trong SRP
====================================================================*/
Structured AS 
(
		SELECT
        [Month],BU,Region,ZoneID,PersonID_RCM,RCMName,PersonID_ASM,ASMName,PersonID_SS,SSName,PersonID SRID,SRName,Title,
        CASE 
            WHEN [TRACKING] IS NULL THEN 1 
            ELSE 0 
        END AS Note_SRP
		FROM 
		(
			SELECT 
            s.*,
            e.Title AS [TRACKING]
			FROM [srp].[SRP_FullStructure_SR_DSM] AS s
			LEFT JOIN [srp].[SRP_SR_DSM_Exclude] AS e 
            ON s.[Month] = e.[Month] 
           AND s.PersonID = e.PersonID
		)AS srp
),
/*====================================================================
    Result_Picos_GT
====================================================================*/
Result_GT AS (
    SELECT
        gt1.*,
        tg.OutletTarget,
        tg.OutletPerfect,
        tg.[%Perfect],
        ROW_NUMBER() OVER (
            PARTITION BY gt1.[Month], gt1.SRID
            ORDER BY gt1.PerfectStore DESC
        ) AS [Rank]
    FROM (
        SELECT *,
            CASE 
                WHEN [Month] IN ('2026-04-01', '2026-05-01')
                     AND ISNULL(NND_Result, 1) <> 0
                     AND ISNULL(VS_Result, 1) <> 0
                     AND ISNULL(FS_Result, 1) <> 0
                     AND ISNULL(PrCom_Result, 1) <> 0 THEN 1
                WHEN [Month] NOT IN ('2026-04-01', '2026-05-01')
                     AND ISNULL(NND_Result, 1) <> 0
                     AND ISNULL(VS_Result, 1) <> 0
                     AND ISNULL(FS_Result, 1) <> 0
                     AND ISNULL(PrCom_Result, 1) <> 0
                     AND ISNULL(ProAc_Result, 1) <> 0 THEN 1
                ELSE 0 END AS PerfectStore
        FROM (
            SELECT
                BU,Channel,[Month],ZoneID,SRID,SRFullName,AuditDate,OutletID,OutletName,SegmentName,Tier,
                NND_Target,
                NND_Actual,
                CASE
                    WHEN NND_Target IS NULL THEN NULL
                    WHEN NND_Actual >= NND_Target THEN 1
                    ELSE 0
                END AS NND_Result,
                FS_Target,
                FS_Actual,                
                CASE
                    WHEN FS_Target IS NULL THEN NULL
                    WHEN FS_Actual >= FS_Target THEN 1
                    ELSE 0
                END AS FS_Result,
                VS_Target,
                VS_Actual,                
                CASE
                    WHEN VS_Target IS NULL THEN NULL
                    WHEN VS_Actual >= VS_Target THEN 1
                    ELSE 0
                END AS VS_Result,
                PrCom_Target,
                PrCom_Actual,
                CASE
                    WHEN PrCom_Target IS NULL THEN NULL
                    WHEN PrCom_Actual >= PrCom_Target THEN 1
                    ELSE 0
                END AS PrCom_Result,
                ProAc_Target,
                ProAc_Actual,
                CASE
                    WHEN ProAc_Target IS NULL THEN NULL
                    WHEN ProAc_Actual >= ProAc_Target THEN 1
                    ELSE 0
                END AS ProAc_Result
            FROM GT_Audit
			) AS gt
		) AS gt1
		 LEFT JOIN GT_Target AS tg
        ON gt1.[Month] = tg.[Month]
       AND gt1.Channel = tg.Channel
),
/*====================================================================
    Result_Picos_MONT
====================================================================*/
Result_MONT AS (
    SELECT
        mo1.*,
        tg.OutletTarget,
        tg.OutletPerfect,
        tg.[%Perfect],
        ROW_NUMBER() OVER (
            PARTITION BY mo1.[Month], mo1.SRID
            ORDER BY mo1.PerfectStore DESC
        ) AS [Rank]
    FROM (
        SELECT *,
            CASE 
                WHEN [Month] IN ('2026-04-01', '2026-05-01')
                     AND ISNULL(NND_Result, 1) <> 0
                     AND ISNULL(VS_Result, 1) <> 0
                     AND ISNULL(FS_Result, 1) <> 0
                     AND ISNULL(PrCom_Result, 1) <> 0 THEN 1
                WHEN [Month] NOT IN ('2026-04-01', '2026-05-01')
                     AND ISNULL(NND_Result, 1) <> 0
                     AND ISNULL(VS_Result, 1) <> 0
                     AND ISNULL(FS_Result, 1) <> 0
                     AND ISNULL(PrCom_Result, 1) <> 0
                     AND ISNULL(ProAc_Result, 1) <> 0 THEN 1
                ELSE 0 END AS PerfectStore
        FROM (
            SELECT
                BU,Channel,[Month],ZoneID,SRID,SRFullName,AuditDate,OutletID,OutletName,SegmentName,Tier,
                NND_Target,
                NND_Actual,
                CASE
                    WHEN NND_Target IS NULL THEN NULL
                    WHEN NND_Actual >= NND_Target THEN 1
                    ELSE 0
                END AS NND_Result,
                FS_Target,
                FS_Actual,                
                CASE
                    WHEN FS_Target IS NULL THEN NULL
                    WHEN FS_Actual >= FS_Target THEN 1
                    ELSE 0
                END AS FS_Result,
                VS_Target,
                VS_Actual,                
                CASE
                    WHEN VS_Target IS NULL THEN NULL
                    WHEN VS_Actual >= VS_Target THEN 1
                    ELSE 0
                END AS VS_Result,
                PrCom_Target,
                PrCom_Actual,
                CASE
                    WHEN PrCom_Target IS NULL THEN NULL
                    WHEN PrCom_Actual >= PrCom_Target THEN 1
                    ELSE 0
                END AS PrCom_Result,
                ProAc_Target,
                ProAc_Actual,
                CASE
                    WHEN ProAc_Target IS NULL THEN NULL
                    WHEN ProAc_Actual >= ProAc_Target THEN 1
                    ELSE 0
                END AS ProAc_Result
            FROM MONT_Audit
        ) AS mo
    ) AS mo1
    LEFT JOIN MONT_Target AS tg
        ON mo1.[Month] = tg.[Month]
       AND mo1.Channel = tg.Channel
	   AND mo1.ZoneID = tg.ZoneID
),
/*====================================================================
						|Nationwide|
    Channel : MONT & GT
    BU      : MODERN ON TRADE | NORTH | CENTRAL | GHCM | MKD
====================================================================*/
Result_PICOS AS
(
	SELECT * FROM Result_MONT
		UNION ALL
	SELECT * FROM Result_GT
)

Select  p.*,
s.Note_SRP
From Result_PICOS AS p
left join Structured s on s.SRID = p.SRID
and s.Month = p.Month
where p.month = '2026-06-01' and p.OutletTarget >= p.Rank and s.Note_SRP = 1

