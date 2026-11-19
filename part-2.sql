SELECT
  default_next_month,
  COUNT(*)                                          AS customers,
  ROUND(AVG(bill_amt1 * 1.0 / limit_bal)::numeric, 2) AS avg_utilization,
  ROUND(AVG(bill_amt1)::numeric, 0)                 AS avg_bill
FROM credit_default
WHERE limit_bal > 0
GROUP BY default_next_month;


SELECT
  CASE WHEN bill_amt1 <= 0                        THEN '0. No balance'
       WHEN bill_amt1 * 1.0 / limit_bal < 0.25    THEN '1. Under 25%'
       WHEN bill_amt1 * 1.0 / limit_bal < 0.50    THEN '2. 25-50%'
       WHEN bill_amt1 * 1.0 / limit_bal < 0.80    THEN '3. 50-80%'
       ELSE '4. 80%+' END                           AS utilization_band,
  COUNT(*)                                          AS customers,
  ROUND(100.0 * SUM(default_next_month) / COUNT(*), 1) AS default_rate_pct
FROM credit_default
WHERE limit_bal > 0
GROUP BY utilization_band
ORDER BY utilization_band;


SELECT
  (pay_1 >= 1)::int + (pay_2 >= 1)::int + (pay_3 >= 1)::int +
  (pay_4 >= 1)::int + (pay_5 >= 1)::int + (pay_6 >= 1)::int   AS late_months_out_of_6,
  COUNT(*)                                          AS customers,
  ROUND(100.0 * SUM(default_next_month) / COUNT(*), 1) AS default_rate_pct
FROM credit_default
GROUP BY late_months_out_of_6
ORDER BY late_months_out_of_6;


SELECT
  CASE WHEN pay_1 >= 1 AND pay_2 >= 1 AND pay_3 >= 1
       THEN 'Late 3 months in a row' ELSE 'Other customers' END AS group_name,
  COUNT(*)                                          AS customers,
  ROUND(100.0 * SUM(default_next_month) / COUNT(*), 1) AS default_rate_pct
FROM credit_default
GROUP BY group_name;


SELECT
  CASE WHEN bill_amt2 <= 0                                       THEN '0. No bill'
       WHEN pay_amt1 * 1.0 / NULLIF(bill_amt2, 0) < 0.05         THEN '1. Paid under 5%'
       WHEN pay_amt1 * 1.0 / NULLIF(bill_amt2, 0) < 0.50         THEN '2. Paid 5-50%'
       WHEN pay_amt1 * 1.0 / NULLIF(bill_amt2, 0) < 1.00         THEN '3. Paid 50-99%'
       ELSE '4. Paid in full' END                   AS payment_band,
  COUNT(*)                                          AS customers,
  ROUND(100.0 * SUM(default_next_month) / COUNT(*), 1) AS default_rate_pct
FROM credit_default
GROUP BY payment_band
ORDER BY payment_band;