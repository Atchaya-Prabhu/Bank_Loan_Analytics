-- =====================================================================================
-- File: 03_validation.sql
-- Goal: Validate cleaned dataset and identify issues
-- Table: clean.bank_loans
-- =====================================================================================


-- A) Row count validation

-- A1) Row count check: raw vs clean

SELECT
  'raw.bank_loans_stg' AS table_name,
  COUNT(*) AS row_count
FROM raw.bank_loans_stg

UNION ALL

SELECT 
  'clean.bank_loans' AS table_name,
  COUNT(*) AS row_count
FROM clean.bank_loans;


-- B) NULL - audit important fields

-- B1) NULL audit for critical columns

SELECT
  COUNT(*) AS total_rows,
  COUNT(*) FILTER(WHERE loan_id IS NULL) AS null_loan_id,
  COUNT(*) FILTER(WHERE customer_id IS NULL) AS null_customer_id,
  COUNT(*) FILTER(WHERE application_date IS NULL) AS null_application_date,
  COUNT(*) FILTER(WHERE approval_date IS NULL) AS null_approval_date,
  COUNT(*) FILTER(WHERE due_date IS NULL) AS null_due_date,
  COUNT(*) FILTER(WHERE product_type IS NULL) AS null_product_type,
  COUNT(*) FILTER(WHERE loan_amount IS NULL) AS null_loan_amount,
  COUNT(*) FILTER(WHERE interest_rate IS NULL) AS null_interest_rate,
  COUNT(*) FILTER(WHERE term_months IS NULL) AS null_term_months,
  COUNT(*) FILTER(WHERE annual_income IS NULL) AS null_annual_income,
  COUNT(*) FILTER(WHERE employment_status IS NULL) AS null_employment_status,
  COUNT(*) FILTER(WHERE credit_score IS NULL) AS null_credit_score,
  COUNT(*) FILTER(WHERE debt_to_income_ratio IS NULL) AS null_debt_to_income_ratio,
  COUNT(*) FILTER(WHERE loan_status IS NULL) AS null_loan_status,
  COUNT(*) FILTER(WHERE default_flag IS NULL) AS null_default_flag
FROM clean.bank_loans;


-- C) Distinct value checks

-- C1) Frequency distribution checks

SELECT
  branch_name,
  COUNT(*) AS row_count
FROM clean.bank_loans
GROUP BY branch_name
ORDER BY row_count DESC, branch_name;

SELECT
  region,
  COUNT(*) AS row_count
FROM clean.bank_loans
GROUP BY region
ORDER BY row_count DESC, region;

SELECT
  product_type,
  COUNT(*) AS row_count
FROM clean.bank_loans
GROUP BY product_type
ORDER BY row_count DESC, product_type;

SELECT
  employment_status,
  COUNT(*) AS row_count
FROM clean.bank_loans
GROUP BY employment_status
ORDER BY row_count DESC, employment_status;

SELECT
  loan_status,
  COUNT(*) AS row_count
FROM clean.bank_loans
GROUP BY loan_status
ORDER BY row_count DESC, loan_status;

SELECT 
  default_flag,
  COUNT(*) AS row_count
FROM clean.bank_loans
GROUP BY default_flag
ORDER BY row_count DESC, default_flag;

SELECT 
  risk_grade,
  COUNT(*) AS row_count
FROM clean.bank_loans
GROUP BY risk_grade
ORDER BY row_count DESC, risk_grade;

SELECT 
  channel,
  COUNT(*) AS row_count
FROM clean.bank_loans
GROUP BY channel
ORDER BY row_count DESC, channel;


-- D) Business logic validation

-- D1) Summary counts for timeline issues

SELECT
  COUNT(*) FILTER(WHERE approval_date < application_date) AS cnt_approval_before_application,
  COUNT(*) FILTER(WHERE disbursement_date < approval_date) AS cnt_disbursement_before_approval,
  COUNT(*) FILTER(WHERE due_date < disbursement_date) AS cnt_due_date_before_disbursement
