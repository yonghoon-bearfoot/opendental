-- Get all procedure logs of all guarantor and their family member (patients) with 90+-day aged balances

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
        pl.BillingNote,
        pc.ProcCode,
        pc.Descript,
        COALESCE(ins.InsPaid, 0) AS InsPaid,
        COALESCE(pat.PatPaid, 0) AS PatPaid,
        pl.ProcFee - COALESCE(ins.InsPaid, 0) - COALESCE(pat.PatPaid, 0) AS BalanceRemaining,
        cp.Status AS ClaimStatus,
        COALESCE(ins.InsPayEst, 0) AS InsPayEst,
        COALESCE(ins.WriteOff, 0) AS WriteOff,
        COALESCE(ins.WriteOffEst, 0) AS WriteOffEst,
        COALESCE(ins.InsEstTotal, 0) AS InsEstTotal,
        COALESCE(ins.CopayAmt, 0) AS CopayAmt,
        COALESCE(ins.PaidOtherIns, 0) AS PaidOtherIns,
        COALESCE(ins.BaseEst, 0) AS BaseEst,
        GROUP_CONCAT(DISTINCT c.CarrierName SEPARATOR ', ') AS InsuranceCompanies
    FROM patient_ar_90_plus_days p
        INNER JOIN procedurelog pl ON p.PatNum = pl.PatNum
        LEFT JOIN procedurecode pc ON pl.CodeNum = pc.CodeNum
        LEFT JOIN (
            SELECT ProcNum,
                SUM(InsPayAmt) AS InsPaid,
                SUM(InsPayEst) AS InsPayEst,
                SUM(WriteOff) AS WriteOff,
                SUM(WriteOffEst) AS WriteOffEst,
                SUM(InsEstTotal) AS InsEstTotal,
                SUM(CopayAmt) AS CopayAmt,
                SUM(PaidOtherIns) AS PaidOtherIns,
                SUM(BaseEst) AS BaseEst
            FROM claimproc
            WHERE Status IN (1, 4, 5, 6) -- Received, Supplemental, CapClaim, CapComplete
            GROUP BY ProcNum
        ) ins ON pl.ProcNum = ins.ProcNum
        LEFT JOIN (
            SELECT ProcNum,
                SUM(SplitAmt) AS PatPaid
            FROM paysplit
            GROUP BY ProcNum
        ) pat ON pl.ProcNum = pat.ProcNum
        LEFT JOIN claimproc cp ON pl.ProcNum = cp.ProcNum
        LEFT JOIN insplan ip ON cp.PlanNum = ip.PlanNum
        LEFT JOIN carrier c ON ip.CarrierNum = c.CarrierNum
    WHERE pl.ProcFee > 0
    GROUP BY p.PatNum,
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
        pl.BillingNote,
        pc.ProcCode,
        pc.Descript,
        ins.InsPaid,
        pat.PatPaid,
        cp.Status,
        ins.InsPayEst,
        ins.WriteOff,
        ins.WriteOffEst,
        ins.InsEstTotal,
        ins.CopayAmt,
        ins.PaidOtherIns,
        ins.BaseEst
    ORDER BY p.PatNum,
        pl.ProcDate
)
SELECT *
FROM procedurelog_90_plus_days;