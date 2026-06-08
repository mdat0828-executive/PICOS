WITH PICOS_Raw_MOFT AS
		(
			SELECT
				Month,
				TargetTimeID,
				ZoneID,
				SRID,
				SRFullName,
				OutletID,
				Name,

				/* ---------- NND ---------- */
				NND_Target,
				NND_Actual,
				CASE
					WHEN ISNULL(NND_Actual,0) >= ISNULL(NND_Target,0)
					THEN 1 ELSE 0
				END AS NND_Achieve,

				/* ---------- Main Shelf ---------- */
				FS_Target,
				FS_Actual,
				CASE
					WHEN ISNULL(FS_Actual,0) >= ISNULL(FS_Target,0)
					THEN 1 ELSE 0
				END AS FS_MS_Achieve,

				/* ---------- Visibility ---------- */
				VS_Target,
				VS_Actual,
				CASE
					WHEN ISNULL(VS_Actual,0) >= ISNULL(VS_Target,0)
					THEN 1 ELSE 0
				END AS VS_Achieve,

				/* ---------- PrCom ---------- */
				PrCom_Target,
				PrCom_Actual,
				CASE
					WHEN ISNULL(PrCom_Actual,0) >= ISNULL(PrCom_Target,0)
					THEN 1 ELSE 0
				END AS PrCom_Achieve,

				/* ---------- PERFECT PICOS ---------- */
				CASE
					WHEN ISNULL(NND_Actual,0) >= ISNULL(NND_Target,0)
					 AND ISNULL(FS_Actual,0) >= ISNULL(FS_Target,0)
					 AND ISNULL(VS_Actual,0) >= ISNULL(VS_Target,0)
					 AND ISNULL(PrCom_Actual,0) >= ISNULL(PrCom_Target,0)
					THEN 1
					ELSE 0
				END AS PICOS_Achieve,

				/* ---------- Target Outlet ---------- */
				CASE
					WHEN Month < '2025-11-01'
					THEN CASE ZoneID
							WHEN 'MF1' THEN 10
							WHEN 'MF3' THEN 12
							WHEN 'MF4' THEN 20
						 END

					WHEN Month = '2026-03-01'
					THEN CASE ZoneID
							WHEN 'MF1' THEN 7
							WHEN 'MF3' THEN 9
							WHEN 'MF4' THEN 12
						 END

					ELSE CASE ZoneID
							WHEN 'MF1' THEN 12
							WHEN 'MF3' THEN 15
							WHEN 'MF4' THEN 25
						 END
				END AS Target

			FROM [srp].[SRP-EOEAnswerFocusPerformanceAudit]

			WHERE ZoneID LIKE 'MF%'
		),

/* ---------- Ranking ---------- */
Ranked AS
		(
			SELECT
				ROW_NUMBER() OVER
				(
					PARTITION BY Month, SRID
					ORDER BY PICOS_Achieve DESC, OutletID
				) AS STT,

				*

			FROM PICOS_Raw_MOFT
		),

/* ---------- Final Result ---------- */
Final_Result As 
	(SELECT *,
		CASE
			WHEN STT <= Target THEN 1
			ELSE 0
		END AS Result_Target
	FROM Ranked	)

SELECT 

Month,TargetTimeID,ZoneID,SRID,SRFullName,OutletID,Name,
NND_Target,NND_Actual,NND_Achieve,
FS_Target,FS_Actual,FS_MS_Achieve,
VS_Target,VS_Actual,VS_Achieve,
PrCom_Target,PrCom_Actual,PrCom_Achieve,PICOS_Achieve

FROM Final_Result
WHERE Result_Target = 1 and TargetTimeID = 148


