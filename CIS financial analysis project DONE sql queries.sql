SELECT * FROM cis_no_dupes;

#STEP 1: CREATING DATABASE

CREATE DATABASE CIS_project;
USE CIS_project;

#STEP 2: CREATE TABLE

CREATE TABLE CIS_dataset (
    PERSONID BIGINT,                          -- unique ID
    Weight DECIMAL(12,4),                     -- survey weights, decimals
    Province INT,                             -- province code
    MBMREGP INT,                              -- market basket measure region
    Age_gap INT,                              -- age category code
    Gender INT,                               -- gender code
    Marital_status INT,                       -- marital status code
    Highschool INT,                           -- 1 = yes, 2 = no, etc.
    Highest_edu INT,                          -- highest education level code
    Work_ref INT,                             -- employment status ref code
    Work_yearly INT,                          -- total years employed
    Emp_week_ref INT,                         -- weeks worked in ref period
    Total_hour_ref INT,                       -- hours worked in ref period
    paid_emp_ref INT,                         -- weeks as paid employee
    self_emp_ref INT,                         -- weeks as self-employed
    Immigrant INT,                            -- immigrant status code
    Year_immigrant INT,                       -- year immigrated
    income_after_tax DECIMAL(15,2),           -- after-tax income
    Cap_gain DECIMAL(15,2),                   -- capital gains
    Childcare_expe DECIMAL(15,2),             -- childcare expenses
    Child_benefit DECIMAL(15,2),              -- childcare benefits
    CPP_QPP DECIMAL(15,2),                    -- pension contributions
    Earning DECIMAL(15,2),                    -- total earnings
    Guaranteed_income DECIMAL(15,2),          -- guaranteed income supplement
    Investment DECIMAL(15,2),                 -- investment income
    Old_age_pension DECIMAL(15,2),            -- old age security
    Private_pension DECIMAL(15,2),            -- private pension
    Self_emp_income DECIMAL(15,2),            -- self-employment income
    Pension DECIMAL(15,2),                    -- total pension
    Total_income DECIMAL(15,2),               -- total income
    Emp_insurance DECIMAL(15,2),              -- employment insurance
    Salary_wages DECIMAL(15,2),               -- salary & wages
    compensation DECIMAL(15,2),               -- compensation
    Family_mem INT,                           -- family members count
    CFCOMP INT,                               -- family composition code
    CONDMP INT,                               -- dwelling type code
    RENTM DECIMAL(15,2)                       -- monthly rent
);

#STEP 3: DATA IMPORT

-- Make sure LOCAL is enabled
SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';


-- Load the CSV into table
LOAD DATA LOCAL INFILE 'C:/Users/HP PC/Desktop/mysqlbegineer/cis_data.csv'
INTO TABLE cis_dataset
FIELDS TERMINATED BY ','       -- columns are separated by commas
ENCLOSED BY '"'               -- text values are enclosed in quotes
LINES TERMINATED BY '\n'      -- each line = one row
IGNORE 1 ROWS;               -- skip the header row

SELECT * FROM CIS_dataset LIMIT 10;


-- Backup raw data
CREATE TABLE CIS_cleaned AS
SELECT * FROM CIS_dataset;

# STEP 4: DATA CLEANING 

-- Count total rows
SELECT COUNT(*) AS total_rows FROM CIS_cleaned;

-- Inspect column
SELECT COUNT(DISTINCT PERSONID) AS unique_ids FROM CIS_cleaned;

-- Find duplicates (if any)
SELECT PERSONID, COUNT(*) AS cnt
FROM CIS_cleaned
GROUP BY PERSONID
HAVING COUNT(*) > 1;

-- Check if any PERSONID is NULL
SELECT COUNT(*) AS null_ids
FROM CIS_cleaned
WHERE PERSONID IS NULL;


