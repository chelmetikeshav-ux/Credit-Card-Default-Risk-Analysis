SELECT
  COUNT(*)                                              AS customers,
  SUM(default_next_month)                               AS defaulters,
  ROUND(100.0 * SUM(default_next_month) / COUNT(*), 1)  AS default_rate_pct,
  ROUND(AVG(limit_bal)::numeric, 0)                     AS avg_credit_limit
FROM credit_default;



SELECT
  CASE WHEN age < 25 THEN '1. Under 25'
       WHEN age BETWEEN 25 AND 34 THEN '2. 25-34'
       WHEN age BETWEEN 35 AND 44 THEN '3. 35-44'
       WHEN age BETWEEN 45 AND 54 THEN '4. 45-54'
       ELSE '5. 55+' END                                AS age_band,
  COUNT(*)                                              AS customers,
  ROUND(100.0 * SUM(default_next_month) / COUNT(*), 1)  AS default_rate_pct
FROM credit_default
GROUP BY age_band
ORDER BY age_band;





SELECT
  CASE WHEN limit_bal < 50000  THEN '1. Under 50K'
       WHEN limit_bal < 100000 THEN '2. 50K-100K'
       WHEN limit_bal < 200000 THEN '3. 100K-200K'
       ELSE '4. 200K+' END                              AS limit_band,
  COUNT(*)                                              AS customers,
  ROUND(100.0 * SUM(default_next_month) / COUNT(*), 1)  AS default_rate_pct
FROM credit_default
GROUP BY limit_band
ORDER BY limit_band;


SELECT
  e.education_label,
  m.marriage_label,
  COUNT(*)                                                  AS customers,
  ROUND(100.0 * SUM(c.default_next_month) / COUNT(*), 1)    AS default_rate_pct
FROM credit_default c
JOIN education_lookup e ON c.education = e.education
JOIN marriage_lookup  m ON c.marriage  = m.marriage
GROUP BY e.education_label, m.marriage_label
HAVING COUNT(*) >= 100
ORDER BY default_rate_pct DESC;