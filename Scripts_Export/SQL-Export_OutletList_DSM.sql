                                                        /* ============================ TRADITIONAL TRADE COVERAGE OUTLET LIST -- DSM -- ============================*/

/*	1. Nếu Tier thuộc Platinum và Gold thì đưa vào Option 1 
	2. Ngược lại nếu là Silver thì ranking cột Actualhec lấy top 30 cao nhất cho Option 1 và 60 kết tiếp là Option 3 còn lại option 4 
	3. Tương tự cho Bronze như Silver
*/

/*========================================================
    KHAI BÁO BIẾN THỜI GIAN
========================================================*/

DECLARE @CurrentDate DATE = GETDATE();
DECLARE @Month DATE;
DECLARE @PreMonth DATE;

DECLARE @ToMonth DATE;
DECLARE @FromMonth DATE;
DECLARE @number INT = 3; --- Số tháng cần lấy

SET @FromMonth =
    DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDate) - @number, 0);

SET @ToMonth =
    DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDate), 0);


/*
    @Month:
    Tháng chạy report
*/
SET @Month = '2026-06-01';


/*
    @PreMonth:
    Lấy ngày đầu tháng trước
*/
SET @PreMonth =
    DATEADD
    (
        MM,
        DATEDIFF(MM, 0, DATEADD(MM, -1, @CurrentDate)),
        0
    );



/*========================================================
    CTE #Outlet_DSM
========================================================*/

WITH #Outlet_DSM AS
(
    SELECT
        CAST(tmp.Month AS DATE) AS Month,

        Region,
        Area,

        RCMID,
        RCMID_UCE,
        RCMName,
        RCM_HeiwayID,

        ASMID,
        ASMID_UCE,
        ASMName,
        ASM_HeiwayID,

        SSID,
        SSID_UCE,
        SSName,
        SS_HeiwayID,

        SRID,
        SRID_UCE,
        SRName,
        SR_HeiwayID,

        OutletID,
        OutletName,

        Segment,

        AddLine,
        WardName,
        DistrictName,
        ProvinceName,

        DemographicID,
        Longitude,
        Latitude,

        Premise,
        Channel,

        Tier,
        LeadBrandName,

        'DSM' AS Title,

        Email,

        CAST(Phone AS VARCHAR(MAX)) AS Phone

    FROM
    (
        SELECT
            'Month' = @Month,

            o.RegionName AS Region,
            o.AreaID     AS Area,

            p3.SIS_PersonID AS RCMID,
            p3.PersonID     AS RCMID_UCE,
            p3.FullName     AS RCMName,
            p3.HeiwayID     AS RCM_HeiwayID,

            p2.SIS_PersonID AS ASMID,
            p2.PersonID     AS ASMID_UCE,
            p2.FullName     AS ASMName,
            p2.HeiwayID     AS ASM_HeiwayID,

            p1.SIS_PersonID AS SSID,
            p1.PersonID     AS SSID_UCE,
            p1.FullName     AS SSName,
            p1.HeiwayID     AS SS_HeiwayID,

            p.SIS_PersonID AS SRID,
            p.PersonID     AS SRID_UCE,
            p.FullName     AS SRName,
            p.HeiwayID     AS SR_HeiwayID,
            p.Title        AS Title,

            o.Customer_ID   AS OutletID,
            o.Customer_Name AS OutletName,

            seg.SegmentName AS Segment,

            o.Customer_Addr AS AddLine,
            o.WardName,
            o.DistrictName,
            o.ProvinceName,

            o.DemographicID,
            o.Longitude,
            o.Latitude,

            seg.Premise,
            seg.Channel,

            o.Tier,
            o.LeadBrandName,

            p.Email,
            p.Phone

        FROM [srp].[v_TD_Account] o

        JOIN [srp].[SEM-Segment] seg
            ON o.OutletTypeID = seg.SEM_SegmentID2

        LEFT JOIN
        (
            SELECT *
            FROM [srp].[v_TD_Person]
            WHERE FirstName NOT LIKE '%Mer%'
        ) p
            ON o.SalesRepID = p.PersonID

        LEFT JOIN [srp].[v_TD_Person] p1
            ON p.ReportToID = p1.PersonID

        LEFT JOIN [srp].[v_TD_Person] p2
            ON p1.ReportToID = p2.PersonID

        LEFT JOIN [srp].[v_TD_Person] p3
            ON p2.ReportToID = p3.PersonID

        WHERE 1 = 1

            AND o.closedate IS NULL
            AND o.StateName = 'Active'
            AND o.StatusName = 'Opened'

            AND o.IsReturnTC = 0

            AND o.Customer_ID LIKE '6%'

            AND o.OutletTypeID <> 2038

            AND p.UserProfile LIKE '%DSM%'

            AND LEFT(o.RegionID, 1) LIKE '[1-9]'

            AND seg.SegmentName IN
            (
                'Grocery Store',
                'Beverage Retail Store',
                'Grocery Store with Home Delivery',

                'Quan Nhau Mainstream',
                'Quan Nhau Economy',
                'Quan Nhau Top',
                'Group Social',

                'Young Social',
                'Karaoke',
                'Premium Karaoke'
            )

            AND o.AreaID NOT LIKE '%MO%'

            AND o.Tier NOT IN ('Waiting Group')

    ) tmp
)