-- Check if duplicate rows are identical
SELECT PERSONID, COUNT(*) AS cnt, COUNT(DISTINCT CONCAT_WS('|', 
    Weight, Province, MBMREGP, Age_gap, Gender, Marital_status, Highschool, 
    Highest_edu, Work_ref, Work_yearly, Emp_week_ref, Total_hour_ref, 
    paid_emp_ref, self_emp_ref, Immigrant, Year_immigrant, income_after_tax, 
    Cap_gain, Childcare_expe, Child_benefit, CPP_QPP, Earning, Guaranteed_income, 
    Investment, Old_age_pension, Private_pension, Self_emp_income, Pension, 
    Total_income, Emp_insurance, Salary_wages, compensation, Family_mem, 
    CFCOMP, CONDMP, RENTM)) AS distinct_rows
FROM CIS_cleaned
GROUP BY PERSONID
HAVING COUNT(*) > 1;

-- Keep only one row per PERSONID
CREATE TABLE CIS_no_dupes AS
SELECT DISTINCT *
FROM CIS_cleaned;


SELECT COUNT(*) AS total_rows FROM CIS_no_dupes;
SELECT COUNT(DISTINCT PERSONID) AS unique_ids FROM CIS_no_dupes;

-- Column 2: Weight
-- Basic range check
SELECT MIN(Weight) AS min_weight, MAX(Weight) AS max_weight
FROM CIS_no_dupes;

-- Spot unusual values (like 0, negatives, or very large)
SELECT Weight, COUNT(*) AS freq
FROM CIS_no_dupes
GROUP BY Weight
ORDER BY Weight;

-- Column 3:Province
-- Inspect column
SELECT Province, COUNT(*) AS count
FROM CIS_no_dupes
GROUP BY Province
ORDER BY Province;

-- Check for NULLs and common sentinel values
SELECT
  SUM(CASE WHEN Province IS NULL THEN 1 ELSE 0 END) AS n_nulls,
  SUM(CASE WHEN Province IN (96,97,98,99) THEN 1 ELSE 0 END) AS n_short_sentinels,
  SUM(CASE WHEN Province IN (99999996,99999997,99999998,99999999) THEN 1 ELSE 0 END) AS n_long_sentinels,
  COUNT(*) AS total_rows
FROM CIS_no_dupes;

-- Create a province mapping table 
CREATE TABLE cis_province_map (
  code INT PRIMARY KEY,
  label VARCHAR(120)
);

-- Insert code → label pairs
INSERT INTO cis_province_map (code, label) VALUES
  (10, 'Newfoundland and Labrador'),
  (11, 'Prince Edward Island'),
  (12, 'Nova Scotia'),
  (13, 'New Brunswick'),
  (24, 'Quebec'),
  (35, 'Ontario'),
  (46, 'Manitoba'),
  (47, 'Saskatchewan'),
  (48, 'Alberta'),
  (59, 'British Columbia');
  

-- Add a new column to hold the readable label
ALTER TABLE cis_no_dupes
ADD COLUMN province_label VARCHAR(50);

SELECT * FROM cis_no_dupes; 

-- Populate new column with province name
SET SQL_SAFE_UPDATES = 0;

UPDATE cis_no_dupes AS m
JOIN cis_province_map AS p
  ON m.Province = p.code
SET m.province_label = p.label;

SELECT Province, province_label, COUNT(*) AS row_count
FROM cis_no_dupes
GROUP BY Province, province_label
ORDER BY Province;

-- column 4: MBMREGP
-- Inspect column

SELECT MBMREGP, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY MBMREGP
ORDER BY MBMREGP;

-- checking for missing or invalid entries
SELECT COUNT(*) AS null_count
FROM cis_no_dupes
WHERE MBMREGP IS NULL OR MBMREGP IN (99999996, 99999999);

-- column 5: Age gap
-- Inspect column
SELECT Age_gap, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Age_gap
ORDER BY Age_gap;

-- Check for missing values or outliers
SELECT COUNT(*) AS invalid_count
FROM cis_no_dupes
WHERE Age_gap IS NULL OR Age_gap IN (96, 97, 98, 99);

-- Create a mapping table and assign readable labels
CREATE TABLE cis_agegap_map (
    code INT PRIMARY KEY,
    label VARCHAR(50)
);

