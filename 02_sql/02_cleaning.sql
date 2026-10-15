-- =====================================================================================
-- File: 02_cleaning.sql
-- Goal: Clean and standardize raw bank loan data into analysis-ready format
-- Notes:
--     - No rows are deleted yet
--     - Duplicates are not removed yet
--     - Suspicious future dates are kept for now and will be reviewed later
--     - Impossible numeric values (negatives where not allowed) are converted to NULL
-- =====================================================================================


-- =====================================================================================
-- 1) Drop and recreate clean table
-- =====================================================================================


DROP TABLE IF EXISTS clean.bank_loans;


CREATE TABLE clean.bank_loans AS

WITH BASE AS (
    SELECT
      ROW_NUMBER () OVER () AS raw_row_num,

      -- Text fields: trim blanks first
      NULLIF(BTRIM(loan_id), '') AS loan_id_raw,
      NULLIF(BTRIM(customer_id), '') AS customer_id_raw,
      NULLIF(BTRIM(application_date), '') AS application_date_raw,
      NULLIF(BTRIM(approval_date), '') AS approval_date_raw,
      NULLIF(BTRIM(disbursement_date), '') AS disbursement_date_raw,
      NULLIF(BTRIM(due_date), '') AS due_date_raw,
      NULLIF(BTRIM(branch_code), '') AS branch_code_raw,
      NULLIF(BTRIM(branch_name), '') AS branch_name_raw,
      NULLIF(BTRIM(region), '') AS region_raw,
      NULLIF(BTRIM(product_type), '') AS product_type_raw,
      NULLIF(BTRIM(loan_amount), '') AS loan_amount_raw,
      NULLIF(BTRIM(interest_rate), '') AS interest_rate_raw,
      NULLIF(BTRIM(term_months), '') AS term_months_raw,
      NULLIF(BTRIM(annual_income), '') AS annual_income_raw,
      NULLIF(BTRIM(employment_status), '') AS employment_status_raw,
      NULLIF(BTRIM(credit_score), '') AS credit_score_raw,
      NULLIF(BTRIM(debt_to_income_ratio), '') AS debt_to_income_ratio_raw,
      NULLIF(BTRIM(collateral_value), '') AS collateral_value_raw,
      NULLIF(BTRIM(delinquent_days), '') AS delinquent_days_raw,
      NULLIF(BTRIM(loan_status), '') AS loan_status_raw,
      NULLIF(BTRIM(default_flag), '') AS default_flag_raw,
      NULLIF(BTRIM(purpose), '') AS purpose_raw,
      NULLIF(BTRIM(risk_grade), '') AS risk_grade_raw,
      NULLIF(BTRIM(channel), '') AS channel_raw,
      NULLIF(BTRIM(officer_id), '') AS officer_id_raw
    FROM raw.bank_loans_stg
), standardize_text AS (
    SELECT
      raw_row_num,

      -- IDs
      loan_id_raw AS loan_id,
      customer_id_raw AS customer_id,

      -- Keep original raw date text for audit during cleaning stage
      application_date_raw,
      approval_date_raw,
      disbursement_date_raw,
      due_date_raw,

      -- Branch / region / product text cleanup 
      
      CASE
          WHEN branch_code_raw IS NULL THEN NULL
          ELSE UPPER(REGEXP_REPLACE(branch_code_raw, '\s+', ' ', 'g'))
      END AS branch_code,

      CASE
          WHEN branch_name_raw IS NULL THEN NULL
          ELSE INITCAP(REGEXP_REPLACE(branch_name_raw, '\s+', ' ', 'g'))
      END AS branch_name,

      CASE
          WHEN region_raw IS NULL THEN NULL
          ELSE INITCAP(region_raw)
      END AS region,

      CASE
          WHEN product_type_raw IS NULL THEN NULL
          WHEN LOWER(REGEXP_REPLACE(product_type_raw, '\s+', ' ', 'g')) = 'sme loan' THEN 'SME Loan'
          ELSE INITCAP(REGEXP_REPLACE(product_type_raw, '\s+', ' ', 'g'))
      END AS product_type,

      -- Numeric raw strings kept for parsing
      loan_amount_raw,
      interest_rate_raw,
      term_months_raw,
      annual_income_raw,
      credit_score_raw,
      debt_to_income_ratio_raw,
      collateral_value_raw,
      delinquent_days_raw,

      -- employment_status cleanup

      CASE
          WHEN employment_status_raw IS NULL THEN NULL
          WHEN LOWER(REGEXP_REPLACE(employment_status_raw, '\s+', ' ', 'g')) IN ('self employed', 'self-employed') THEN 'Self-Employed'
          ELSE INITCAP(REGEXP_REPLACE(employment_status_raw, '\s+', ' ', 'g'))
      END AS employment_status,

      -- loan_status cleanup

      CASE
          WHEN loan_status_raw IS NULL THEN NULL
          ELSE INITCAP(REGEXP_REPLACE(loan_status_raw, '\s+', ' ', 'g'))
      END AS loan_status,

      -- default_flag normalization

      CASE
          WHEN default_flag_raw IS NULL THEN NULL
          WHEN LOWER(default_flag_raw) IN ('yes', 'y') THEN 'Yes'
          WHEN LOWER(default_flag_raw) IN ('no', 'n') THEN 'No'
          ELSE NULL
      END AS default_flag,

      -- Purpose cleanup

      CASE
          WHEN purpose_raw IS NULL THEN NULL
          ELSE INITCAP(REGEXP_REPLACE(purpose_raw, '\s+', ' ', 'g'))
      END AS purpose,

      -- risk_grade cleanup

      CASE
          WHEN risk_grade_raw IS NULL THEN NULL
          ELSE UPPER(risk_grade_raw)
      END AS risk_grade,

      -- Channel cleanup

      CASE
          WHEN channel_raw IS NULL THEN NULL
          ELSE INITCAP(REGEXP_REPLACE(channel_raw, '\s+', ' ', 'g'))
      END AS channel,

      -- officer_id cleanup

      CASE
          WHEN officer_id_raw IS NULL THEN NULL
          ELSE UPPER(REGEXP_REPLACE(officer_id_raw, '\s+', '', 'g'))
      END AS officer_id

    FROM base
), parsed_values AS (
    SELECT
    raw_row_num,
    loan_id,
    customer_id,
    branch_code,
    branch_name,
    region,
    product_type,
    employment_status,
    loan_status,
    default_flag,
    purpose,
    risk_grade,
    channel,
    officer_id,

    application_date_raw,
    approval_date_raw,
    disbursement_date_raw,
    due_date_raw,

      -- Numeric parsing

      -- loan_amount

      CASE
          WHEN loan_amount_raw IS NULL THEN NULL
          WHEN REGEXP_REPLACE(loan_amount_raw, '[\$,]', '', 'g') ~ '^-?\d+(\.\d+)?$'
          THEN REGEXP_REPLACE(loan_amount_raw, '[\$,]', '', 'g')::NUMERIC(14, 2)
          ELSE NULL
      END AS loan_amount_tmp,

      -- interest_rate

      CASE
          WHEN interest_rate_raw IS NULL THEN NULL
          WHEN REGEXP_REPLACE(interest_rate_raw, '[\%,]', '', 'g') ~ '^-?\d+(\.\d+)?$'
          THEN REGEXP_REPLACE(interest_rate_raw, '[\%,]', '', 'g')::NUMERIC(8, 2)
          ELSE NULL
      END AS interest_rate_temp,

      -- term_months

      CASE
          WHEN term_months_raw IS NULL THEN NULL
          WHEN REGEXP_REPLACE(term_months_raw, '[,]', '', 'g') ~ '^-?\d+$'
          THEN REGEXP_REPLACE(term_months_raw, '[,]', '', 'g')::INTEGER
          ELSE NULL
      END AS term_months_tmp,

      -- annual_income

      CASE
          WHEN annual_income_raw IS NULL THEN NULL
          WHEN REGEXP_REPLACE(annual_income_raw, '[$,]', '', 'g') ~ '^-?\d+(\.\d+)?$'
          THEN REGEXP_REPLACE(annual_income_raw, '[$,]', '', 'g')::NUMERIC(14, 2)
          ELSE NULL
      END AS annual_income_tmp,

      -- credit_score

      CASE
          WHEN credit_score_raw IS NULL THEN NULL
          WHEN REGEXP_REPLACE(credit_score_raw, '[,]', '', 'g') ~ '^\d+$'
          THEN REGEXP_REPLACE(credit_score_raw, '[,]', '', 'g')::INTEGER
          ELSE NULL
      END AS credit_score_tmp,

      -- debt_to_income_ratio

      CASE
          WHEN debt_to_income_ratio_raw IS NULL THEN NULL
          WHEN REGEXP_REPLACE(debt_to_income_ratio_raw, '[\%,]', '', 'g') ~ '^-?\d+(\.\d+)?$'
          THEN REGEXP_REPLACE(debt_to_income_ratio_raw, '[\%,]', '', 'g')::NUMERIC(8, 2)
          ELSE NULL
      END AS debt_to_income_ratio_tmp,

      -- collateral_value

      CASE
          WHEN collateral_value_raw IS NULL THEN NULL
          WHEN REGEXP_REPLACE(collateral_value_raw, '[\$,]', '', 'g') ~ '^-?\d+(\.\d+)?$'
          THEN REGEXP_REPLACE(collateral_value_raw, '[\$,]', '', 'g')::NUMERIC(14, 2)
          ELSE NULL
      END AS collateral_value_tmp,

      -- delinquent_days

      CASE
          WHEN delinquent_days_raw IS NULL THEN NULL
          WHEN REGEXP_REPLACE(delinquent_days_raw, '[,]', '', 'g') ~ '^\d+$'
          THEN REGEXP_REPLACE(delinquent_days_raw, '[,]', '', 'g')::INTEGER
          ELSE NULL
      END AS delinquent_days_tmp,

    -- =====================================================================================
    -- Date parsing
    -- Strategy:
    -- 1) YYYY-MM-DD | YYYY/MM/DD
    -- 2) Month DD, YYYY
    -- 3) Ambiguous numeric form:
    -- - if first part > 12 => DD-MM-YYYY | DD/MM/YYYY
    -- - if second part > 12 => MM-DD-YYYY | MM/DD/YYYY 
    -- - if both <= 12 => assume MM-DD-YYYY | MM/DD/YYYY
    -- This assumption should be reviewed later in business logic validation.
    -- =====================================================================================

    -- application_date

    CASE
        WHEN application_date_raw IS NULL THEN NULL
        WHEN REGEXP_REPLACE(application_date_raw, '/', '-', 'g') ~ '^\d{4}-\d{2}-\d{2}$'
        THEN TO_DATE(REGEXP_REPLACE(application_date_raw, '/', '-', 'g'), 'YYYY-MM-DD')
        WHEN application_date_raw ~ '^[A-Za-z]+ \d{1,2}, \d{4}$'
        THEN TO_DATE(application_date_raw, 'Mon DD, YYYY')
        WHEN REGEXP_REPLACE(application_date_raw, '/', '-', 'g') ~ '^\d{2}-\d{2}-\d{4}$' THEN

        CASE
            WHEN SPLIT_PART(REGEXP_REPLACE(application_date_raw, '/', '-', 'g'), '-', 1)::INTEGER > 12 
            THEN TO_DATE(REGEXP_REPLACE(application_date_raw, '/', '-', 'g'), 'DD-MM-YYYY')
            WHEN SPLIT_PART(REGEXP_REPLACE(application_date_raw, '/', '-', 'g'), '-', 2)::INTEGER > 12
            THEN TO_DATE(REGEXP_REPLACE(application_date_raw, '/', '-', 'g'), 'MM-DD-YYYY')
            ELSE TO_DATE(REGEXP_REPLACE(application_date_raw, '/', '-', 'g'), 'MM-DD-YYYY')
        END
        ELSE NULL
    END AS application_date_tmp,

    -- approval_date

    CASE
        WHEN approval_date_raw IS NULL THEN NULL 
        WHEN REGEXP_REPLACE(approval_date_raw, '/', '-', 'g') ~ '^\d{4}-\d{2}-\d{2}$'
        THEN TO_DATE(REGEXP_REPLACE(approval_date_raw, '/', '-', 'g'), 'YYYY-MM-DD')
        WHEN approval_date_raw ~ '^[A-Za-z]+ \d{1,2}, \d{4}$'
        THEN TO_DATE(approval_date_raw, 'Mon DD, YYYY')
        WHEN REGEXP_REPLACE(approval_date_raw, '/', '-', 'g') ~ '^\d{2}-\d{2}-\d{4}$' THEN
        
        CASE
            WHEN SPLIT_PART(REGEXP_REPLACE(approval_date_raw, '/', '-', 'g'), '-', 1)::INTEGER > 12
            THEN TO_DATE(REGEXP_REPLACE(approval_date_raw, '/', '-', 'g'), 'DD-MM-YYYY')
            WHEN SPLIT_PART(REGEXP_REPLACE(approval_date_raw, '/', '-', 'g'), '-', 2)::INTEGER > 12
            THEN TO_DATE(REGEXP_REPLACE(approval_date_raw, '/', '-', 'g'), 'MM-DD-YYYY')
            ELSE TO_DATE(REGEXP_REPLACE(approval_date_raw, '/', '-', 'g'), 'MM-DD-YYYY')
        END
        ELSE NULL
    END AS approval_date_tmp,

    CASE
        WHEN disbursement_date_raw IS NULL THEN NULL
        WHEN REGEXP_REPLACE(disbursement_date_raw, '/', '-', 'g') ~ '^\d{4}-\d{2}-\d{2}$'
        THEN TO_DATE(REGEXP_REPLACE(disbursement_date_raw, '/', '-', 'g'), 'YYYY-MM-DD')
        WHEN disbursement_date_raw ~ '^[A-Za-z]+ \d{1,2}, \d{4}$'
        THEN TO_DATE(disbursement_date_raw, 'Mon DD, YYYY')
        WHEN REGEXP_REPLACE(disbursement_date_raw, '/', '-', 'g') ~ '^\d{2}-\d{2}-\d{4}$' THEN

        CASE
            WHEN SPLIT_PART(REGEXP_REPLACE(disbursement_date_raw, '/', '-', 'g'), '-', 1)::INTEGER > 12
            THEN TO_DATE(REGEXP_REPLACE(disbursement_date_raw, '/', '-', 'g'), 'DD-MM-YYYY')
            WHEN SPLIT_PART(REGEXP_REPLACE(disbursement_date_raw, '/', '-', 'g'), '-', 2)::INTEGER > 12
            THEN TO_DATE(REGEXP_REPLACE(disbursement_date_raw, '/', '-', 'g'), 'MM-DD-YYYY')
            ELSE TO_DATE(REGEXP_REPLACE(disbursement_date_raw, '/', '-', 'g'), 'MM-DD-YYYY')
        END
        ELSE NULL
    END AS disbursement_date_tmp,

    -- due_date

    CASE
        WHEN due_date_raw IS NULL THEN NULL
        WHEN REGEXP_REPLACE(due_date_raw, '/', '-', 'g') ~ '^\d{4}-\d{2}-\d{2}$'
        THEN TO_DATE(REGEXP_REPLACE(due_date_raw, '/', '-', 'g'), 'YYYY-MM-DD')
        WHEN due_date_raw ~ '^[A-Za-z]+ \d{1,2}, \d{4}$'
        THEN TO_DATE(due_date_raw, 'Mon DD, YYYY')
        WHEN REGEXP_REPLACE(due_date_raw, '/', '-', 'g') ~ '^\d{2}-\d{2}-\d{4}$' THEN

        CASE
            WHEN SPLIT_PART(REGEXP_REPLACE(due_date_raw, '/', '-', 'g'), '-', 1)::INTEGER > 12
            THEN TO_DATE(REGEXP_REPLACE(due_date_raw, '/', '-', 'g'), 'DD-MM-YYYY')
            WHEN SPLIT_PART(REGEXP_REPLACE(due_date_raw, '/', '-', 'g'), '-', 2)::INTEGER > 12
            THEN TO_DATE(REGEXP_REPLACE(due_date_raw, '/', '-', 'g'), 'MM-DD-YYYY')
            ELSE TO_DATE(REGEXP_REPLACE(due_date_raw, '/', '-', 'g'), 'MM-DD-YYYY')
        END
        ELSE NULL
    END AS due_date_tmp
    FROM standardize_text
), final_clean AS(
    SELECT
    raw_row_num,

    loan_id,
    customer_id,

    branch_code,
    branch_name,
    region,
    product_type,

    -- Negative values converted to NULL

    -- loan_amount

    CASE
        WHEN loan_amount_tmp < 0 THEN NULL
        ELSE loan_amount_tmp
    END AS loan_amount,

    -- interest_rate

    CASE
        WHEN interest_rate_temp < 0 THEN NULL
        ELSE interest_rate_temp
    END AS interest_rate,

    -- term_months

    CASE
        WHEN term_months_tmp < 0 THEN NULL
        ELSE term_months_tmp
    END AS term_months,

    -- annual_income

    CASE
        WHEN annual_income_tmp < 0 THEN NULL
        ELSE annual_income_tmp
    END AS annual_income,

    employment_status,

    -- credit_score

    CASE
        WHEN credit_score_tmp < 0 THEN NULL
        ELSE credit_score_tmp
    END AS credit_score,

    -- debt_to_income_ratio

    CASE
        WHEN debt_to_income_ratio_tmp < 0 THEN NULL
        ELSE debt_to_income_ratio_tmp
    END AS debt_to_income_ratio,

    -- collateral_value

    CASE
        WHEN collateral_value_tmp < 0 THEN NULL
        ELSE collateral_value_tmp
    END AS collateral_value,

    -- delinquent_days
    CASE
        WHEN delinquent_days_tmp < 0 THEN NULL
        ELSE delinquent_days_tmp
    END AS delinquent_days,

    loan_status,
    default_flag,
    purpose,
    risk_grade,
    channel,
    officer_id,

    application_date_tmp AS application_date,
    approval_date_tmp AS approval_date,
    disbursement_date_tmp AS disbursement_date,
    due_date_tmp AS due_date
    FROM parsed_values
)

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

  -- duplicate_flag for later review

  CASE
      WHEN COUNT(*) OVER (PARTITION BY loan_id) > 1 THEN 'duplicate_loan_id'
      ELSE 'No'
  END AS loan_id_duplicate_flag,

  CASE
      WHEN COUNT(*) OVER(
        PARTITION BY loan_id, customer_id, loan_amount, disbursement_date
      ) > 1 THEN 'duplicate_business_key'
      ELSE 'No'
  END AS business_key_duplicate_flag

FROM final_clean;