FROM clean.bank_loans;

-- D2) Invalid timeline: approval before application

SELECT *
FROM clean.bank_loans
WHERE approval_date < application_date;

-- D3) Invalid timeline: disbursement before approval

SELECT *
FROM clean.bank_loans
WHERE disbursement_date < approval_date;

-- D4) Invalid timeline: due date before disbursement

SELECT *
FROM clean.bank_loans
WHERE due_date < disbursement_date;


-- E) Invalid future operational dates

-- E1) Future dates in operational fields

SELECT *
FROM clean.bank_loans
WHERE application_date > CURRENT_DATE
  OR approval_date > CURRENT_DATE
  OR disbursement_date > CURRENT_DATE;

-- E2) Count future-date issues

SELECT
  COUNT(*) FILTER(WHERE application_date > CURRENT_DATE) AS future_application_date,
  COUNT(*) FILTER(WHERE approval_date > CURRENT_DATE) AS future_approval_date,
  COUNT(*) FILTER(WHERE disbursement_date > CURRENT_DATE) AS future_disbursement_date
FROM clean.bank_loans;


-- F) Timeline checks

-- F1) Approval lag in days

SELECT
  loan_id,
  customer_id,
  application_date,
  approval_date,
  (approval_date - application_date) AS approval_days
FROM clean.bank_loans
WHERE application_date IS NOT NULL
  AND approval_date IS NOT NULL
ORDER BY approval_days DESC;

-- F2) Very long approval timelines

SELECT
  loan_id,
  customer_id,
  application_date,
  approval_date,
  (approval_date - application_date) AS approval_days
FROM clean.bank_loans
WHERE application_date IS NOT NULL
  AND approval_date IS NOT NULL
  AND (approval_date - application_date) > 60
ORDER BY approval_days DESC;

-- F3) Disbursement lag after approval

SELECT
  loan_id,
  customer_id,
  approval_date,
  disbursement_date,
  (disbursement_date - approval_date) AS disbursement_days
FROM clean.bank_loans
WHERE approval_date IS NOT NULL
  AND disbursement_date IS NOT NULL
ORDER BY disbursement_days DESC;


-- G) Duplicates

-- G1) Duplicate flag counts

SELECT
  loan_id_duplicate_flag,
  COUNT(*) AS row_count
FROM clean.bank_loans
GROUP BY loan_id_duplicate_flag
ORDER BY row_count DESC;

SELECT
  business_key_duplicate_flag,
  COUNT(*) AS row_count
FROM clean.bank_loans
GROUP BY business_key_duplicate_flag
ORDER BY row_count DESC;

-- G2) Inspect duplicate rows

SELECT *
FROM clean.bank_loans
WHERE loan_id_duplicate_flag = 'duplicate_loan_id'
ORDER BY loan_id, raw_row_num;

-- G3) Group exact duplicate candidates

SELECT
  loan_id,
  customer_id,
  loan_amount,
  disbursement_date,
  COUNT(*) AS duplicate_count
FROM clean.bank_loans
GROUP BY loan_id, customer_id, loan_amount, disbursement_date
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, loan_id;


-- H) Missing data evaluation

-- H1) Rows with multiple critical fields missing

SELECT *
FROM clean.bank_loans
WHERE loan_amount IS NULL
  AND annual_income IS NULL
  AND credit_score IS NULL
ORDER BY raw_row_num;

-- H2) Rows missing core identifiers or dates

SELECT *
FROM clean.bank_loans
WHERE loan_id IS NULL
  OR customer_id IS NULL
  OR application_date IS NULL
ORDER BY raw_row_num;

-- H3) Missing loan amount review

SELECT *
FROM clean.bank_loans
WHERE loan_amount IS NULL
ORDER BY raw_row_num;