INSERT INTO cis_agegap_map (code, label) VALUES
(1, '0–4 years'),
(2, '5–9 years'),
(3, '10–14 years'),
(4, '15–19 years'),
(5, '20–24 years'),
(6, '25–29 years'),
(7, '30–34 years'),
(8, '35–39 years'),
(9, '40–44 years'),
(10, '45–49 years'),
(11, '50–54 years'),
(12, '55–59 years'),
(13, '60–64 years'),
(14, '65–69 years'),
(15, '70+ years');

-- Add a new label column in main table
ALTER TABLE cis_no_dupes
ADD COLUMN age_gap_label VARCHAR(50);

-- Populate label column 
UPDATE cis_no_dupes AS m
JOIN cis_agegap_map p ON m.Age_gap = p.code
SET m.age_gap_label = p.label;

-- Column 6:Gender
-- Inspect column
SELECT Gender, count(*) AS freq
FROM cis_no_dupes
GROUP BY Gender
ORDER BY Gender;

-- Create a mapping table
CREATE TABLE cis_gender_map
(code INT PRIMARY KEY, label VARCHAR(10));

-- Insert values
INSERT INTO cis_gender_map (code, label) VALUES
(1, 'Male'),
(2, 'Female');

-- Add new label column in main table
ALTER TABLE cis_no_dupes
ADD COLUMN Gender_label VARCHAR (10);

-- Populate label column 
UPDATE cis_no_dupes AS m
JOIN cis_gender_map AS p ON m.Gender = p.code
SET m.Gender_label = p.label;

-- Column 7: Marital status
-- Inspect column
SELECT Marital_status, COUNT(*)
FROM cis_no_dupes
GROUP BY Marital_status
ORDER BY Marital_status;

-- Create mapping table
CREATE TABLE cis_marital_map
(code INT PRIMARY KEY, label VARCHAR(20));

INSERT INTO cis_marital_map (code, label) VALUES
(1, 'Single'),
(2, 'Married'),
(3, 'Divorced'),
(4, 'Widowed'),
(96, 'Not stated'),
(99, 'Unknown');

-- Add new albel column in main table 
ALTER TABLE cis_no_dupes
ADD COLUMN Marital_status_label VARCHAR(20);

-- Populate label column
UPDATE cis_no_dupes AS m
JOIN cis_marital_map AS p ON m.Marital_status = p.code
SET m.Marital_status_label = p.label;

-- Column 8: Highschool
-- Inspect column
SELECT Highschool, COUNT(*)
FROM cis_no_dupes
GROUP BY Highschool
ORDER BY Highschool;

-- Checking for nulls and outliers
SELECT
  SUM(CASE WHEN Highschool IS NULL THEN 1 ELSE 0 END) AS n_nulls
FROM cis_no_dupes;


-- Create mapping table 
CREATE TABLE cis_highschool_map (
  code INT PRIMARY KEY,
  label VARCHAR(60)
);

-- Insert values
INSERT INTO cis_highschool_map (code, label) VALUES
(1, 'Yes'),
(2, 'No'),
(6, 'Not apllicable'),
(9,'Not stated');

-- Create column 
ALTER TABLE cis_no_dupes
ADD column Highschool_label VARCHAR (60);

-- Populate label column 
UPDATE cis_no_dupes AS m
JOIN cis_highschool_map AS p ON m.Highschool = p.code
SET m.Highschool_label = p.label;

-- Column 9: Highest Edu
-- Inspect column
SELECT Highest_edu, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Highest_edu
ORDER BY Highest_edu;

-- Check for nulls 
SELECT
  SUM(CASE WHEN Highest_edu IS NULL THEN 1 ELSE 0 END) AS n_nulls
FROM cis_no_dupes;

-- Create mapping table 
CREATE TABLE cis_highestedu_map (
  code INT PRIMARY KEY,
  label VARCHAR(60)
);

-- Insert labels 
INSERT INTO cis_highestedu_map (code, label) VALUES
(1, 'Less than high school'),
(2, 'High school diploma'),
(3, 'College/Trade/Non-university'),
(4, 'University degree'),
(6, 'Not applicable'),
(9, 'Not stated');

-- Create column in main table 
ALTER TABLE cis_no_dupes
ADD COLUMN Highest_edu_label VARCHAR(60);

