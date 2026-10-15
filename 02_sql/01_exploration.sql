-- =====================================================================================
-- File: 01_exploration.sql
-- Project: Bank Loan Risk Analysis
-- Goal: Preliminary exploration of raw staging data after cleaning
-- =====================================================================================


-- Section A: Preview the raw data

SELECT *
FROM raw.bank_loans_stg;


-- Section B: Count total rows

SELECT
  COUNT(*) AS total_rows
FROM raw.bank_loans_stg;


-- Section C: Check duplicate loan_id values

-- C1) Duplicate loan_id values

SELECT
  loan_id,
  COUNT(*) AS duplicate_count
FROM raw.bank_loans_stg
GROUP BY loan_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, loan_id;

-- C2) Duplicate records based on business key subset

SELECT
  loan_id,
  customer_id,
  loan_amount,
  disbursement_date,
  COUNT(*)
FROM raw.bank_loans_stg
GROUP BY loan_id, customer_id, loan_amount, disbursement_date
HAVING COUNT(*) > 1;


-- Section D: Check missing / blank values by column

SELECT
  COUNT(*) AS total_rows,

  SUM(CASE WHEN loan_id IS NULL OR BTRIM(loan_id) = '' THEN 1 ELSE 0 END) AS missing_loan_id,
  SUM(CASE WHEN customer_id IS NULL OR BTRIM(customer_id) = '' THEN 1 ELSE 0 END) AS missing_customer_id,
  SUM(CASE WHEN application_date IS NULL OR BTRIM(application_date) = '' THEN 1 ELSE 0 END) AS missing_application_date,
  SUM(CASE WHEN approval_date IS NULL OR BTRIM(approval_date) = '' THEN 1 ELSE 0 END) AS missing_approval_date,
  SUM(CASE WHEN disbursement_date IS NULL OR BTRIM(disbursement_date) = '' THEN 1 ELSE 0 END) AS missing_disbursement_date,
  SUM(CASE WHEN due_date IS NULL OR BTRIM(due_date) = '' THEN 1 ELSE 0 END) AS missing_due_date,
  SUM(CASE WHEN branch_code IS NULL OR BTRIM(branch_code) = '' THEN 1 ELSE 0 END) AS missing_branch_code,
  SUM(CASE WHEN branch_name IS NULL OR BTRIM(branch_name) = '' THEN 1 ELSE 0 END) AS missing_branch_name,
  SUM(CASE WHEN region IS NULL OR BTRIM(region) = '' THEN 1 ELSE 0 END) AS missing_region,
  SUM(CASE WHEN product_type IS NULL OR BTRIM(product_type) = '' THEN 1 ELSE 0 END) AS missing_product_type,
  SUM(CASE WHEN loan_amount IS NULL OR BTRIM(loan_amount) = '' THEN 1 ELSE 0 END) AS missing_loan_amount,
  SUM(CASE WHEN interest_rate IS NULL OR BTRIM(interest_rate) = '' THEN 1 ELSE 0 END) AS missing_interest_rate,
  SUM(CASE WHEN term_months IS NULL OR BTRIM(term_months) = '' THEN 1 ELSE 0 END) AS missing_term_months,
  SUM(CASE WHEN annual_income IS NULL OR BTRIM(annual_income) = '' THEN 1 ELSE 0 END) AS missing_annual_income,
  SUM(CASE WHEN employment_status IS NULL OR BTRIM(employment_status) = '' THEN 1 ELSE 0 END) AS missing_employment_status,
  SUM(CASE WHEN credit_score IS NULL OR BTRIM(credit_score) = '' THEN 1 ELSE 0 END) AS missing_credit_score,
  SUM(CASE WHEN debt_to_income_ratio IS NULL OR BTRIM(debt_to_income_ratio) = '' THEN 1 ELSE 0 END) AS missing_debt_to_income_ratio,
  SUM(CASE WHEN collateral_value IS NULL OR BTRIM(collateral_value) = '' THEN 1 ELSE 0 END) AS missing_collateral_value,
  SUM(CASE WHEN delinquent_days IS NULL OR BTRIM(delinquent_days) = '' THEN 1 ELSE 0 END) AS missing_delinquent_days,
  SUM(CASE WHEN loan_status IS NULL OR BTRIM(loan_status) = '' THEN 1 ELSE 0 END) AS missing_loan_status,
  SUM(CASE WHEN default_flag IS NULL OR BTRIM(default_flag) = '' THEN 1 ELSE 0 END) AS missing_default_flag,
  SUM(CASE WHEN purpose IS NULL OR BTRIM(purpose) = '' THEN 1 ELSE 0 END) AS missing_purpose,
  SUM(CASE WHEN risk_grade IS NULL OR BTRIM(risk_grade) = '' THEN 1 ELSE 0 END) AS missing_risk_grade,
  SUM(CASE WHEN channel IS NULL OR BTRIM(channel) = '' THEN 1 ELSE 0 END) AS missing_channel,
  SUM(CASE WHEN officer_id IS NULL OR BTRIM(officer_id) = '' THEN 1 ELSE 0 END) AS missing_officer_id