/*----------------------------- Total All KPI MOFT----------------------*/
WITH PICOS_Raw_MOFT AS
(
    SELECT
        Month,
        TargetTimeID,
        ZoneID,
        SRID,
        SRFullName,
        OutletID,
        Name,

        /* ---------- NND ---------- */
        NND_Target,
        NND_Actual,
        CASE
            WHEN ISNULL(NND_Actual,0) >= ISNULL(NND_Target,0)
            THEN 1 ELSE 0
        END AS NND_Achieve,

        /* ---------- Main Shelf ---------- */
        FS_Target,
        FS_Actual,
        CASE
            WHEN ISNULL(FS_Actual,0) >= ISNULL(FS_Target,0)
            THEN 1 ELSE 0
        END AS FS_MS_Achieve,

		  /* ---------- OFF Shelf ---------- */
        FS_Target2,
        FS_Actual2,
        CASE
			WHEN FS_Target2 IS NULL Then Null
            WHEN ISNULL(FS_Actual2,0) >= ISNULL(FS_Target2,0)
            THEN 1 ELSE 0
        END AS FS_OS_Achieve,

        /* ---------- Visibility ---------- */
        VS_Target,
        VS_Actual,
        CASE
            WHEN ISNULL(VS_Actual,0) >= ISNULL(VS_Target,0)
            THEN 1 ELSE 0
        END AS VS_Achieve,

        /* ---------- PrCom ---------- */
        PrCom_Target,
        PrCom_Actual,
        CASE
            WHEN ISNULL(PrCom_Actual,0) >= ISNULL(PrCom_Target,0)
            THEN 1 ELSE 0
        END AS PrCom_Achieve,

        /* ---------- PERFECT PICOS ---------- */
        CASE
            WHEN ISNULL(NND_Actual,0) >= ISNULL(NND_Target,0)
             AND ISNULL(FS_Actual,0) >= ISNULL(FS_Target,0)
             AND ISNULL(VS_Actual,0) >= ISNULL(VS_Target,0)
             AND ISNULL(PrCom_Actual,0) >= ISNULL(PrCom_Target,0)
            THEN 1
            ELSE 0
        END AS PICOS_Achieve,

        /* ---------- Target Outlet ---------- */
        CASE
            WHEN Month < '2025-11-01'
            THEN CASE ZoneID
                    WHEN 'MF1' THEN 10
                    WHEN 'MF3' THEN 12
                    WHEN 'MF4' THEN 20
                 END

            WHEN Month = '2026-03-01'
            THEN CASE ZoneID
                    WHEN 'MF1' THEN 7
                    WHEN 'MF3' THEN 9
                    WHEN 'MF4' THEN 12
                 END

            ELSE CASE ZoneID
                    WHEN 'MF1' THEN 12
                    WHEN 'MF3' THEN 15
                    WHEN 'MF4' THEN 25
                 END
        END AS Target

    FROM [srp].[SRP-EOEAnswerFocusPerformanceAudit]

    WHERE ZoneID LIKE 'MF%'
),

/* ---------- Ranking ---------- */
Ranked AS
(
    SELECT
        ROW_NUMBER() OVER
        (
            PARTITION BY Month, SRID
            ORDER BY PICOS_Achieve DESC, OutletID
        ) AS STT,

        *

    FROM PICOS_Raw_MOFT
),



/* ---------- Final Result ---------- */
Final_Result AS
(
    SELECT *,
        CASE
            WHEN STT <= Target THEN 1
            ELSE 0
        END AS Result_Target
    FROM Ranked
)

SELECT

    A.Month,
    A.TargetTimeID,
    A.ZoneID,
    A.SRID,
    A.SRFullName,
    A.OutletID,
    A.Name,

    A.NND_Target,
    A.NND_Actual,
    A.NND_Achieve,

    A.FS_Target,
    A.FS_Actual,
    A.FS_MS_Achieve,

    A.VS_Target,
    A.VS_Actual,
    A.VS_Achieve,

    A.PrCom_Target,
    A.PrCom_Actual,
    A.PrCom_Achieve,

    A.PICOS_Achieve,

	A.FS_Target2,
    A.FS_Actual2,
    A.FS_OS_Achieve,

    /* ---------- Planogram ---------- */
    P.PLG,
    P.PLG_Target,
    P.PLG_Score,

    /* ---------- Promotion ---------- */
    PR.Promotion_Target,
    PR.Promotion_Actual,
    PR.Promotion_Achieve

FROM Final_Result A

LEFT JOIN [srp].[SRP-EOEAnswerFocusPerformanceAudit_Planogram] P
    ON A.TargetTimeID = P.TargetTimeID
   AND A.OutletID     = P.OutletID

LEFT JOIN [srp].[SRP-EOEAnswerFocusPerformanceAudit_Promotion] PR
    ON A.TargetTimeID = PR.TargetTimeID
   AND A.OutletID     = PR.OutletID

WHERE A.Result_Target = 1
  AND A.TargetTimeID = 149