-- Populate label column 
UPDATE cis_no_dupes AS m
JOIN cis_highestedu_map AS p ON m.Highest_edu = p.code
SET m.Highest_edu_label = p.label;

-- Column 10: Work_ref
-- Inspect column
SELECT Work_ref, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Work_ref
ORDER BY Work_ref;

-- Check for nulls 
SELECT
  SUM(CASE WHEN Work_ref IS NULL THEN 1 ELSE 0 END) AS n_nulls
FROM cis_no_dupes;

-- Create mapping table 
CREATE TABLE cis_workref_map (
  code INT PRIMARY KEY,
  label VARCHAR(60)
);

INSERT INTO cis_workref_map (code, label) VALUES
(1, 'Employed'),
(2, 'Unemployed'),
(6, 'Retired');

-- Create label column 
ALTER TABLE cis_no_dupes
ADD COLUMN workref_label VARCHAR(60);

-- Populate label column
UPDATE cis_no_dupes AS m
JOIN cis_workref_map AS p
  ON m.Work_ref = p.code
SET m.workref_label = p.label;

-- Column 11: Work yearly 
-- Inspect column 
SELECT Work_yearly, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Work_yearly
ORDER BY Work_yearly;

-- Check for nulls
SELECT COUNT(*) AS null_count
FROM cis_no_dupes
WHERE Work_yearly IS NULL OR TRIM(Work_yearly) = '';

-- Clean invalid codes
UPDATE cis_no_dupes
SET Work_yearly = NULL
WHERE Work_yearly IN (96, 99);

SELECT Work_yearly, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Work_yearly
ORDER BY Work_yearly;

-- Column 12: Emp week ref
-- Check range
SELECT 
    MIN(Emp_week_ref) AS min_weeks,
    MAX(Emp_week_ref) AS max_weeks
FROM cis_no_dupes;

-- Check unique values and their counts
SELECT Emp_week_ref, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Emp_week_ref
ORDER BY Emp_week_ref;

-- Removing invalid codes
UPDATE cis_no_dupes
SET Emp_week_ref = NULL
WHERE Emp_week_ref > 52;

-- COLUMN 13: Total hours ref
-- Check min and max
SELECT MIN(Total_hour_ref) AS min_hours,
       MAX(Total_hour_ref) AS max_hours
FROM cis_no_dupes;

-- See distribution of values
SELECT Total_hour_ref, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Total_hour_ref
ORDER BY Total_hour_ref;

-- Check for nulls
SELECT COUNT(*) AS null_count
FROM cis_no_dupes
WHERE Total_hour_ref IS NULL OR TRIM(Total_hour_ref) = '';

-- Add a clean column
ALTER TABLE cis_no_dupes
ADD COLUMN Total_hour_ref_clean INT;

-- Populate the clean column
UPDATE cis_no_dupes
SET Total_hour_ref_clean = CASE
    WHEN Total_hour_ref > 5000 THEN NULL   
    ELSE Total_hour_ref                    
END;

-- Column 14: Paid emp ref
SELECT paid_emp_ref, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY paid_emp_ref
ORDER BY paid_emp_ref;

-- check for nulls
SELECT COUNT(*) AS null_count
FROM cis_no_dupes
WHERE paid_emp_ref IS NULL OR TRIM(Total_hour_ref) = '';

-- Add clean table
ALTER TABLE cis_no_dupes
ADD COLUMN paid_emp_ref_clean VARCHAR(20);

UPDATE cis_no_dupes
SET paid_emp_ref_clean = CASE
    WHEN paid_emp_ref IN (1,2) THEN paid_emp_ref
    WHEN paid_emp_ref = 6 THEN 'Retired'
END;

SELECT paid_emp_ref, paid_emp_ref_clean, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY paid_emp_ref, paid_emp_ref_clean
ORDER BY paid_emp_ref;

-- Column 15:Self emp ref
-- Inspect column 
SELECT self_emp_ref, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY self_emp_ref
ORDER BY self_emp_ref;

-- Check for NULLs
SELECT COUNT(*) AS null_count
FROM cis_no_dupes
WHERE self_emp_ref IS NULL;

