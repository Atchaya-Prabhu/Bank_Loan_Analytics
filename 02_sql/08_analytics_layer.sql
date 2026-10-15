-- =====================================================================================
-- File: 08_analytics_layer.sql
-- Goal: Answer business questions and generate ad hoc analytical outputs
-- from the loan portfolio star-schema
-- =====================================================================================


-- =====================================================================================
-- Section A) Join validation and model readiness
-- Purpose: Confirm that fact-to-dimension joins are complete before analysis
-- =====================================================================================

-- A1) Validate product join completeness
SELECT
  COUNT(*) AS total_fact_rows,
  COUNT(p.product_type) AS matched_product_rows
FROM analytics.fact_loans f
LEFT JOIN analytics.dim_product p
  ON f.product_type = p.product_type;

-- A2) Validate branch join completeness
SELECT
  COUNT(*) AS total_fact_rows,
  COUNT(b.branch_code) AS matched_branch_rows
FROM analytics.fact_loans f
LEFT JOIN analytics.dim_branch b
  ON f.branch_code = b.branch_code;

-- A3) Validate disbursement-date join completeness
SELECT
  COUNT(*) AS total_fact_rows,
  COUNT(d.date) AS matched_disbursement_rows
FROM analytics.fact_loans f
LEFT JOIN analytics.dim_date d
  ON f.disbursement_date = d.date;

-- A4) Count null branch keys in fact table
SELECT
  COUNT(*) AS null_branch_code_rows
FROM analytics.fact_loans
WHERE branch_code IS NULL; 

-- A5) Count null disbursement dates keys in fact table
SELECT
  COUNT(*) AS null_disbursement_date_rows
FROM analytics.fact_loans
WHERE disbursement_date IS NULL;

-- A6) Preview joined loan sample with business context
SELECT
  f.loan_id,
  f.loan_amount,
  f.loan_status,
  f.default_flag,
  p.product_type,
  b.branch_name,
  b.region,
  d.year,
  d.month_name
FROM analytics.fact_loans f
JOIN analytics.dim_product p
  ON f.product_type = p.product_type
JOIN analytics.dim_branch b
  ON f.branch_code = b.branch_code
JOIN analytics.dim_date d
  ON f.disbursement_date = d.date
WHERE f.loan_amount_quality_flag = 'Valid'
ORDER BY f.loan_amount DESC
LIMIT 20;

-- =====================================================================================
-- Section B) Portfolio overview KPIs
-- Purpose: Understand the overall size and composition of the loan portfolio
-- =====================================================================================

-- B1) Core portfolio KPIs (Valid loan amounts only)
SELECT
  COUNT(*) AS total_loans,
  ROUND(SUM(loan_amount), 2) AS total_loan_amount,
  ROUND(AVG(loan_amount), 2) AS avg_loan_amount,
  ROUND(MIN(loan_amount), 2) AS min_loan_amount,
  ROUND(MAX(loan_amount), 2) AS max_loan_amount
FROM analytics.fact_loans
WHERE loan_amount_quality_flag = 'Valid';

-- B2) Loan status distribution
SELECT
  loan_status,
  COUNT(*) AS loan_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_portfolio
FROM analytics.fact_loans
GROUP BY loan_status
ORDER BY loan_count DESC;

-- B3) Default flag distribution
SELECT
  default_flag,
  COUNT(*) AS loan_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_portfolio
FROM analytics.fact_loans
GROUP BY default_flag
ORDER BY loan_count DESC;

-- B4) Overall default rate
SELECT
  COUNT(*) AS total_loans,
  SUM(CASE WHEN default_flag = 'Yes' THEN 1 ELSE 0 END) AS defaulted_loans,
  ROUND(
    100.0 * SUM(CASE WHEN default_flag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
    2
  ) AS default_rate_pct
FROM analytics.fact_loans;

-- B5) Loan amount quality monitoring
SELECT
  loan_amount_quality_flag,
  COUNT(*) AS loan_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_portfolio
FROM analytics.fact_loans
GROUP BY loan_amount_quality_flag
ORDER BY loan_count DESC;

-- =====================================================================================
-- Section C) Product analysis
-- Purpose: Measure exposure, performance, and risk by loan product
-- =====================================================================================

