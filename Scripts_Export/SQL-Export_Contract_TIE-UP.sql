/* ======================= TIE-up IN OSR Systems ===========================*/


SELECT OutletID, StartingDate, CompleteDate , CurrentStatusID,
		CASE 
			--WHEN CurrentStatusID ='-1'THEN 'Draft'
			--WHEN CurrentStatusID ='1' THEN 'Pending SS Approval'
			--WHEN CurrentStatusID ='2' THEN 'Pending SE Approval'
			--WHEN CurrentStatusID ='3' THEN 'Pending'
			--WHEN CurrentStatusID ='4' THEN 'Approved'
			--WHEN CurrentStatusID ='5' THEN 'Waiting for Approval'
			--WHEN CurrentStatusID ='6' THEN 'Pending CD Approval'
			--WHEN CurrentStatusID ='7' THEN 'Pending GD Approval'
			WHEN CurrentStatusID ='10'THEN 'Completed'
			--WHEN CurrentStatusID ='31'THEN 'Pending ASM Approval'
			--WHEN CurrentStatusID ='99'THEN 'Cancel'
			--WHEN CurrentStatusID ='100'THEN 'Terminal' 
			else 'Other' end [Status]
FROM [srp].[v_OSR_Contract]
	WHERE 1=1 AND CurrentStatusID = 10 /*Chỉ filter lấy ID 10 and Status Completed*/
		AND GETDATE() BETWEEN StartingDate AND CompleteDate
		AND LiquidationDate IS NULL
	ORDER BY CompleteDate