-- Add a clean column 
ALTER TABLE cis_no_dupes
ADD COLUMN self_emp_ref_clean VARCHAR(20);

-- Populate clean column 
UPDATE cis_no_dupes
SET self_emp_ref_clean =
    CASE 
        WHEN self_emp_ref = 1 THEN 'Yes'       
        WHEN self_emp_ref = 2 THEN 'No'        
        WHEN self_emp_ref = 6 THEN 'Retired'   
    END;
    
    -- Column 16: Immigration
    -- Inspect column 
SELECT immigrant, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY immigrant
ORDER BY immigrant;

-- Check for nulls
SELECT COUNT(*) AS null_count
FROM cis_no_dupes
WHERE immigrant IS NULL;

-- Add clean column 
ALTER TABLE cis_no_dupes
ADD COLUMN immigrant_clean VARCHAR(20);

-- Populate with labels
UPDATE cis_no_dupes
SET immigrant_clean = CASE
    WHEN immigrant = 1 THEN 'Yes'
    WHEN immigrant = 2 THEN 'No'
    WHEN immigrant = 6 THEN 'Retired'
    WHEN immigrant = 9 THEN 'Not stated'
END;

-- Column 17: Year immigrant 
-- Inspect column 
SELECT year_immigrant, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY year_immigrant
ORDER BY year_immigrant;

-- Null check
SELECT COUNT(*) AS null_count
FROM cis_no_dupes
WHERE year_immigrant IS NULL;

-- Create clean column 
ALTER TABLE cis_no_dupes
ADD COLUMN year_immigrant_clean VARCHAR(50);

UPDATE cis_no_dupes
SET year_immigrant_clean = CASE
    WHEN year_immigrant = 1 THEN 'Before 1960'
    WHEN year_immigrant = 2 THEN '1960–1969'
    WHEN year_immigrant = 3 THEN '1970–1979'
    WHEN year_immigrant = 4 THEN '1980–1989'
    WHEN year_immigrant = 5 THEN '1990–1999'
    WHEN year_immigrant = 6 THEN '2000 and later'
    WHEN year_immigrant = 9 THEN 'Not stated'
END;

-- 1. Non-immigrants = no year
UPDATE cis_no_dupes
SET Year_immigrant_clean = NULL
WHERE Immigrant_clean = 'No';

-- 2. Retired = Retired
UPDATE cis_no_dupes
SET Year_immigrant_clean = 'Retired'
WHERE Immigrant_clean = 'Retired';

-- 3. Missing immigrant status = no year
UPDATE cis_no_dupes
SET Year_immigrant_clean = NULL
WHERE Immigrant_clean = 'Missing';

-- Column 18:Income after tax
-- Inspect column
SELECT 
    MIN(income_after_tax) AS min_income,
    MAX(income_after_tax) AS max_income,
    COUNT(*) AS total_rows
FROM cis_no_dupes;

SELECT DISTINCT income_after_tax, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY income_after_tax
ORDER BY income_after_tax DESC;

-- Create a clean version of the column
ALTER TABLE cis_no_dupes
ADD COLUMN income_after_tax_clean DECIMAL(15,2);

--  Copy valid values into the clean column
UPDATE cis_no_dupes
SET income_after_tax_clean = income_after_tax;

-- 3. Replace negative incomes with NULL
UPDATE cis_no_dupes
SET income_after_tax_clean = NULL
WHERE income_after_tax < 0;

-- Replace extreme outliers with NULL
UPDATE cis_no_dupes
SET income_after_tax_clean = NULL
WHERE income_after_tax >= 9999999;

-- Column 19: Cap gain
-- Inspect column 
SELECT DISTINCT Cap_gain, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Cap_gain
ORDER BY Cap_gain;

SELECT 
    MIN(Cap_gain) AS min_gain,
    MAX(Cap_gain) AS max_gain,
    AVG(Cap_gain) AS avg_gain,
    COUNT(*) AS total_rows
FROM cis_no_dupes;

-- Removing outlier
UPDATE cis_no_dupes
SET Cap_gain = NULL
WHERE Cap_gain = 99999996.00;

