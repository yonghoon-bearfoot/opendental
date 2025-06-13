-- Get all claimproc of all guarantor and their family member (patients) with 90+-day aged balances

-- 1. guarantor with 90+-day aged balances
WITH guarantors AS (
    SELECT PatNum as GuarantorNum
    FROM patient
    WHERE Guarantor = PatNum -- Only Guarantor records have aged family balances.
        AND (
            (HmPhone IS NOT NULL && HmPhone != "") || (WirelessPhone IS NOT NULL && WirelessPhone != "") -- WirelessPhone or HmPhone available
        )
        -- AND BalOver90 > 0
),

-- 2. patient with 90+-day aged balances
patient_ar_90_plus_days AS (
    SELECT p.*
    FROM patient p
        INNER JOIN guarantors g ON p.Guarantor = g.GuarantorNum
    -- WHERE p.BillingType = 40 -- BillingType: 40 Standard
),

-- 3. procedurelog with 90+-day aged balances
procedurelog_90_plus_days AS (
    SELECT p.PatNum,
        pl.ProcNum,
        pl.ProcDate,
        pl.ProcFee,
        pl.ToothNum,
        pl.ProcStatus,
        pl.ProvNum,
        pl.BillingTypeOne,
        pl.BillingTypeTwo,
        pl.CodeNum,
        pl.UnitQty,
        pl.DateTStamp,
        pl.BillingNote
    FROM patient_ar_90_plus_days p
        INNER JOIN procedurelog pl ON p.PatNum = pl.PatNum
    WHERE pl.ProcFee > 0
    ORDER BY p.PatNum,
        pl.ProcDate
),

-- 4. claimproc (procedure to claim) with 90+-day aged balances
claimproc_90_plus_days AS (
    SELECT cp.*
    FROM procedurelog_90_plus_days p
        INNER JOIN claimproc cp ON p.ProcNum = cp.ProcNum
)

-- 5. combine all the data: claimproc, procedurelog, insplan, carrier
SELECT cp.ClaimProcNum,
    cp.Status,
    cp.FeeBilled,
    cp.InsPayAmt,
    cp.InsPayEst,
    cp.WriteOff,
    cp.WriteOffEst,
    cp.InsEstTotal,
    cp.CopayAmt,
    cp.PaidOtherIns,
    cp.BaseEst,
    cp.DateCP,
    cp.DateEntry,
    p.PatNum,
    p.ProcNum,
    p.ProcDate,
    p.ProcFee,
    p.ToothNum,
    p.ProcStatus,
    p.ProvNum,
    ip.PlanNum,
    ip.GroupName,
    ip.PlanType,
    ip.BillingType,
    c.CarrierNum,
    c.CarrierName
FROM procedurelog_90_plus_days p
    INNER JOIN claimproc_90_plus_days cp ON p.ProcNum = cp.ProcNum
    LEFT JOIN insplan ip ON cp.PlanNum = ip.PlanNum
    LEFT JOIN carrier c ON ip.CarrierNum = c.CarrierNum
ORDER BY p.PatNum,
    p.ProcDate,
    cp.DateCP;
