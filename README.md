
# Bank Loan Risk Analysis | End-to-End Data Analytics Project

## Project Overview

This project analyzes a bank's loan portfolio to identify credit risk patterns, understand loan defaults, and evaluate portfolio performance across products, regions, branches, and time.

The objective was to build an end-to-end data analytics solution using PostgreSQL, SQL, and Power BI, covering data cleaning, data quality validation, dimensional modeling, business analysis, and interactive dashboard development.

## Business Problem

Financial institutions must balance portfolio growth with effective credit risk management. This project addresses the following questions:

- Which loan products have the highest default risk?
- Which regions and branches contribute most to portfolio risk?
- How does portfolio growth affect credit quality?
- Are approval delays associated with higher default rates?
- Is the underlying data reliable for decision-making?

## Dataset

- **Raw records:** 1,243
- **Final analysis-ready records:** Approximately 800
- **Source:** Raw CSV loan dataset

### Key Fields

- Loan amount, term, and interest rate
- Customer income, credit score, and debt-to-income ratio
- Application, approval, disbursement, and due dates
- Loan product, branch, and region
- Loan status and default flag

## Tools & Technologies

- **SQL / VS Code:** Data cleaning, validation, and analytics
- **Power BI:** Dashboard development and data storytelling
- **GitHub:** Version control and project documentation

## SQL Workflow

### 1. Raw Data Ingestion

- Imported the CSV dataset into `raw.bank_loans_stg`.
- Explored data structure, distributions, and potential duplicates.
- Preserved the original records for traceability.

### 2. Data Cleaning

Created `clean.bank_loans` to standardize and clean the source data.

- Standardized text fields and whitespace.
- Converted monetary, percentage, and numeric fields.
- Normalized inconsistent date formats.
- Converted invalid values to NULL.
- Flagged potential duplicates using loan IDs and business keys.

### 3. Data Quality Validation

- Reconciled row counts across data layers.
- Audited missing values in critical fields.
- Inspected duplicate records.
- Validated application, approval, disbursement, and due dates.
- Identified future dates and operational anomalies.
- Evaluated data completeness.

### 4. Business Rules and Data Refinement

Created the following tables:

- `clean.bank_loans_reviewed` — identifies data quality issues.
- `clean.bank_loans_deduped` — removes confirmed exact duplicates.
- `analytics.bank_loans_final` — stores the analysis-ready dataset.

Applied business rules to identify impossible timelines, future-dated anomalies, placeholder records, and unrealistic product-term combinations.

### 5. Data Modeling

Designed a star schema for scalable analytics and Power BI reporting.

**Fact Table**
- `fact_loans`

**Dimension Tables**
- `dim_date`
- `dim_branch`
- `dim_product`

Validated dimension uniqueness, fact table integrity, and record reconciliation.

### 6. SQL Analytics

Developed SQL queries to analyze:

- Portfolio volume and loan exposure
- Overall and product-level default rates
- Branch and regional performance
- Portfolio growth and default trends
- Risk grade segmentation
- Operational indicators
- Data quality metrics

## Power BI Dashboard

The report contains five analytical pages.

### 1. Executive Summary

- Portfolio size and exposure
- Overall default rate
- Loan status distribution
- Data quality coverage

### 2. Product Risk Analysis

- Auto loans recorded the highest default rate at approximately 25%.
- SME loans combined elevated exposure with higher default risk.
- Mortgages represented the largest exposure with comparatively lower default risk.

### 3. Branch & Region Performance

- The North region recorded the highest default rate.
- The East region had the largest exposure with comparatively lower risk.
- Branch-level analysis highlighted locations such as New York and Miami for further investigation.

### 4. Time & Risk Trends

- Portfolio growth increased significantly in 2025.
- Default rates remained elevated despite portfolio expansion.
- Risk Grade E recorded the highest default rate at approximately 42%.

### 5. Operational Risk Monitoring

- Loans with delayed approvals showed a default rate of approximately 25%, compared with 17.8% for the comparison group.
- Delayed approvals represented approximately 3% of the portfolio.
- The relationship indicates a potential monitoring signal, not proof of causation.

## Key Findings

### Credit Risk

The overall default rate was approximately **18%**, indicating significant credit risk within the analyzed portfolio.

### Data Quality

Approximately **18% of loan amount values were missing**, limiting the reliability of exposure calculations and risk reporting.

Valid balance coverage was approximately 81.5%.

### Product Risk

Auto loans had the highest observed default rate. SME loans combined elevated risk with substantial exposure, while mortgages showed comparatively lower risk.

### Geographic Risk

The North region had the highest default rate, and certain branches warranted further investigation for potential risk concentration.

### Growth vs. Credit Quality

The portfolio expanded significantly in 2025, but default rates remained elevated. Growth did not coincide with a clear improvement in credit quality.

### Operational Risk

Approval delays were associated with higher observed default rates, although further analysis is required to identify the underlying drivers.

## Business Recommendations

1. **Strengthen underwriting:** Review lending criteria for auto and SME loans and evaluate risk-based pricing.
2. **Optimize portfolio composition:** Monitor high-risk exposure and evaluate growth opportunities in comparatively lower-risk products.
3. **Investigate geographic risk:** Review high-default regions and branches to identify potential risk drivers.
4. **Improve risk monitoring:** Track approval delays, risk grades, default rates, and exposure trends.
5. **Control portfolio growth:** Align lending expansion with underwriting standards and risk appetite.
6. **Improve data quality:** Strengthen collection and validation of loan amount and branch information.

## Project Outcomes

This project demonstrates practical experience in:

- SQL-based data cleaning and transformation
- Data quality auditing and validation
- Business rule implementation and deduplication
- Star schema dimensional modeling
- Credit risk and portfolio analytics
- Power BI dashboard development
- Translating analytical findings into business recommendations

## Conclusion

This project demonstrates how raw loan data can be transformed into an analysis-ready dataset and an interactive reporting solution. By combining SQL, dimensional modeling, and Power BI, the analysis identifies credit risk patterns, highlights data quality issues, and provides actionable recommendations for lending and risk monitoring.