-- Column 20 : Childcare expenses
-- Inspect 

SELECT 
    MIN(Childcare_expe) AS min_val,
    MAX(Childcare_expe) AS max_val,
    COUNT(*) AS total_count,
    SUM(CASE WHEN Childcare_expe IS NULL THEN 1 ELSE 0 END) AS null_count
FROM cis_no_dupes;

SELECT DISTINCT Childcare_expe, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Childcare_expe
ORDER BY Childcare_expe;

UPDATE cis_no_dupes
SET Childcare_expe = NULL
WHERE Childcare_expe = 99999996.00;

UPDATE cis_no_dupes
SET Childcare_expe = 0.00
WHERE Childcare_expe = 0;

-- Column 22: Child benefit

SELECT Child_benefit, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Child_benefit
ORDER BY Child_benefit;

UPDATE cis_no_dupes
SET Child_benefit = NULL
WHERE Child_benefit = 99999996.00;

-- Column 23: CPP_QPP
SELECT CPP_QPP, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY CPP_QPP
ORDER BY CPP_QPP;

UPDATE cis_no_dupes
SET CPP_QPP = NULL
WHERE CPP_QPP = 99999996.00;

-- Column 24: Earnings
SELECT Earning, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Earning
ORDER BY Earning;

UPDATE cis_no_dupes
SET Earning = NULL
WHERE Earning = 99999996.00 OR Earning <0;

-- Column 25: Guaranteed income 
SELECT Guaranteed_income, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Guaranteed_income
ORDER BY Guaranteed_income;

UPDATE cis_no_dupes
SET Guaranteed_income = NULL
WHERE Guaranteed_income = 99999996.00;

 -- Column 26: Investment
 SELECT Investment, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Investment
ORDER BY Investment;

UPDATE cis_no_dupes
SET Investment = NULL
WHERE Investment = 99999996.00 OR Investment <0;

-- Column 27: Old age pension
SELECT Old_age_pension, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Old_age_pension
ORDER BY Old_age_pension;

UPDATE cis_no_dupes
SET Old_age_pension = NULL
WHERE Old_age_pension = 99999996.00;

-- Column 28: Private pension
SELECT Private_pension, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Private_pension
ORDER BY Private_pension;

UPDATE cis_no_dupes
SET Private_pension = NULL
WHERE Private_pension = 99999996.00;

-- Column 29: Self emp income
SELECT Self_emp_income, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Self_emp_income
ORDER BY Self_emp_income;

UPDATE cis_no_dupes
SET Self_emp_income = NULL
WHERE Self_emp_income = 99999996.00 OR Self_emp_income <0;

-- Column 30: Pension
SELECT Pension, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Pension
ORDER BY Pension;

UPDATE cis_no_dupes
SET Pension = NULL
WHERE Pension = 99999996.00;

-- Column 31: Total income
SELECT Total_income, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Total_income
ORDER BY Total_income;

UPDATE cis_no_dupes
SET Total_income = NULL
WHERE Total_income <0;

-- Column 32: Emp insurance
SELECT Emp_insurance, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Emp_insurance
ORDER BY Emp_insurance;

UPDATE cis_no_dupes
SET Emp_insurance = NULL
WHERE Emp_insurance <0;

-- Column 33: Salary wages
SELECT Salary_wages, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Salary_wages
ORDER BY Salary_wages;

-- Column 34: Compensation
SELECT compensation, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY compensation
ORDER BY compensation;

-- Column 35: Family members
SELECT Family_mem, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY Family_mem
ORDER BY Family_mem;

UPDATE cis_no_dupes
SET Family_mem = NULL
WHERE Family_mem > 20;

-- Column 36: CFCOMP

SELECT CFCOMP, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY CFCOMP
ORDER BY CFCOMP;

-- Create column for readable labels
ALTER TABLE cis_no_dupes
ADD COLUMN CFCOMP_Clean VARCHAR(100);

