---------------------------------PICOS Performance GT------------------------------

----------Delete data cũ -------------
--delete from [srp].[SRP-EOEAnswerFocusPerformanceAudit_SRP]  where 1=1 and Month = '2026-05-01'

----------Update Data mới -------------
Select * from [srp].[SRP-EOEAnswerFocusPerformanceAudit_SRP] where TargetTimeID = 149

------------------------HitPICOS-------------------------------------
DECLARE @ID_Month INT = 149;
Select 
	TargetTimeID, 
	Month, 
	ZoneID, 
	SRID, 
	SRFullName, 
	AuditDate, OutletID, 
	Name, SegmentName, Tier, 
	NND, FS, VS, PrCom, ProAc,
	CASE 
		WHEN isnull(NND,1) <> 0  and
             isnull(FS,1) <> 0  and
             isnull(VS,1) <> 0  and
             isnull(PrCom,1) <> 0
			 then 1 else 0 end
        AS [HitPICOS]
	from [srp].[SRP-EOEAnswerFocusPerformanceAudit_SRP] where TargetTimeID = @ID_Month

--insert into [srp].[SRP-EOEAnswerFocusPerformanceAudit_SRP] (Month,TargetTimeID,ZoneID,PersonID,FullName,PosID,SRID,SRFullName,AuditDate,AuditTime,OutletID,Name,SegmentName,Tier,Address,District,Province,WardType,NND_Target,NND_Actual,NND,FS_Target,FS_Actual,FS,FS_Target2,FS_Actual2,FS2,VS_Target ,VS_Actual ,VS ,PrCom_Target ,PrCom_Actual ,PrCom,ProAc_Target,ProAc_Actual,ProAc)

-------------------- Xuất Report Theo Structure ---------------
/* --New Logic Current Month */

--declare @Month as date

--set @Month = '2025-10-01';

