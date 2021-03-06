-- Non ZAP status
UPDATE kpdb."2020"
SET status = 
    (CASE 
    WHEN source = 'DOB' 
        THEN 
            CASE
                WHEN inactive = '1' THEN 'DOB 9: Application inactive'
                WHEN status = 'Permit issued' THEN 'DOB 3: Construction permit issued'
                WHEN status = 'Partial complete' THEN 'DOB 4: CofO issued for part of building'
                WHEN status = 'In progress (last plan disapproved)' THEN 'DOB 2: Application in progress'
                WHEN status = 'Complete' THEN 'DOB 5: CofO issued for entire building'
                WHEN status = 'Complete (demolition)' THEN 'DOB 0: Building demolished'
                WHEN status = 'Filed' THEN 'DOB 1: Application filed'
                WHEN status = 'In progress' THEN 'DOB 2: Application in progress'
                ELSE status
            END
    WHEN source = 'EDC Projected Projects' AND status = 'Projected' THEN 'Potential'
    WHEN source = 'Empire State Development Projected Projects' AND status = 'Projected' THEN 'Potential'
    WHEN source = 'Future Neighborhood Studies' AND status = 'Projected' THEN 'Potential'
    WHEN source = 'HPD Projected Closings' AND status = 'Projected' THEN 'HPD 3: Projected Closing'
    WHEN source = 'HPD RFPs' 
        THEN 
            CASE
                WHEN status = 'RFP designated; financing closed' THEN 'HPD 4: Financing Closed'
                WHEN status = 'RFP designated; financing not closed' THEN 'HPD 2: RFP Designated'
                WHEN status = 'RFP issued; financing not closed' THEN 'HPD 1: RFP Issued'
                ELSE status
            END
    WHEN source = 'Neighborhood Study Projected Development Sites' AND status = 'Projected Development' THEN 'Potential'
    WHEN source = 'Neighborhood Study Rezoning Commitments' AND status = 'Rezoning Commitment' THEN 'Potential'
    ELSE status
    END);

-- ZAP Status
WITH
zap_status as (select 
	dcp_name as record_id,
	(case
		when dcp_publicstatus ~* 'completed' then 'DCP 4: Zoning Implemented'
		when dcp_projectphase ~* 'project completed' then 'DCP 4: Zoning Implemented'
		when dcp_projectphase ~* 'pre-pas|pre-cert' then 'DCP 2: Application in progress'
		when dcp_projectphase ~* 'initiation' then 'DCP 1: Expression of interest'
		when dcp_projectphase ~* 'public review' then 'DCP 3: Certified/Referred'
	end) status
from dcp_project
where dcp_name in (Select record_id from kpdb."2020"))
update kpdb."2020" a
set status = b.status
from zap_status b
where a.record_id = b.record_id;