UPDATE cis_no_dupes
SET CFCOMP_Clean = CASE 
    WHEN CFCOMP = 1 THEN 'Couple with children'
    WHEN CFCOMP = 2 THEN 'Couple without children'
    WHEN CFCOMP = 3 THEN 'Lone-parent (female)'
    WHEN CFCOMP = 4 THEN 'Lone-parent (male)'
    WHEN CFCOMP = 5 THEN 'One-person household'
    WHEN CFCOMP = 6 THEN 'Other family household'
    WHEN CFCOMP = 7 THEN 'Non-family household'
END;

-- Column 37: CONDMP
SELECT DISTINCT CONDMP
FROM cis_no_dupes
ORDER BY CONDMP;

ALTER TABLE cis_no_dupes
ADD COLUMN CONDMP_Clean VARCHAR(100);

UPDATE cis_no_dupes
SET CONDMP_Clean = CASE 
    WHEN CONDMP = 1 THEN 'Single detached house'
    WHEN CONDMP = 2 THEN 'Semi-detached house'
    WHEN CONDMP = 3 THEN 'Row house / Townhouse'
    WHEN CONDMP = 4 THEN 'Apartment, duplex'
    WHEN CONDMP = 5 THEN 'Apartment <5 storeys'
    WHEN CONDMP = 6 THEN 'Apartment ≥5 storeys'
    WHEN CONDMP = 7 THEN 'Other dwelling type'
    WHEN CONDMP = 9 THEN 'Not stated'
END;

-- Column 38: RENTM
-- Inspect column 
SELECT MIN(RENTM) AS min_val,
       MAX(RENTM) AS max_val,
       COUNT(*) AS total_records
FROM cis_no_dupes;

SELECT DISTINCT RENTM
FROM cis_no_dupes
ORDER BY RENTM;

SELECT RENTM, COUNT(*) AS freq
FROM cis_no_dupes
GROUP BY RENTM
ORDER BY RENTM;

ALTER TABLE cis_no_dupes
ADD COLUMN RENTM_Clean VARCHAR(50);

UPDATE cis_no_dupes
SET RENTM_Clean = CASE
    WHEN RENTM = 0.00 THEN 'No rent / Not applicable'
    WHEN RENTM = 99999996.00 THEN 'Not stated'
    ELSE CAST(RENTM AS CHAR)
END;

-- ANALYSIS 
-- 1. POPULATION OVERVIEW

-- Step 1: Count total unique individuals
SELECT COUNT(DISTINCT PersonID) AS Total_individuals
FROM cis_no_dupes;

-- Step 2: Gender distribution by percentage
SELECT Gender_label, COUNT(*) AS freq,
ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM cis_no_dupes), 2) AS percentage
FROM cis_no_dupes
GROUP BY Gender_label
ORDER BY Gender_label;

-- Step 3: Immigrant distribution by percentage
ALTER TABLE cis_no_dupes
DROP COLUMN year_immigrant_label;

ALTER TABLE cis_no_dupes
RENAME COLUMN immigrant_clean TO immigrant_label;

SELECT Immigrant_label, COUNT(*) AS freq,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM cis_no_dupes), 2) AS percentage
FROM cis_no_dupes
GROUP BY Immigrant_label
ORDER BY Immigrant_label;

-- Step 4: Age gap distribution (grouped) by percentage

SELECT Age_gap_label, COUNT(*) AS freq,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM cis_no_dupes), 2) AS percentage
FROM cis_no_dupes
GROUP BY Age_gap_label
ORDER BY Age_gap_label;

-- 2. EMPLOYMENT AND WORK PATTERNS

-- Step 1: Distribution of employment status (employed, unemployed, retired, etc.).
SELECT workref_label,
       COUNT(*) AS count,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM cis_no_dupes), 2) AS percentage
FROM cis_no_dupes
GROUP BY workref_label
ORDER BY count DESC;

-- Step 2: Employment Patterns by Province/Region
SELECT Province,
       workref_label,
       COUNT(*) AS count
FROM cis_no_dupes
GROUP BY Province, workref_label
ORDER BY Province, count DESC;

-- 3. INCOME ANALYSIS

-- Step 1: Average Total Income
-- Average Total Income
SELECT 
    ROUND(AVG(income_after_tax_clean), 2) AS avg_income
FROM cis_no_dupes;

