-- =====================================================================================
-- File: 04_business_rules.sql
-- Goal: Apply business rules, flag issues, deduplicate exact duplicates, and create
--       the final analysis-ready table
-- =====================================================================================


-- =====================================================================================
-- Section A) Create reviewed table with issue flags
-- Purpose: keep all cleaned rows, but classify data quality / business rule issues
-- =====================================================================================


-- A1) Drop reviewed table if it already exists
DROP TABLE IF EXISTS clean.bank_loans_reviewed;


-- A2) Create reviewed table
CREATE TABLE clean.bank_loans_reviewed AS
SELECT
  bl.*,

  -- Flag 1: imposible timeline issues
  CASE
      WHEN approval_date IS NOT NULL
        AND application_date IS NOT NULL
        AND approval_date < application_date
      THEN 'Yes'

      WHEN disbursement_date IS NOT NULL
        AND approval_date IS NOT NULL
        AND disbursement_date < approval_date
      THEN 'Yes'

      WHEN due_date IS NOT NULL
        AND disbursement_date IS NOT NULL
        AND due_date < disbursement_date
      THEN 'Yes'

      ELSE 'No'
  END AS timeline_issue_flag,

  -- Flag 2: future operational dates
  -- Important: due_date is intentionally excluded because future due dates are valid
  CASE
      WHEN application_date > CURRENT_DATE
        OR approval_date > CURRENT_DATE
        OR disbursement_date > CURRENT_DATE
      THEN 'Yes'
      ELSE 'No'
  END AS future_operational_date_flag,

  -- Flag 3: long approval timeline
  CASE
      WHEN application_date IS NOT NULL
        AND approval_date IS NOT NULL
        AND (approval_date - application_date) > 60
      THEN 'Yes'
      ELSE 'No'
  END AS long_approval_timeline_flag,

  -- Flag 4: low-information rows
  CASE
      WHEN loan_amount IS NULL
        AND annual_income IS NULL
        AND credit_score IS NULL
      THEN 'Yes'
      ELSE 'No'
  END AS low_information_flag,

  -- Flag 5: extreme placeholder rows
  CASE
      WHEN customer_id IS NULL
        AND application_date IS NULL
        AND approval_date IS NULL
        AND disbursement_date IS NULL
        AND loan_amount IS NULL
        AND annual_income IS NULL
        AND credit_score IS NULL
        AND loan_status IS NULL
        AND default_flag IS NULL
      THEN 'Yes'
      ELSE 'No'
  END AS extreme_placeholder_flag,

  -- Flag 6: exact duplicate rows based on business key
  CASE
      WHEN ROW_NUMBER() OVER (
        PARTITION BY loan_id, customer_id, loan_amount, disbursement_date
        ORDER BY raw_row_num
      ) > 1
      THEN 'Yes'
      ELSE 'No'
  END AS exact_duplicate_flag,

  -- Flag 7: unrealistic product-term combinations
  CASE
      WHEN product_type = 'Mortgage'
        AND term_months IN (120, 180, 240, 360)
        THEN 'No'
      
      WHEN product_type = 'Auto Loan'
        AND term_months > 84
        THEN 'Yes'

      WHEN product_type = 'Personal Loan'
        AND term_months > 72
        THEN 'Yes'

      WHEN product_type = 'Credit Builder'
        AND term_months > 36
        THEN 'Yes'

      WHEN product_type = 'SME Loan'
        AND term_months > 240
        THEN 'Yes'
      
      WHEN product_type IS NOT NULL
        AND term_months IS NOT NULL
        THEN 'No'
      
      ELSE 'No'
  END AS term_product_realism_flag,

  -- Flag 8: loan amount quality
  CASE
      WHEN loan_amount IS NULL THEN 'Missing'
      WHEN loan_amount = 0 THEN 'Invalid'
      WHEN loan_amount >= 10000000 THEN 'Outlier'
      ELSE 'Valid'
  END AS loan_amount_quality_flag
FROM clean.bank_loans bl;


-- =====================================================================================
-- Section B) Create exact-deduplicated table
-- Purpose: keep only the first row from each exact duplicate group
-- =====================================================================================

-- B1) Drop deduped table if it already exists
DROP TABLE IF EXISTS clean.bank_loans_deduped;

-- B2) Create deduped table
CREATE TABLE clean.bank_loans_deduped AS 
SELECT *
FROM (
    SELECT
    r.*,
    ROW_NUMBER() OVER (
        PARTITION BY loan_id, customer_id, loan_amount, disbursement_date
        ORDER BY raw_row_num
    ) AS dedupe_rn
    FROM clean.bank_loans_reviewed r
    ) x 
    WHERE dedupe_rn = 1;


-- =====================================================================================
-- Section C) Create final analysis-ready table
-- Purpose: Exclude rows that should not be used for KPIs / portfolio analysis
-- =====================================================================================

-- C1) Drop final table if it already exists
DROP TABLE IF EXISTS analytics.bank_loans_final;

-- C2) Create final table
CREATE TABLE analytics.bank_loans_final AS
SELECT
  raw_row_num,
  loan_id,
  customer_id,
  application_date,
  approval_date,
  disbursement_date,
  due_date,
  branch_code,
  branch_name,
  region,
  product_type,
  loan_amount,
  interest_rate,
  term_months,
  annual_income,
  employment_status,
  credit_score,
  debt_to_income_ratio,
  collateral_value,
  delinquent_days,
  loan_status,
  default_flag,
  purpose,
  risk_grade,
  channel,
  officer_id,

  -- Keep useful audit flags in final table
  long_approval_timeline_flag,
  low_information_flag,
  loan_amount_quality_flag

FROM clean.bank_loans_deduped
WHERE timeline_issue_flag = 'No'
  AND future_operational_date_flag = 'No'
  AND extreme_placeholder_flag = 'No'
  AND term_product_realism_flag = 'No';