# Canadian-Income-survey-Financial-Analysis
### Table of content
- [Project overview](Project-overview)
- [Data sources](Data-sources)
- [Data set overview](Data-set-overview)
- [Tools](Tools)
- [Data cleaning](Data-cleaning)
- [Analysis questions](Analysis-questions)
- [Key Insights](Key-Insights)
- [Conclusion](Conclusion)


### Project overview
This project analyzes Canadian income, employment patterns, and government benefits using a survey dataset.
The goal was to clean messy survey data, transform coded values into meaningful categories, and generate insights on employment, income sources, and immigrant outcomes.


### Data Sources
The dataset used for this analysis is sourced from kaggle [Download here](https://www.kaggle.com/datasets/aradhanahirapara/income-survey-finance-analysis?select=Income+Survey+Dataset.csv)

### Dataset Overview
The CIS (Canadian Income Survey) Dataset contains detailed demographic, economic, and employment-related data of individuals across different provinces in Canada. The dataset is designed to assess key factors affecting income levels, employment history, and financial well-being at an individual level.

Dataset Description: 
- Rows: 72,643 individuals
- Columns: Total Variables 36
Data Type: A mix of categorical, numerical, and binary data. 
Raw dataset contained coded fields for demographics and placeholder values like 99999996 for missing data.

### Tools
- SQL - Used for data cleaning and Analysis

### Data cleaning / Preparation

- Converted categorical codes into readable labels (e.g., 1 = Male, 2 = Female, 35= Ontario, 48 = Alberta)
- Created age groups
- Standardized monetary columns into consistent numeric types
- Removed unrealistic/outlier values
- Replaced placeholder values with NULL

### Analysis Questons
- EMPLOYMENT AND WORK PATTERNS: Distribution of employment status, Employment Patterns by Province/Region
- INCOME ANALYSIS: Average Total Income, Breakdown of Income Sources, Comparision of Income Levels Between Provinces/Regions, Income difference by Immigraton status
- GOVERNMENT SUPPORT AND BENEFITS: How many individuals benefit, Average benefits amounts received by Provinces
- CAPITAL GAIN DISTRIBUTION

### Key Insights
- Majority of individuals are employed. Employed -53.91%, unemployed -28.43%, retired -17.66%
- Salary/wages are the main source of income, pensions & government transfers important for retirees.
- Benefits play a strong role in supplementing low-income groups.
- Capital gains: Concentrated among higher-income individuals.
- Employemnt by province: Ontario recorded the highest employment, followed by Quebec and British Columbia. Prince Edward Island recorded the lowest among all provinces.
- Immigrant status: Majority non-immigrant, -11.55% immigrants.
- Immigrants have lower average weeks worked compared to non-immigrants.
- Employment participation rates remain competitive despite the gap between immigrants and non immigrants.

### Conclusion

Income distribution is skewed, with high earners driving up averages  

Immigrants face slightly lower work weeks but remain strongly engaged in the labor force  

This project highlights the importance of data cleaning, structured SQL analysis, and clear reporting in real-world datasets.