-- C1) Portfolio size by product
SELECT
  p.product_type,
  COUNT(*) AS total_loans,
  ROUND(SUM(f.loan_amount), 2) AS total_loan_amount,
  ROUND(AVG(loan_amount), 2) AS avg_loan_amount
FROM analytics.fact_loans f
JOIN analytics.dim_product p
  ON f.product_type = p.product_type
WHERE f.loan_amount_quality_flag = 'Valid'
GROUP BY p.product_type
ORDER BY total_loan_amount DESC;

-- C2) Default rate by product
SELECT
  p.product_type,
  COUNT(*) AS total_loans,
  SUM(CASE WHEN f.default_flag = 'Yes' THEN 1 ELSE 0 END) AS defaulted_loans,
  ROUND(
    100.0 * SUM(CASE WHEN f.default_flag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
    2
  ) AS default_rate_pct
FROM analytics.fact_loans f
JOIN analytics.dim_product p
  ON f.product_type = p.product_type
GROUP BY p.product_type
ORDER BY default_rate_pct DESC, total_loans DESC;

-- C3) Delinquency by product
SELECT
  p.product_type,
  ROUND(AVG(f.delinquent_days), 2) AS avg_delinquent_days,
  ROUND(MAX(f.delinquent_days), 2) AS max_delinquent_days
FROM analytics.fact_loans f
JOIN analytics.dim_product p
  ON f.product_type = p.product_type
GROUP BY p.product_type
ORDER BY avg_delinquent_days DESC;

-- C4) Average borrower credit profile by product
SELECT
  p.product_type,
  ROUND(AVG(f.credit_score), 2) AS avg_credit_score,
  ROUND(AVG(f.debt_to_income_ratio), 2) AS avg_debt_to_income_ratio,
  ROUND(AVG(f.annual_income), 2) AS avg_annual_income
FROM analytics.fact_loans f
JOIN analytics.dim_product p
  ON f.product_type = p.product_type
GROUP BY p.product_type
ORDER BY avg_credit_score DESC;

-- =====================================================================================
-- Section D) Branch and regional analysis
-- Goal: Compare branch-level portfolio size, quality, and risk patterns
-- =====================================================================================

-- D1) Portfolio size by branch
SELECT
  b.branch_code,
  b.branch_name,
  b.region,
  ROUND(SUM(f.loan_amount), 2) AS total_loan_amount,
  ROUND(AVG(f.loan_amount), 2) AS avg_loan_amount 
FROM analytics.fact_loans f
JOIN analytics.dim_branch b
  ON f.branch_code = b.branch_code
WHERE f.loan_amount_quality_flag = 'Valid'
GROUP BY b.branch_code, b.branch_name, b.region
ORDER BY total_loan_amount DESC;

-- D2) Default rate by branch
SELECT
  b.branch_code,
  b.branch_name,
  b.region,
  COUNT(*) AS total_loans,
  SUM(CASE WHEN f.default_flag = 'Yes' THEN 1 ELSE 0 END) AS defaulted_loans,
  ROUND(
    100.0 * SUM(CASE WHEN f.default_flag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
    2
  ) AS default_rate_pct
FROM analytics.fact_loans f
JOIN analytics.dim_branch b
  ON f.branch_code = b.branch_code
GROUP BY b.branch_code, b.branch_name, b.region
ORDER BY default_rate_pct DESC, total_loans DESC;

-- D3) Regional performance summary
SELECT
  b.region,
  COUNT(*) AS total_loans,
  ROUND(SUM(f.loan_amount), 2) AS total_loan_amount,
  ROUND(AVG(f.loan_amount), 2) AS avg_loan_amount,
  ROUND(
    100.0 * SUM(CASE WHEN f.default_flag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
    2
  ) AS default_rate_pct
FROM analytics.fact_loans f
JOIN analytics.dim_branch b
  ON f.branch_code = b.branch_code
WHERE f.loan_amount_quality_flag = 'Valid'
GROUP BY b.region
ORDER BY total_loan_amount DESC;

-- =====================================================================================
-- Section E) Time trend analysis
-- Purpose: Analyze portfolio growth and risk trends over time using the date dimension
-- =====================================================================================

-- E1) Monthly disbursement trend
SELECT
  d.year,
  d.month,
  d.year_month,
  COUNT(*) AS total_loans,
  ROUND(SUM(f.loan_amount), 2) AS total_loan_amount