/*========================================================
    SALES VOLUME
========================================================*/

, #Outlet_Volume AS
(
    SELECT
        OutletID,

        SUM(Quantity) AS Quantity,
        SUM(ActualHec) AS ActualHec

    FROM
    (
        SELECT
            DATEADD(MONTH, DATEDIFF(MONTH, 0, PostingDate), 0) AS Month,

            OutletID,

            Quantity,
            Volume,

            Quantity * Volume AS ActualHec

        FROM [srp].[v_TF_SalesOut_ByMonth]

        WHERE 1 = 1

            AND DATEADD(MONTH, DATEDIFF(MONTH, 0, PostingDate), 0)
                BETWEEN @FromMonth AND @ToMonth

    ) a

    GROUP BY OutletID
)



/*========================================================
    RANKING SILVER + BRONZE
========================================================*/

, #Outlet_Ranking AS
(
    SELECT
        o.Month,
        o.SRID_UCE,
        o.OutletID,
        o.Tier,

        ISNULL(v.ActualHec, 0) AS ActualHec,

        DENSE_RANK() OVER
        (
            PARTITION BY o.Month, o.SRID_UCE, o.Tier
            ORDER BY ISNULL(v.ActualHec, 0) DESC
        ) AS STT

    FROM #Outlet_DSM o

    LEFT JOIN #Outlet_Volume v
        ON o.OutletID = v.OutletID

    WHERE o.Tier IN ('Silver', 'Bronze')
)



/*========================================================
    FULL OUTLET COVERAGE
========================================================*/

, #Full_Outlet_DSM AS
(
    SELECT
        o.Month,

        REPLACE(REPLACE(r.BusinessUnitID, '[', ''), ']', '') AS BU,

        o.Region,
        o.Area,

        o.RCMID_UCE,
        o.RCMName,
        o.RCM_HeiwayID,

        o.ASMID_UCE,
        o.ASMName,
        o.ASM_HeiwayID,

        o.SSID_UCE,
        o.SSName,
        o.SS_HeiwayID,

        o.SRID_UCE,
        o.SRName,
        o.SR_HeiwayID,

        o.OutletID,
        o.OutletName,

        o.Segment,

        o.AddLine,
        o.WardName,
        o.DistrictName,
        o.ProvinceName,

        o.DemographicID,
        o.Longitude,
        o.Latitude,

        o.Premise,
        o.Channel,

        o.Tier,
        o.LeadBrandName,

        o.Title,
        o.Email,
        o.Phone,

        /*============================================
            PRIORITY LOGIC MỚI
        ============================================*/
        CASE

            /*==============================
                Platinum + Gold
            ==============================*/
            WHEN o.Tier IN ('Platinum', 'Gold')
                THEN 'Option 1'


            /*==============================
                Silver
            ==============================*/
            WHEN o.Tier = 'Silver'
                 AND rk.STT <= 30
                THEN 'Option 1'

            WHEN o.Tier = 'Silver'
                 AND rk.STT BETWEEN 31 AND 90
                THEN 'Option 2'

            WHEN o.Tier = 'Silver'
                THEN 'Option 3'


            /*==============================
                Bronze
            ==============================*/
            WHEN o.Tier = 'Bronze'
                 AND rk.STT <= 30
                THEN 'Option 1'

            WHEN o.Tier = 'Bronze'
                 AND rk.STT BETWEEN 31 AND 90
                THEN 'Option 2'

            WHEN o.Tier = 'Bronze'
                THEN 'Option 3'


            ELSE 'Option 4'

        END AS Priority,

        ISNULL(v.ActualHec, 0) AS ActualHec

    FROM #Outlet_DSM o

    LEFT JOIN [srp].[v_TD_Region_Area] r
        ON o.Area = r.AreaID

    LEFT JOIN #Outlet_Volume v
        ON o.OutletID = v.OutletID

    LEFT JOIN #Outlet_Ranking rk
        ON o.Month = rk.Month
       AND o.SRID_UCE = rk.SRID_UCE
       AND o.OutletID = rk.OutletID
       AND o.Tier = rk.Tier
)



/*========================================================
    FINAL RESULT
========================================================*/

SELECT
     Month
    ,BU

    ,Region
    ,Area

    ,RCMID_UCE
    ,RCMName
    ,RCM_HeiwayID

    ,ASMID_UCE
    ,ASMName
    ,ASM_HeiwayID

    ,SSID_UCE
    ,SSName
    ,SS_HeiwayID

    ,SRID_UCE
    ,SRName
    ,SR_HeiwayID

    ,OutletID
    ,OutletName

    ,Segment

    ,AddLine
    ,WardName
    ,DistrictName
    ,ProvinceName

    ,DemographicID
    ,Longitude
    ,Latitude

    ,Premise
    ,Channel

    ,Tier
    ,LeadBrandName

    ,Title
    ,Email
    ,Phone

    ,[Priority]
    ,ActualHec

FROM #Full_Outlet_DSM

WHERE 1 = 1

ORDER BY
    SRID_UCE,
    Area,
    Region,
    BU;