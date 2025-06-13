-- Get all payments of all guarantor and their family member (patients) with 90+-day aged balances

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

-- 4. paysplit (payment to procedurelog) with 90+-day aged balances
paysplit_90_plus_days AS (
    SELECT ps.*
    FROM procedurelog_90_plus_days p
        INNER JOIN paysplit ps ON p.ProcNum = ps.ProcNum
)

-- 5. combine all the data: payment, paysplit, procedurelog
SELECT pay.PayNum,
    pay.PayType,
    pay.PayDate,
    pay.PayAmt,
    pay.CheckNum,
    pay.BankBranch,
    pay.PayNote,
    pay.PatNum,
    pay.DepositNum,
    pay.Receipt,
    pay.IsRecurringCC,
    pay.PaymentSource,
    pay.ProcessStatus,
    pay.RecurringChargeDate,
    pay.PaymentStatus,
    pay.IsCcCompleted,
    pay.MerchantFee,
    pay.DateEntry as PaymentDateEntry,
    ps.SplitNum,
    ps.PayNum,
    ps.PayPlanNum,
    ps.IsDiscount,
    ps.DatePay,
    ps.SplitAmt,
    ps.ProvNum as SplitProvNum,
    ps.ClinicNum,
    ps.DateEntry,
    ps.PayPlanDebitType,
    p.ProcNum,
    p.ProcDate,
    p.ProcFee,
    p.ToothNum,
    p.ProcStatus,
    p.ProvNum
FROM procedurelog_90_plus_days p
    INNER JOIN paysplit_90_plus_days ps ON p.ProcNum = ps.ProcNum
    LEFT JOIN payment pay ON ps.PayNum = pay.PayNum
ORDER BY p.PatNum,
    p.ProcDate,
    ps.DatePay;
    