--with PICOS as (


WITH MaxStructureMonth AS 
	(
		SELECT MAX(Month) AS MaxMonth
		FROM [srp].[SRP_FullStructure_SR_DSM]
	)

,ValidStructure AS 
(
    SELECT DISTINCT fs.PersonID ,fs.Title
    FROM [srp].[SRP_FullStructure_SR_DSM] fs
    CROSS JOIN MaxStructureMonth sm
    LEFT JOIN srp.[SRP_SR_DSM_Exclude] ex 
        ON fs.PersonID = ex.PersonID 
       AND fs.Month = ex.Month
    WHERE fs.Month = sm.MaxMonth
      AND ex.PersonID IS NULL
)

,MaxRankedMonth AS (
    SELECT MAX(Month) AS MaxRankMonth
    FROM (
        SELECT t1.Month
        FROM srp.[SRP-EOEAnswerFocusPerformanceAudit_SRP] t1
        JOIN (
            SELECT DISTINCT Month,
                CASE 
                    WHEN DAY(GETDATE()) <= 5 
                         AND Month = DATEADD(MONTH, -2, DATEADD(MONTH, DATEDIFF(MONTH,0,GETDATE()),0)) THEN 'last_month'
                    WHEN DAY(GETDATE()) <= 5 
                         AND Month = DATEADD(MONTH, -1, DATEADD(MONTH, DATEDIFF(MONTH,0,GETDATE()),0)) THEN 'current_month'
                    WHEN DAY(GETDATE()) > 5  
                         AND Month = DATEADD(MONTH, -1, DATEADD(MONTH, DATEDIFF(MONTH,0,GETDATE()),0)) THEN 'last_month'
                    WHEN DAY(GETDATE()) > 5  
                         AND Month = DATEADD(MONTH, 0, DATEADD(MONTH, DATEDIFF(MONTH,0,GETDATE()),0)) THEN 'current_month'
                    ELSE NULL 
                END AS check_month
            FROM srp.[SRP-EOEAnswerFocusPerformanceAudit_SRP] 
            WHERE Month >= DATEADD(MONTH, DATEDIFF(MONTH,0,DATEADD(MONTH,-2,GETDATE())),0)
        ) cm 
        ON t1.Month = cm.Month AND cm.check_month = 'current_month'
        WHERE t1.ZoneID NOT LIKE '%MF%'
	) R
)

,PICOS as (
SELECT Ranked.Month, REPLACE(REPLACE(BU, '[', ''), ']', '') BU, Region, ZoneID, Ranked.PersonID, FullName, Title
	,OutletID, Name ,SegmentName ,Tier 
	,NND_Actual ,NND_Target ,NND
	,FS_Actual ,FS_Target ,FS
	,VS_Actual ,VS_Target ,VS
	,PrCom_Actual ,PrCom_Target ,PrCom
	,[Outlet Perfect]
    ,CASE 
        WHEN rm.MaxRankMonth > sm.MaxMonth THEN 1	-- Structure chưa có tháng mới
        WHEN vs.PersonID IS NOT NULL THEN 1			-- Person có trong Structure tháng mới nhất
        ELSE 0
     END AS is_SRP
	 ,STT_Limit
	 ,STT
FROM (
	SELECT s_tbl2.*,
        CASE 
            WHEN s_tbl2.Month = '2025-05-01' AND (ZoneID IN ('H10','S9','HM2','HM4','S26','HM9','HM8','HM5','HM3','S11','H11','S12','S1','HM7','HM1','HM6','S10','S21','S18')
                 OR PersonID IN (80703568,80706176,80706214,80704770,80706465,80704854,80703437,80705881,80703335,80706247,80703337,80704683,80706464,80706424,80705739,80703278,80703429,80703413,80706139,80706150,80705074,80706195))
            THEN 6 
				--WHEN Month = '2025-09-01' THEN 15
				--WHEN Month = '2025-10-01' THEN 30
				--WHEN Month between '2025-11-01' and '2025-12-01' THEN 30
				--WHEN Month = '2026-01-01' THEN 40 --Test--
				--WHEN Month = '2026-02-01' THEN 15 --Test--
				--WHEN Month = '2026-03-01' THEN 30 --Test--
			ELSE t.Audited_Outlet
        END AS STT_Limit
    FROM 
		(
			SELECT Month, BU, Region, ZoneID, PersonID, FullName, OutletID, Name ,SegmentName , Tier
					,NND_Actual ,NND_Target ,NND
					,FS_Actual ,FS_Target ,FS
					,VS_Actual ,VS_Target ,VS
					,PrCom_Actual ,PrCom_Target ,PrCom
					,[Outlet Perfect] 
				   ,RANK() OVER (PARTITION BY Month, PersonID ORDER BY CONCAT([Outlet Perfect], '_', Total_KPI, '_', OutletID) DESC) AS STT
			FROM (
					SELECT 
						t1.Month ,case when t1.ZoneID in ('MO6','MO8') then '[MODERN ON TRADE]' else r.BusinessUnitID end BU 
						,r.RegionName Region ,t1.ZoneID
						,t1.SRID AS PersonID, tp.FullName, t1.OutletID, t1.Name
						,t1.SegmentName
						,t1.Tier
						,t1.NND_Actual ,t1.NND_Target ,t1.NND
						,t1.FS_Actual ,t1.FS_Target ,t1.FS
						,t1.VS_Actual ,t1.VS_Target ,t1.VS
						,t1.PrCom_Actual ,t1.PrCom_Target ,t1.PrCom
						,CASE 
							WHEN t1.Month >= '2025-03-01' THEN 
								CASE WHEN ISNULL(t1.NND_Actual,0) >= ISNULL(t1.NND_Target,0)
								   AND ISNULL(t1.FS_Actual,0) >= ISNULL(t1.FS_Target,0)
								   AND ISNULL(t1.VS_Actual,0) >= ISNULL(t1.VS_Target,0)
								   AND ISNULL(t1.PrCom_Actual,0) >= ISNULL(t1.PrCom_Target,0)
								THEN 1 ELSE 0 END
							ELSE 
								CASE WHEN ISNULL(t1.NND_Actual,0) >= ISNULL(t1.NND_Target,0)
								   AND ISNULL(t1.FS_Actual,0) >= ISNULL(t1.FS_Target,0)
								   AND ISNULL(t1.VS_Actual,0) >= ISNULL(t1.VS_Target,0)
								THEN 1 ELSE 0 END
						END AS [Outlet Perfect],
						'SR' AS PersonType,
						CASE 
							WHEN t1.Month >= '2025-03-01' THEN 
								(ISNULL(t1.NND,0) + ISNULL(t1.FS,0) + ISNULL(t1.VS,0) + ISNULL(t1.PrCom,0))
							ELSE 
								(ISNULL(t1.NND,0) + ISNULL(t1.FS,0) + ISNULL(t1.VS,0))
						END AS Total_KPI
					FROM srp.[SRP-EOEAnswerFocusPerformanceAudit_SRP] t1
						left join srp.v_TD_Person tp on tp.PersonID = t1.SRID
						left join [srp].[v_TD_Region_Area] r on t1.ZoneID = r.AreaID and r.Type = 'SEM'
					WHERE t1.ZoneID NOT LIKE '%MF%'
				) s_tbl1
		) s_tbl2
left join srp.[TF_PICOSTarget_GT&MONT] t on t.Month = s_tbl2.Month
) Ranked
	cross join MaxStructureMonth sm
	cross join MaxRankedMonth rm
	left join ValidStructure vs ON Ranked.PersonID = vs.PersonID
WHERE 1=1 
	and STT <= STT_Limit
)



/* By BU

select Month
	,BU 
	,count(distinct OutletID) TotalOutlet
	,sum([Outlet Perfect]) #Outlet_Hit_PICOS
	,CAST(CAST(SUM([Outlet Perfect]) AS decimal(18,2)) / COUNT(DISTINCT OutletID) AS decimal(18,3)) PICOS_Score
	--,'0.8' EOE_Target
	--,CAST((CAST(SUM([Outlet Perfect]) AS decimal(18,2)) / COUNT(DISTINCT OutletID)) / 0.8 AS decimal(18,3)) PICOS_Achieve
from PICOS a
	left join [srp].[v_TD_Region_Area] b on a.ZoneID = b.AreaID and Type = 'SEM'
	where 1=1
		and Month = '2026-03-01'
		and is_SRP = 1
group by Month ,BU 

*/

/* By Region

select Month
	,BU ,Region
	,count(distinct OutletID) TotalOutlet
	,sum([Outlet Perfect]) #Outlet_Hit_PICOS
	,CAST(CAST(SUM([Outlet Perfect]) AS decimal(18,2)) / COUNT(DISTINCT OutletID) AS decimal(18,3)) PICOS_Score
	--,'0.8' PICOS_Target
	--,CAST((CAST(SUM([Outlet Perfect]) AS decimal(18,2)) / COUNT(DISTINCT OutletID)) / 0.8 AS decimal(18,3)) PICOS_Achieve
from PICOS a
	left join [srp].[v_TD_Region_Area] b on a.ZoneID = b.AreaID and Type = 'SEM'
	where 1=1
		and Month = '2026-03-01'
		and is_SRP = 1
group by Month ,BU ,Region
	--,ZoneID, PersonID, FullName

*/

/* By Area

select Month
	,BU
	,Region
	,b.AreaName ZoneName
	--,a.ZoneID
	,count(distinct OutletID) TotalOutlet
	,sum([Outlet Perfect]) #Outlet_Hit_PICOS
	,CAST(CAST(SUM([Outlet Perfect]) AS decimal(18,2)) / COUNT(DISTINCT OutletID) AS decimal(18,3)) PICOS_Score
	--,'0.8' PICOS_Target
	--,CAST((CAST(SUM([Outlet Perfect]) AS decimal(18,2)) / COUNT(DISTINCT OutletID)) / 0.8 AS decimal(18,3)) PICOS_Achieve
from PICOS a
	left join [srp].[v_TD_Region_Area] b on a.ZoneID = b.AreaID and Type = 'SEM'
	where 1=1
		and Month = '2026-03-01'
		and is_SRP = 1
group by Month ,BU ,Region ,b.AreaName , a.ZoneID
order by b.AreaName, Region, BU

*/

/* Sum by Person

select a.Month ,a.BU ,a.Region ,a.ZoneID
	,PersonID,FullName
	--,STT_Limit
	,count(distinct OutletID) TotalOutlet
	,sum(NND) NND
	,sum(FS) FS
	,sum(VS) VS
	,sum(PrCom) PrCom
	,sum([Outlet Perfect]) PICOS_Outlet
	,CAST(SUM([Outlet Perfect]) * 1.0 / NULLIF(COUNT(DISTINCT OutletID), 0) AS DECIMAL(18,3)) as PICOS_Achievement
	--,is_SRP
from PICOS a
	left join [srp].[v_TD_Region_Area] b on a.ZoneID = b.AreaID and Type = 'SEM'
	where 1=1
		and is_SRP = 1
		and Month = '2026-03-01'
		--and a.ZoneID like '%MO%'
		--and PersonID in (80703149)
group by a.Month ,a.BU ,a.Region ,ZoneID, PersonID, FullName,is_SRP --,STT_Limit
--having count(distinct OutletID) < 15
--having CAST(SUM([Outlet Perfect]) * 1.0 / NULLIF(COUNT(DISTINCT OutletID), 0) AS DECIMAL(18,3)) >= 1
order by a.Month ,a.BU ,count(distinct OutletID) desc,sum([Outlet Perfect]) desc
	--, CAST(SUM([Outlet Perfect]) * 1.0 / NULLIF(COUNT(DISTINCT OutletID), 0) AS DECIMAL(18,3)) desc

*/


--/*

select Month,BU,Region,ZoneID,PersonID,FullName,OutletID,Name,SegmentName,Tier,NND_Actual,NND_Target,NND,FS_Actual,FS_Target,FS,VS_Actual,VS_Target,VS,PrCom_Actual,PrCom_Target,PrCom,[Outlet Perfect]
from PICOS
where 1=1
	and Month = '2026-03-01'
	and is_SRP = 1
	--and OutletID = 67702464
	--and BU = 'MODERN ON TRADE'
order by Month


--*/
