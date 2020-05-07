
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
                WHEN status = 'Filed' THEN 'DOB 1: Application filed'
                WHEN status = 'In progress' THEN 'DOB 2: Application in progress'
                ELSE NULL
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
                ELSE NULL
            END
    WHEN source = 'Neighborhood Study Projected Development Sites' AND status = 'Projected Development' THEN 'Potential'
    WHEN source = 'Neighborhood Study Rezoning Commitments' AND status = 'Rezoning Commitment' THEN 'Potential'
    END);