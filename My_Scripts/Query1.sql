/*====================================================================
    PARAMETERS
====================================================================*/
DECLARE @Month DATE = '2026-05-01';

WITH
/*====================================================================
    STEP 01 - LOAD AUDIT DATA
====================================================================*/

/*====================================================================
    CTE: GT_Audit
    Channel : GT
    BU      : NORTH | CENTRAL | GHCM | MKD
    Rule    : Exclude MONT Zone (MO_)
====================================================================*/
GT_Audit AS (
    SELECT
        'GT' AS Channel,
        [Month] AS [Month],
        -- Organization
        ZoneID,
        SRID,
        SRFullName,
        -- Outlet Information
        OutletID,
        TRIM(Name) AS OutletName,
        FORMAT(AuditDate, 'dd/MM/yyyy') AS AuditDate,
        SegmentName,
        Tier,
        -- NND
        NND_Target,
        NND_Actual,
        NND,
        -- FS
        FS_Target,
        FS_Actual,
        FS,
        -- FS Out Of Stock
        FS_Target2 AS FS_OS_Target,
        FS_Actual2 AS FS_OS_Actual,
        FS2 AS FS_OS,
        -- VS
        VS_Target,
        VS_Actual,
        VS,
        -- Product Communication
        PrCom_Target,
        PrCom_Actual,
        PrCom,
        -- Promotion Activity
        ProAc_Target,
        ProAc_Actual,
        ProAc
    FROM [srp].[SRP-EOEAnswerFocusPerformanceAudit_SRP]
    WHERE ZoneID NOT LIKE 'MO_'
),

/*====================================================================
    CTE: MONT_Audit
    Channel : MONT
    BU      : MONT
    Rule    : Only Zone MO_
====================================================================*/
MONT_Audit AS (
    SELECT
        'MONT' AS Channel,
        [Month] AS [Month],
        -- Organization
        ZoneID,
        SRID,
        SRFullName,
        -- Outlet Information
        OutletID,
        TRIM(Name) AS OutletName,
        FORMAT(AuditDate, 'dd/MM/yyyy') AS AuditDate,
        SegmentName,
        Tier,
        -- NND
        NND_Target,
        NND_Actual,
        NND,
        -- FS
        FS_Target,
        FS_Actual,
        FS,
        -- FS Out Of Stock
        FS_Target2 AS FS_OS_Target,
        FS_Actual2 AS FS_OS_Actual,
        FS2 AS FS_OS,
        -- VS
        VS_Target,
        VS_Actual,
        VS,
        -- Product Communication
        PrCom_Target,
        PrCom_Actual,
        PrCom,
        -- Promotion Activity
        ProAc_Target,
        ProAc_Actual,
        ProAc
    FROM [srp].[SRP-EOEAnswerFocusPerformanceAudit_SRP]
    WHERE ZoneID LIKE 'MO_'
),

/*====================================================================
    CTE: MT_Audit
    Channel : MOFT
    BU      : Modern Trade
    Source  : SRP-EOEAnswerFocusPerformanceAudit
    Note:
    - KPI ProAc không áp dụng cho MT
    - Trả NULL cho các cột ProAc
====================================================================*/
MT_Audit AS (
    SELECT
        'MOFT' AS Channel,
        [Month] AS [Month],
        -- Organization
        ZoneID,
        SRID,
        SRFullName,
        -- Outlet Information
        OutletID,
        TRIM(Name) AS OutletName,
        FORMAT(AuditDate, 'dd/MM/yyyy') AS AuditDate,
        SegmentName,
        Tier,
        -- NND
        NND_Target,
        NND_Actual,
        NND,
        -- FS
        FS_Target,
        FS_Actual,
        FS,
        -- FS Out Of Stock
        FS_Target2 AS FS_OS_Target,
        FS_Actual2 AS FS_OS_Actual,
        FS2 AS FS_OS,
        -- VS
        VS_Target,
        VS_Actual,
        VS,
        -- Price Communication
        PrCom_Target,
        PrCom_Actual,
        PrCom,
        -- Promotion Activity (Not Applicable)
        NULL AS ProAc_Target,
        NULL AS ProAc_Actual,
        NULL AS ProAc
    FROM [srp].[SRP-EOEAnswerFocusPerformanceAudit]
    WHERE [Month] > '2024-12-01'
),

/*====================================================================
    CTE: Total_Audit (Unused in the rest of query, but kept for logic integrity)
====================================================================*/
Total_Audit AS (
    SELECT * FROM MT_Audit
    UNION ALL
    SELECT * FROM GT_Audit
    UNION ALL
    SELECT * FROM MONT_Audit
),

/*====================================================================
    CTE: Structured
    Mapping giữa Structure và những sale không trong SRP
====================================================================*/
Structured AS (
    SELECT
        [Month],
        BU,
        Region,
        ZoneID,
        PersonID_RCM,
        RCMName,
        PersonID_ASM,
        ASMName,
        PersonID_SS,
        SSName,
        PersonID,
        SRName,
        Title,
        CASE 
            WHEN [TRACKING] IS NULL THEN 1 
            ELSE 0 
        END AS Note_SRP
    FROM (
        SELECT 
            s.*,
            e.Title AS [TRACKING]
        FROM [srp].[SRP_FullStructure_SR_DSM] AS s
        LEFT JOIN [srp].[SRP_SR_DSM_Exclude] AS e 
            ON s.[Month] = e.[Month] 
           AND s.PersonID = e.PersonID
        /* WHERE s.Month = @Month AND e.Title IS NULL */
    ) AS srp
),

