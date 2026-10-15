-- =====================================================================================
-- File: 06_data_modeling.sql
-- Goal: Build star-schema style tables from analytics.bank_loans_final
-- =====================================================================================


-- =====================================================================================
-- Section A) Create date dimension
-- Purpose: Build a reusable date lookup table for time-based analysis
-- =====================================================================================


-- A1) Drop date dimension if it already exists
DROP TABLE IF EXISTS analytics.dim_date;

-- A2) Create date dimension
CREATE TABLE analytics.dim_date AS
WITH all_dates AS (
    SELECT application_date AS date_value
    FROM analytics.bank_loans_final
    WHERE application_date IS NOT NULL

    UNION

    SELECT approval_date AS date_value
    FROM analytics.bank_loans_final
    WHERE approval_date IS NOT NULL

    UNION

    SELECT disbursement_date AS date_value
    FROM analytics.bank_loans_final
    WHERE disbursement_date IS NOT NULL

    UNION

    SELECT due_date AS date_value
    FROM analytics.bank_loans_final
    WHERE due_date IS NOT NULL
)
SELECT
  date_value AS date,
  EXTRACT(YEAR FROM date_value)::INTEGER AS year,
  EXTRACT(MONTH FROM date_value)::INTEGER AS month,
  EXTRACT(DAY FROM date_value)::INTEGER AS day,
  EXTRACT(QUARTER FROM date_value)::INTEGER AS quarter,
  TO_CHAR(date_value, 'FMMonth') AS month_name,
  TO_CHAR(date_value, 'Mon') AS month_name_short,
  TO_CHAR(date_value, 'YYYY-MM') AS year_month,
  TO_CHAR(date_value, 'FMDay') AS day_name,
  TO_CHAR(date_value, 'Dy') AS day_name_short
  FROM all_dates
  ORDER BY date;


-- =====================================================================================
-- Section B) Create branch dimension
-- Purpose: Create a standardized branch dimension for consistent branch and 
--          regional analysis
-- =====================================================================================


-- B1) Drop branch dimension if it already exists
DROP TABLE IF EXISTS analytics.dim_branch;

-- B2) Create branch dimension
CREATE TABLE analytics.dim_branch AS
SELECT
  branch_code,
  branch_name,
  region
FROM (
    SELECT
      branch_code,
      branch_name,
      region,
      ROW_NUMBER() OVER (
        PARTITION BY branch_code
        ORDER BY branch_name
      ) AS rn
    FROM analytics.bank_loans_final
    WHERE branch_code IS NOT NULL
) x
WHERE rn = 1;


-- =====================================================================================
-- Section C) Create product dimension
-- Purpose: Create a standardized product dimension for consistent 
--          product-based analysis
-- =====================================================================================


-- C1) Drop product dimension if it already exists
DROP TABLE IF EXISTS analytics.dim_product;

-- C2) Create product dimension
CREATE TABLE analytics.dim_product AS
SELECT DISTINCT product_type
FROM analytics.bank_loans_final
WHERE product_type IS NOT NULL
ORDER BY product_type;


-- =====================================================================================
-- Section D) Create fact table
-- Purpose: Create the central fact table for loan-level portfolio analysis
-- =====================================================================================


-- D1) Drop fact table if it already exists
DROP TABLE IF EXISTS analytics.fact_loans;

-- D2) Create fact table
CREATE TABLE analytics.fact_loans AS
SELECT
  raw_row_num,
  loan_id,
  customer_id,

  -- Dimension join keys
  application_date,
  approval_date,
  disbursement_date,
  due_date,
  branch_code,
  product_type,

  -- Measures and descriptive fields
  loan_amount,
  interest_rate,
  term_months,
  annual_income,
  credit_score,
  debt_to_income_ratio,
  collateral_value,
  delinquent_days,

  -- Status / segmentation fields
  loan_status,
  default_flag,
  employment_status,
  purpose,
  risk_grade,
  channel,
  officer_id,

  -- Audit fields retained from final trusted layers
  long_approval_timeline_flag,
  low_information_flag,
  loan_amount_quality_flag

FROM analytics.bank_loans_final;