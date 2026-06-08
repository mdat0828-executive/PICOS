------------MONT------------------
-------------OR-----------------

Declare @CurrentDate Date = GetDate()
Declare @Month Date
Declare @PreMonth Date
Declare @Top int

Set @Month = '2026-03-01'
Set @Top = 40



With #Outlet_SR as
(

Select Cast(tmp.Month as Date) Month, Region = case when Area = 'MO6' then 'MONT Central_North' when Area = 'MO8' then 'MONT South' else Region end
	,Area, 
    RCMID, RCMID_UCE, RCMName, RCM_HeiwayID, ASMID, ASMID_UCE, ASMName, ASM_HeiwayID,
    SSID, SSID_UCE, SSName, SS_HeiwayID, SRID, SRID_UCE, SRName, SR_HeiwayID,
    OutletID, OutletName, Segment, AddLine, WardName, DistrictName, ProvinceName, DemographicID, 
    Longitude, Latitude, Premise, Channel,
    Tier, LeadBrandName, Title, Email, Cast(Phone as varchar(max)) Phone,
    'Priority' = Case 
		When Tier in ('Platinum','Gold','Hot') Then 'Option 1'
        When Tier in ('Silver','Medium') Then 'Option 2'
        When Tier in ('Bronze','Low') Then 'Option 3'
			Else 'Option 4'
    End
	,'Tier_Priority' = Case
		When Tier in ('Platinum','Gold') Then 1
        When Tier in ('Silver') Then 2
        When Tier in ('Bronze') Then 3
        When Tier in ('Hot') Then 4
        When Tier in ('Medium') Then 5
			Else 6
	End
	,'Segment_Priority' = Case 
		When Segment in ('Karaoke','Premium Karaoke') Then 1
		When Segment in ('Young Social') Then 2
		When Segment in ('Bar/Pub','Bar') Then 3
		When Segment in ('Night Club') Then 4
			Else 99
	End
From
	(
		Select 'Month' = @Month
			,o.RegionName Region, o.AreaID Area, 
			p3.SIS_PersonID RCMID, p3.PersonID RCMID_UCE, p3.FullName RCMName, p3.PositionID PosID_RCM, p3.HeiwayID RCM_HeiwayID,
			p2.SIS_PersonID ASMID, p2.PersonID ASMID_UCE, p2.FullName ASMName, p2.PositionID PosID_ASM, p2.HeiwayID ASM_HeiwayID,
			p1.SIS_PersonID SSID, p1.PersonID SSID_UCE, p1.FullName SSName, p1.PositionID PosID_SS, p1.HeiwayID SS_HeiwayID,
			p.SIS_PersonID SRID, p.PersonID SRID_UCE, p.FullName SRName, p.HeiwayID SR_HeiwayID, p.Title Title,
			o.Customer_ID OutletID, o.Customer_Name OutletName, seg.SegmentName Segment,
			o.Customer_Addr AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, o.Longitude, o.Latitude, 
			seg.Premise Premise, seg.Channel Channel, o.Tier, o.LeadBrandName, p.Email Email, p.Phone		
		From [srp].[v_TD_Account] o 
		Join [srp].[SEM-Segment] seg
			On o.OutletTypeID = seg.SEM_SegmentID2
		Left Join (Select * From [srp].[v_TD_Person] p Where FirstName not like '%Mer%') p
			On o.SalesRepID = p.PersonID
		Left Join [srp].[v_TD_Person] p1 On p.ReportToID = p1.PersonID
		Left Join [srp].[v_TD_Person] p2 On p1.ReportToID = p2.PersonID
		Left Join [srp].[v_TD_Person] p3 On p2.ReportToID = p3.PersonID
		where 1 = 1
			and o.closedate is null and o.StateName = 'Active' and o.StatusName = 'Opened' and o.IsReturnTC = 0 
			and o.Customer_ID like '6%'
			and o.OutletTypeID <> 2038
			and p.UserProfile Like '%Sales%'
			and Left(o.RegionID,1) Like '[1-9]'
			and seg.SegmentName in ('Young Social','Premium Karaoke','Karaoke','Bar/Pub','Bar','Night Club')
		and o.AreaID like '%MO%'
		--Remove Outlet KTC liên tục--
		and o.Customer_ID not in (66803625,66810799,66811178,66855843,66856374,66856379,66856381,66857614,66858263,66858264,66808833,66810744,66811140,66811223) /*Đã có mail cf xác nhận từ chị Trinh - Danh sách Nga Spiral gửi ngày 20/05/2026*/
		and o.Tier not in ('Waiting Group')

	) tmp 
), #Outlet_SR_All as
(

Select o.Month,'MODERN ON TRADE' BU, o.Region, o.Area, o.RCMID_UCE, o.RCMName, o.RCM_HeiwayID, o.ASMID_UCE, o.ASMName, o.ASM_HeiwayID, o.SSID_UCE, o.SSName, o.SS_HeiwayID,
	o.SRID_UCE, o.SRName, o.SR_HeiwayID, o.OutletID, o.OutletName, o.Segment, o.AddLine, o.WardName, o.DistrictName, o.ProvinceName, o.DemographicID, 
	o.Longitude, o.Latitude, o.Premise, o.Channel, o.Tier, o.LeadBrandName, o.Title, o.Email, o.Phone, o.Priority, o.Tier_Priority ,o.Segment_Priority
	,ROW_NUMBER() OVER (PARTITION BY Month, o.SRID_UCE ORDER BY o.Segment_Priority asc, o.Tier_Priority, o.OutletID) AS STT
from #Outlet_SR o
Where 1=1
)


select
	 Month
	,BU,Region,Area,RCMID_UCE,RCMName,RCM_HeiwayID,ASMID_UCE,ASMName,ASM_HeiwayID,SSID_UCE,SSName,SS_HeiwayID
	,SRID_UCE,SRName,SR_HeiwayID
	,OutletID,OutletName,Segment,AddLine,WardName,DistrictName,ProvinceName,DemographicID,Longitude,Latitude
	,Premise,Channel,Tier,LeadBrandName,Title,Email,Phone,Priority
	,Segment_Priority
	,Tier_Priority
	,STT
from #Outlet_SR_All
where 1=1
/*Min Outlet per Sales MONT*/
	and STT <= @Top
	--and SRID_UCE = 80706625
order by SRID_UCE
