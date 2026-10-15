-- =====================================================================================
-- File: 05_validation_business_rules.sql
-- Goal: Measure reviewed, deduped, and final row counts
-- =====================================================================================

-- A1) Row counts by layer
SELECT 
  'clean.bank_loans' AS table_name,
  COUNT(*) AS row_count
FROM clean.bank_loans

UNION ALL

SELECT
  'clean.bank_loans_reviewed' AS table_name,
  COUNT(*) AS row_count
FROM clean.bank_loans_reviewed

UNION ALL

SELECT
  'clean.bank_loans_deduped' AS table_name,
  COUNT(*) AS row_count
FROM clean.bank_loans_deduped

UNION ALL

SELECT
  'analytics.bank_loans_final' AS table_name,
  COUNT(*) AS row_count
FROM analytics.bank_loans_final;


-- A2) Reviewed flag summary
SELECT
  COUNT(*) FILTER(WHERE timeline_issue_flag = 'Yes') AS timeline_issue_rows,
  COUNT(*) FILTER(WHERE future_operational_date_flag = 'Yes') AS future_operational_rows,
  COUNT(*) FILTER(WHERE long_approval_timeline_flag = 'Yes') AS long_approval_rows,
  COUNT(*) FILTER(WHERE low_information_flag = 'Yes') AS low_information_rows,
  COUNT(*) FILTER(WHERE extreme_placeholder_flag = 'Yes') AS extreme_placeholder_rows,
  COUNT(*) FILTER(WHERE exact_duplicate_flag = 'Yes') AS exact_duplicates_rows,
  COUNT(*) FILTER(WHERE term_product_realism_flag = 'Yes') AS term_product_realism_rows
FROM clean.bank_loans_reviewed;

-- A3) Rows removed by deduplication
SELECT
  COUNT(*) AS removed_exact_duplicate_rows
FROM clean.bank_loans_reviewed
WHERE exact_duplicate_flag = 'Yes';

-- A4) Rows excluded from final layer
SELECT
  COUNT(*) FILTER(WHERE timeline_issue_flag = 'Yes') AS timeline_issue_rows,
  COUNT(*) FILTER(WHERE future_operational_date_flag = 'Yes') AS future_operational_rows,
  COUNT(*) FILTER(WHERE extreme_placeholder_flag = 'Yes') AS extreme_placeholder_rows,
  COUNT(*) FILTER(WHERE term_product_realism_flag = 'Yes') AS term_product_realism_rows
FROM clean.bank_loans_deduped;

-- A5) Final table quick null audit
SELECT
  COUNT(*) AS total_rows,
  COUNT(*) FILTER(WHERE loan_id IS NULL) AS null_loan_id,
  COUNT(*) FILTER(WHERE customer_id IS NULL) AS null_customer_id,
  COUNT(*) FILTER(WHERE application_date IS NULL) AS null_application_date,
  COUNT(*) FILTER(WHERE loan_amount IS NULL) AS null_loan_amount,
  COUNT(*) FILTER(WHERE annual_income IS NULL) AS null_annual_income,
  COUNT(*) FILTER(WHERE credit_score IS NULL) AS null_credit_score
FROM analytics.bank_loans_final;