FROM raw.bank_loans_stg; 


-- Section E: check distinct messy values in categorical columns

-- E1) Distinct region values

SELECT DISTINCT region
FROM raw.bank_loans_stg
ORDER BY region;

-- E2) Distinct product type values

SELECT DISTINCT product_type
FROM raw.bank_loans_stg
ORDER BY product_type;

-- E3) Distinct employment_status values

SELECT DISTINCT employment_status
FROM raw.bank_loans_stg
ORDER BY employment_status;

-- E4) Distinct loan_status values

SELECT DISTINCT loan_status
FROM raw.bank_loans_stg
ORDER BY loan_status;

-- E5) Distict default_flag values

SELECT DISTINCT default_flag
FROM raw.bank_loans_stg
ORDER BY default_flag;

-- E6) Distinct risk_grade values

SELECT DISTINCT risk_grade
FROM raw.bank_loans_stg
ORDER BY risk_grade;

-- E7) Distinct channel values

SELECT DISTINCT channel
FROM raw.bank_loans_stg
ORDER BY channel;


-- Section F: Check numeric fields for invalid characters

-- F1) Sample messy loan_amount values

SELECT DISTINCT loan_amount
FROM raw.bank_loans_stg
WHERE loan_amount IS NOT NULL
  AND BTRIM(loan_amount) <> ''
ORDER BY loan_amount;

--F2) Sample messy interest_rate values

SELECT DISTINCT interest_rate
FROM raw.bank_loans_stg
WHERE interest_rate IS NOT NULL
  AND BTRIM(interest_rate) <> ''
ORDER BY interest_rate;

-- F3) Sample messy annual_income values

SELECT DISTINCT annual_income
FROM raw.bank_loans_stg
WHERE annual_income IS NOT NULL
  AND BTRIM(annual_income) <> ''
ORDER BY annual_income;

-- F4) Invalid credit_score values 

SELECT DISTINCT credit_score
FROM raw.bank_loans_stg
WHERE credit_score IS NOT NULL
  AND BTRIM(credit_score) <> ''
ORDER BY credit_score;

-- F5) Sample messy debt_to_income_ratio values

SELECT DISTINCT debt_to_income_ratio
FROM raw.bank_loans_stg
WHERE debt_to_income_ratio IS NOT NULL
  AND BTRIM(debt_to_income_ratio) <> ''
ORDER BY debt_to_income_ratio;

-- F6) Invalid delinquent_days values

SELECT DISTINCT delinquent_days
FROM raw.bank_loans_stg
WHERE delinquent_days IS NOT NULL
  AND BTRIM(delinquent_days) <> ''
ORDER BY delinquent_days;

-- F7) Invalid term_months values

SELECT DISTINCT term_months
FROM raw.bank_loans_stg
WHERE term_months IS NOT NULL
  AND BTRIM(term_months) <> ''
ORDER BY term_months;


-- Section G: Check date fields and mixed formats

-- G1) Sample application_date values

SELECT DISTINCT application_date
FROM raw.bank_loans_stg
ORDER BY application_date;

-- G2) Sample approval_date values

SELECT DISTINCT approval_date
FROM raw.bank_loans_stg
ORDER BY approval_date;

-- G3) Sample disbursement_date values

SELECT DISTINCT disbursement_date
FROM raw.bank_loans_stg
ORDER BY disbursement_date;

-- G4) Sample due_date values 

SELECT DISTINCT due_date
FROM raw.bank_loans_stg
ORDER BY due_date;
