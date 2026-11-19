WITH ranked AS (
  SELECT
    default_next_month,
    bill_amt1,
    NTILE(10) OVER (ORDER BY bill_amt1) AS balance_decile
  FROM credit_default
)
SELECT
  balance_decile,
  COUNT(*)                                             AS customers,
  ROUND(AVG(bill_amt1)::numeric, 0)                    AS avg_balance,
  ROUND(100.0 * SUM(default_next_month) / COUNT(*), 1) AS default_rate_pct
FROM ranked
GROUP BY balance_decile
ORDER BY balance_decile DESC;


WITH ranked AS (
  SELECT
    id,
    education,
    bill_amt1,
    limit_bal,
    default_next_month,
    RANK() OVER (PARTITION BY education ORDER BY bill_amt1 DESC) AS rank_in_segment
  FROM credit_default
)
SELECT *
FROM ranked
WHERE rank_in_segment <= 3
ORDER BY education, rank_in_segment;


SELECT
  default_next_month,
  ROUND(AVG(bill_amt6)::numeric, 0) AS month_6_oldest,
  ROUND(AVG(bill_amt5)::numeric, 0) AS month_5,
  ROUND(AVG(bill_amt4)::numeric, 0) AS month_4,
  ROUND(AVG(bill_amt3)::numeric, 0) AS month_3,
  ROUND(AVG(bill_amt2)::numeric, 0) AS month_2,
  ROUND(AVG(bill_amt1)::numeric, 0) AS month_1_latest
FROM credit_default
GROUP BY default_next_month;


WITH tagged AS (
  SELECT
    default_next_month,
    CASE WHEN bill_amt1 * 1.0 / limit_bal >= 0.80 AND pay_1 >= 1
         THEN 'High-risk segment' ELSE 'Rest of portfolio' END AS segment
  FROM credit_default
  WHERE limit_bal > 0
),
overall AS (
  SELECT 1.0 * SUM(default_next_month) / COUNT(*) AS overall_rate FROM tagged
)
SELECT
  t.segment,
  COUNT(*)                                                                AS customers,
  ROUND(100.0 * SUM(t.default_next_month) / COUNT(*), 1)                  AS default_rate_pct,
  ROUND(((1.0 * SUM(t.default_next_month) / COUNT(*)) / o.overall_rate)::numeric, 2) AS lift_vs_overall
FROM tagged t
CROSS JOIN overall o
GROUP BY t.segment, o.overall_rate;



WITH tagged AS (
  SELECT
    default_next_month,
    CASE WHEN bill_amt1 * 1.0 / limit_bal >= 0.80 AND pay_1 >= 1 THEN 1 ELSE 0 END AS in_segment
  FROM credit_default
  WHERE limit_bal > 0
)
SELECT
  ROUND(100.0 * SUM(in_segment) / COUNT(*), 1)                                        AS pct_of_customers_contacted,
  ROUND(100.0 * SUM(CASE WHEN in_segment = 1 AND default_next_month = 1 THEN 1 END)
        / SUM(default_next_month), 1)                                                 AS pct_of_defaulters_reached
FROM tagged;



WITH scored AS (
  SELECT
    default_next_month,
      2 * (pay_1 >= 1)::int
    + 1 * ((  (pay_1 >= 1)::int + (pay_2 >= 1)::int + (pay_3 >= 1)::int
            + (pay_4 >= 1)::int + (pay_5 >= 1)::int + (pay_6 >= 1)::int) >= 3)::int
    + 1 * (bill_amt1 * 1.0 / limit_bal >= 0.80)::int
    + 1 * (bill_amt2 > 0 AND pay_amt1 * 1.0 / NULLIF(bill_amt2, 0) < 0.05)::int   AS risk_score
  FROM credit_default
  WHERE limit_bal > 0
)
SELECT
  CASE WHEN risk_score >= 4 THEN 'High'
       WHEN risk_score >= 2 THEN 'Medium'
       ELSE 'Low' END                                            AS risk_tier,
  COUNT(*)                                                       AS customers,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)             AS pct_of_portfolio,
  ROUND(100.0 * SUM(default_next_month) / COUNT(*), 1)           AS default_rate_pct
FROM scored
GROUP BY risk_tier
ORDER BY default_rate_pct DESC;