-- Step 2: Breakdown of Income Sources: How much each income source contributes on average.
-- Average income from each source
SELECT 
    ROUND(AVG(Salary_wages), 2) AS avg_salary,
    ROUND(AVG(Self_emp_income), 2) AS avg_self_emp,
    ROUND(AVG(Pension), 2) AS avg_pension,
    ROUND(AVG(Private_pension), 2) AS avg_private_pension,
    ROUND(AVG(Investment), 2) AS avg_investment,
    ROUND(AVG(Old_age_pension), 2) AS avg_old_age_pension,
    ROUND(AVG(Guaranteed_income), 2) AS avg_guaranteed_income,
    ROUND(AVG(Emp_insurance), 2) AS avg_emp_insurance,
    ROUND(AVG(Compensation), 2) AS avg_compensation,
    ROUND(AVG(Cap_gain), 2) AS avg_cap_gain,
    ROUND(AVG(Child_benefit), 2) AS avg_child_benefit,
    ROUND(AVG(Earning), 2) AS avg_Earning
FROM cis_no_dupes;

-- Step 3: Compare Income Levels Between Provinces/Regions
-- Average income by province/region
SELECT 
    m.label AS province,
    ROUND(AVG(c.income_after_tax_clean), 2) AS avg_income
FROM cis_no_dupes c
JOIN CIS_province_map m ON c.Province = m.code
GROUP BY m.label
ORDER BY avg_income DESC;

-- Step 4: Income difference by Immigraton status
-- Average income by immigrant status
SELECT 
    Immigrant_label AS immigrant_status,
    ROUND(AVG(income_after_tax_clean), 2) AS avg_income
FROM cis_no_dupes
GROUP BY Immigrant_label
ORDER BY avg_income DESC;

-- 4. GOVERNMENT SUPPORT AND BENEFITS

-- Step 1: How many individuals receive CPP/QPP, OAS, Guaranteed Income, Employment Insurance?

SELECT 
    SUM(CASE WHEN CPP_QPP > 0 THEN 1 ELSE 0 END) AS cpp_qpp_recipients,
    SUM(CASE WHEN Old_age_pension > 0 THEN 1 ELSE 0 END) AS oas_recipients,
    SUM(CASE WHEN Guaranteed_income > 0 THEN 1 ELSE 0 END) AS gis_recipients,
    SUM(CASE WHEN Emp_insurance > 0 THEN 1 ELSE 0 END) AS ei_recipients
FROM cis_no_dupes;

-- Step 2: Average benefits amounts received by Province

SELECT 
    m.label AS province,
    ROUND(AVG(CPP_QPP), 2) AS avg_cpp_qpp,
    ROUND(AVG(Old_age_pension), 2) AS avg_oas,
    ROUND(AVG(Guaranteed_income), 2) AS avg_gis,
    ROUND(AVG(Emp_insurance), 2) AS avg_ei
FROM cis_no_dupes c
JOIN CIS_province_map m ON c.Province = m.code
GROUP BY m.label
ORDER BY avg_cpp_qpp DESC;

-- Step 3: Relationship between childcare expenses and child benefits received
SELECT 
    ROUND(AVG(Childcare_expe), 2) AS avg_childcare_expe,
    ROUND(AVG(Child_benefit), 2) AS avg_child_benefit
FROM cis_no_dupes
WHERE Childcare_expe > 0 OR Child_benefit > 0;


-- 5. Capital Gains Distribution: We want to see who earns the most from investments (capital gains).

SELECT 
    CASE 
        WHEN Cap_gain = 0 THEN 'No Capital Gains'
        WHEN Cap_gain BETWEEN 1 AND 10000 THEN 'Low (1–10k)'
        WHEN Cap_gain BETWEEN 10001 AND 50000 THEN 'Medium (10k–50k)'
        WHEN Cap_gain > 50000 THEN 'High (50k+)'
    END AS gain_category,
    COUNT(*) AS num_people,
    ROUND(AVG(income_after_tax), 2) AS avg_total_income
FROM cis_no_dupes
WHERE Cap_gain IS NOT NULL
GROUP BY gain_category
ORDER BY gain_category;
























































 




















    
    









































































