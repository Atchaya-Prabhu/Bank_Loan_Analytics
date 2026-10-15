-- =====================================================================================
-- File: 07_validation_data_modeling.sql
-- Goal: Validate star-schema modeling tables
-- =====================================================================================


-- =====================================================================================
-- Section A) Validate analytics.dim_date
-- =====================================================================================


-- A1) Check table exists and preview rows
SELECT *
FROM analytics.dim_date
ORDER BY date
LIMIT 20;

-- A2) Check row count
SELECT
  COUNT(*) AS dim_date_row_count
FROM analytics.dim_date;

-- A3) Check min and max date
SELECT
  MIN(date) AS min_date,
  MAX(date) AS max_date
FROM analytics.dim_date;

-- A4) Check for duplicate dates
SELECT
  date,
  COUNT(*) AS row_count
FROM analytics.dim_date
GROUP BY date
HAVING COUNT(*) > 1;

-- A5) Check for null dates
SELECT
  COUNT(*) AS null_date_rows
FROM analytics.dim_date
WHERE date IS NULL;


-- =====================================================================================
-- Section B) Validate analytics.dim_branch
-- =====================================================================================


-- B1) Check table exists and preview rows
SELECT *
FROM analytics.dim_branch;

-- B2) Check row count
SELECT
  COUNT(*) AS dim_branch_row_count
FROM analytics.dim_branch;

-- B3) Check for duplicates
SELECT
  branch_code,
  COUNT(*) AS row_count
FROM analytics.dim_branch
GROUP BY branch_code
HAVING COUNT(*) > 1;

-- B4) Check for nulls
SELECT
  COUNT(*) AS null_branch_code
FROM analytics.dim_branch
WHERE branch_code IS NULL;

-- B5) Reconciliation check
SELECT
  (SELECT COUNT(DISTINCT branch_code)
   FROM analytics.bank_loans_final) AS fact_distinct_branch_code,

  (SELECT COUNT(*)
   FROM analytics.dim_branch) AS dim_branch_rows;


-- =====================================================================================
-- Section C) Validate analytics.dim_product
-- =====================================================================================

-- C1) Check table exists and preview rows
SELECT *
FROM analytics.dim_product;

-- C2) Check row count
SELECT
  COUNT(*) AS dim_product_row_count
FROM analytics.dim_product;

-- C3) Check for duplicates
SELECT
  product_type,
  COUNT(*) AS row_count
FROM analytics.dim_product
GROUP BY product_type
HAVING COUNT(*) > 1;

-- C4) Check for nulls
SELECT
  COUNT(*) AS null_product_type
FROM analytics.dim_product
WHERE product_type IS NULL;

-- C5) Reconciliation check
SELECT
  (SELECT COUNT(DISTINCT product_type)
   FROM analytics.bank_loans_final) AS fact_distinct_product_type,

   (SELECT COUNT(*)
    FROM analytics.dim_product) AS dim_product_rows;


-- =====================================================================================
-- Section D) Validate analytics.fact_loans
-- =====================================================================================


-- D1) Check table exists and preview rows
SELECT *
FROM analytics.fact_loans
LIMIT 20;

-- D2) Check row count
SELECT
  COUNT(*) AS fact_loans_row_count
FROM analytics.fact_loans;

-- D3) Check for duplicate loan_id values
SELECT
  loan_id,
  COUNT(*) AS row_count
FROM analytics.fact_loans
GROUP BY loan_id
HAVING COUNT(*) > 1;

-- D4) Check for null loan_id values
SELECT
  COUNT(*) AS null_loan_id
FROM analytics.fact_loans
WHERE loan_id IS NULL; 

-- D5) Reconciliation check with trusted final table
SELECT
  (SELECT COUNT(*)
   FROM analytics.bank_loans_final) AS final_table_rows,

   (SELECT COUNT(*)
    FROM analytics.fact_loans) AS fact_table_rows;