/*====================================================================
    CTE: GT_MONT_Target
    Bảng Target PICOS theo Tháng
====================================================================*/
GT_MONT_Target AS (
    -- GT
    SELECT
        [Month],
        Channel,
        Audited_Outlet AS OutletTarget,
        Perfect_Outlet AS OutletPerfect,
        Target_PICOS AS [%Perfect]
    FROM [srp].[TF_PICOSTarget_GT&MONT]
    WHERE Channel = 'GT'

    UNION ALL

    -- MONT dữ liệu cũ
    SELECT
        [Month],
        'MONT' AS Channel,
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
        40 AS OutletTarget,
        30 AS OutletPerfect,
        0.75 AS [%Perfect]
),

/*====================================================================
    CTE: MT_Target (Unused in the rest of query, but kept for logic integrity)
====================================================================*/
MT_Target AS (
    SELECT 
        'MOFT' AS Channel,
        [Month] AS [Month],
        ZoneID,
        Audited_Outlet AS [OutletTarget],
        Perfect_Outlet AS [OutletPerfect],
        Target_PICOS AS [%Perfect],
        Target_Fundamental AS [%Fundamental]
    FROM [srp].[TF_PICOSTarget_MOFT]
),

/*====================================================================
    CTE: PICOS_GT
    Query chạy rule tính
====================================================================*/
PICOS_GT AS (
    SELECT 
        t.*,
        CASE 
            WHEN s.Note_SRP IS NULL THEN -1 
            ELSE s.Note_SRP 
        END AS Note_SRP
    FROM (
        SELECT * FROM GT_Audit
        UNION ALL
        SELECT * FROM MONT_Audit
    ) AS t
    LEFT JOIN Structured AS s 
        ON t.[Month] = s.[Month] 
       AND t.SRID = s.PersonID
),

/*====================================================================
    CTE: Result_Picos_GT
====================================================================*/
Result_Picos_GT AS (
    SELECT
        x.*,
        tg.OutletTarget,
        tg.OutletPerfect,
        tg.[%Perfect],
        ROW_NUMBER() OVER (
            PARTITION BY x.[Month], x.SRID
            ORDER BY x.PerfectStore DESC
        ) AS [Rank]
    FROM (
        SELECT 
            *,
            CASE 
                WHEN [Month] IN ('2026-04-01', '2026-05-01')
                     AND ISNULL(NND_Result, 1) <> 0
                     AND ISNULL(VS_Result, 1) <> 0
                     AND ISNULL(FS_Result, 1) <> 0
                     AND ISNULL(PrCom_Result, 1) <> 0
                THEN 1
                WHEN [Month] NOT IN ('2026-04-01', '2026-05-01')
                     AND ISNULL(NND_Result, 1) <> 0
                     AND ISNULL(VS_Result, 1) <> 0
                     AND ISNULL(FS_Result, 1) <> 0
                     AND ISNULL(PrCom_Result, 1) <> 0
                     AND ISNULL(ProAc_Result, 1) <> 0
                THEN 1
                ELSE 0
            END AS PerfectStore
        FROM (
            SELECT
                Channel,
                [Month],
                ZoneID,
                SRID,
                SRFullName,
                AuditDate,
                OutletID,
                OutletName,
                SegmentName,
                Tier,
                Note_SRP,
                CASE
                    WHEN NND_Target IS NULL THEN NULL
                    WHEN NND_Actual >= NND_Target THEN 1
                    ELSE 0
                END AS NND_Result,
                CASE
                    WHEN FS_Target IS NULL THEN NULL
                    WHEN FS_Actual >= FS_Target THEN 1
                    ELSE 0
                END AS FS_Result,
                CASE
                    WHEN VS_Target IS NULL THEN NULL
                    WHEN VS_Actual >= VS_Target THEN 1
                    ELSE 0
                END AS VS_Result,
                CASE
                    WHEN PrCom_Target IS NULL THEN NULL
                    WHEN PrCom_Actual >= PrCom_Target THEN 1
                    ELSE 0
                END AS PrCom_Result,
                CASE
                    WHEN ProAc_Target IS NULL THEN NULL
                    WHEN ProAc_Actual >= ProAc_Target THEN 1
                    ELSE 0
                END AS ProAc_Result
            FROM PICOS_GT
        ) AS t
    ) AS x
    LEFT JOIN GT_MONT_Target AS tg
        ON x.[Month] = tg.[Month]
       AND x.Channel = tg.Channel
)

/*====================================================================
    FINAL SELECT
====================================================================*/
SELECT
    v1.[BusinessUnitID],
    v1.RegionName,
    r1.[Month],
    r1.ZoneID,
    r1.SRID,
    r1.SRFullName,
    r1.AuditDate,
    r1.OutletID,
    r1.OutletName,
    r1.SegmentName,
    r1.Tier,
    r1.Note_SRP,
    r1.NND_Result,
    r1.FS_Result,
    r1.VS_Result,
    r1.PrCom_Result,
    r1.ProAc_Result,
    r1.PerfectStore,
    r1.OutletTarget,
    r1.OutletPerfect,
    r1.[%Perfect],
    CASE
        WHEN r1.OutletTarget >= r1.[Rank] THEN 1
        ELSE 0
    END AS OutletAchieved
FROM Result_Picos_GT AS r1
LEFT JOIN [srp].[v_TD_Region_Area] AS v1
    ON r1.ZoneID = v1.AreaID
WHERE r1.[Month] = @Month;