FROM analytics.fact_loans f
JOIN analytics.dim_date d
  ON f.disbursement_date = d.date
WHERE f.loan_amount_quality_flag = 'Valid'
GROUP BY d.year, d.month, d.year_month
ORDER BY d.year, d.month;

-- E2) Monthly default trend by disbursement month
SELECT
  d.year,
  d.month,
  d.year_month,
  COUNT(*) AS total_loans,
  SUM(CASE WHEN f.default_flag = 'Yes' THEN 1 ELSE 0 END) AS defaulted_loans,
  ROUND(
    100.0 * SUM(CASE WHEN f.default_flag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
    2
) AS default_rate_pct
FROM analytics.fact_loans f
JOIN analytics.dim_date d
  ON f.disbursement_date = d.date
GROUP BY d.year, d.month, d.year_month
ORDER BY d.year, d.month;

-- E3) Quarterly portfolio trend
SELECT
  d.year,
  d.quarter,
  COUNT(*) AS total_loans,
  ROUND(SUM(f.loan_amount), 2) AS total_loan_amount,
  ROUND(AVG(f.loan_amount), 2) AS avg_loan_amount
FROM analytics.fact_loans f
JOIN analytics.dim_date d
  ON f.disbursement_date = d.date
WHERE f.loan_amount_quality_flag = 'Valid'
GROUP BY d.year, d.quarter
ORDER BY d.year, d.quarter;

-- =====================================================================================
-- Section F) Risk and borrower quality analysis
-- Purpose: Evaluate borrower strength and portfolio risk characteristics
-- =====================================================================================

-- F1) Default rate by risk grade
SELECT
  risk_grade,
  COUNT(*) AS total_loans,
  SUM(CASE WHEN default_flag = 'Yes' THEN 1 ELSE 0 END) AS defaulted_loans,
  ROUND(
    100.0 * SUM(CASE WHEN default_flag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
    2
  ) AS default_rate_pct
FROM analytics.fact_loans
GROUP BY risk_grade
ORDER BY default_rate_pct DESC, total_loans DESC;

-- F2) Credit score profile by loan status
SELECT
  loan_status,
  COUNT(*) AS total_loans,
  ROUND(AVG(credit_score), 2) AS avg_credit_score,
  ROUND(AVG(debt_to_income_ratio), 2) AS avg_debt_to_income_ratio,
  ROUND(AVG(annual_income), 2) AS avg_annual_income
FROM analytics.fact_loans
GROUP BY loan_status
ORDER BY avg_credit_score DESC;

-- F3) High-risk exposure summary
SELECT
  COUNT(*) AS total_loans,
  ROUND(SUM(loan_amount), 2) AS total_exposure,
  ROUND(AVG(credit_score), 2) AS avg_credit_score,
  ROUND(AVG(debt_to_income_ratio), 2) AS avg_debt_to_income_ratio
FROM analytics.fact_loans
WHERE loan_amount_quality_flag = 'Valid'
  AND (
    default_flag = 'Yes'
    OR loan_status IN ('Late', 'Charged Off', 'Default')
  );

-- =====================================================================================
-- Section G) Operational and quality monitoring
-- Purpose: Track operational flags retained in the trusted fact table
-- =====================================================================================

-- G1) Long approval timeline monitoring
SELECT
  long_approval_timeline_flag,
  COUNT(*) AS loan_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_portfolio
FROM analytics.fact_loans
GROUP BY long_approval_timeline_flag
ORDER BY loan_count DESC;

-- G2) Low information row monitoring
SELECT
  low_information_flag,
  COUNT(*) AS loan_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_portfolio
FROM analytics.fact_loans
GROUP BY low_information_flag
ORDER BY loan_count DESC;

-- Approval-timeline impact on default performance
SELECT
  long_approval_timeline_flag,
  COUNT(*) AS loan_count,
  SUM(CASE WHEN default_flag = 'Yes' THEN 1 ELSE 0 END) AS defaulted_loans,
  ROUND(
    100.0 * SUM(CASE WHEN default_flag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
    2
  ) AS default_rate_pct
FROM analytics.fact_loans
GROUP BY long_approval_timeline_flag
ORDER BY default_rate_pct DESC;
