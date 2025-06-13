-- Get all guarantor and their family member (patients) with 90+-day aged balances

-- 1. guarantor with 90+-day aged balances
WITH guarantors AS (
    SELECT PatNum as GuarantorNum
    FROM patient
    WHERE Guarantor = PatNum -- Only Guarantor records have aged family balances.
        AND (
            (HmPhone IS NOT NULL && HmPhone != "") || (WirelessPhone IS NOT NULL && WirelessPhone != "") -- WirelessPhone or HmPhone available
        ) -- AND BalOver90 > 0
)

-- 2. patient with 90+-day aged balances
SELECT p.PatNum,
    p.LName,
    p.FName,
    p.PatStatus,
    p.Gender,
    p.Birthdate,
    p.Address,
    p.Address2,
    p.City,
    p.State,
    p.Zip,
    p.HmPhone,
    p.WkPhone,
    p.WirelessPhone,
    p.Guarantor,
    p.Email,
    p.EstBalance,
    p.BillingType,
    d.ItemName as BillingTypeName,
    p.Bal_0_30,
    p.Bal_31_60,
    p.Bal_61_90,
    p.BalOver90,
    p.InsEst,
    p.BalTotal,
    p.HasIns,
    p.PreferConfirmMethod,
    p.PreferContactMethod,
    p.PreferRecallMethod,
    p.Language,
    p.DateTStamp
FROM patient p
    INNER JOIN guarantors g ON p.Guarantor = g.GuarantorNum
    LEFT JOIN definition d ON d.DefNum = p.BillingType AND d.Category = 4
-- WHERE p.BillingType = 40 -- BillingType: 40 Standard
;
