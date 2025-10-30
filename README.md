# 🏢 MNC Data Analysis using SQL

**Comprehensive Analysis of Employee Records, Salaries, Performance Metrics, and Attrition Patterns**  

Using advanced SQL techniques — **CTEs, Window Functions, Aggregations, and Joins** 

**Dataset:** [Kaggle](https://www.kaggle.com/datasets/rohitgrewal/hr-data-mnc) 

**Presented by:** Suman Saha  

**Role:** Data Analyst  

**Date:** 10-09-2025  

---

## 🧭 Dataset Overview

### 📂 MNC Data Structure
Our dataset (`mnc_data`) contains **1,048,575 employee records** across multiple dimensions:

| Category | Description |
|-----------|-------------|
| 👤 Employee Demographics | ID, Name, Location Data |
| 🏢 Organizational Data | Department, Job Title, Work Mode |
| 📈 Performance Metrics | Ratings, Experience, Status |
| 💰 Compensation | Salary Data in INR |

---

### 🧹 Data Preparation

Created a **clean view** `cl_hr_data` with refined location and standardized date formatting.

```sql
CREATE VIEW cl_hr_data AS (
    SELECT
        employee_id,
        full_name,
        department,
        job_title,
        STR_TO_DATE(hire_date, '%d-%m-%Y') AS date_of_hire,
        LEFT(location, LOCATE(',', location) - 1) AS City,
        RIGHT(location, LENGTH(location) - LOCATE(',', location)) AS Country,
        performance_rating,
        experience_years,
        status,
        work_mode,
        salary_inr
    FROM hr_data
);
```

---

## 🎯 Strategic Problem Statement

1. **Salary Trend Analysis** — Identify patterns to ensure fair and competitive pay.  
2. **Performance Insights** — Assess performance ratings to guide employee development.  
3. **Attrition Intelligence** — Detect turnover risks to improve retention strategies.

---

## 🧮 Key SQL Analysis

---

### **Q1. Find the top 5 highest-paid employees in each department.**

```sql
WITH top_emp AS (
    SELECT
        department,
        employee_id,
        full_name,
        salary_inr,
        RANK() OVER (PARTITION BY department ORDER BY salary_inr DESC) AS rnks
    FROM hr_data
)
SELECT department, employee_id, full_name, salary_inr, rnks
FROM top_emp
WHERE rnks <= 5;
```
**Insight:** Highlights top performers and salary outliers across departments.

---

### **Q2. Calculate the average salary by department and work mode.**

```sql
SELECT
    h1.department,
    h1.work_mode,
    dept_avg,
    ROUND(AVG(h1.salary_inr), 2) AS avg_salary
FROM hr_data h1
JOIN (
    SELECT department, ROUND(AVG(salary_inr), 2) AS dept_avg
    FROM hr_data
    GROUP BY department
) h2 ON h1.department = h2.department
GROUP BY h1.department, h1.work_mode, h2.dept_avg
ORDER BY department;
```
**Insight:** Reveals cost distribution across departments and work setups (Remote vs On-site).

---

### **Q3. Find the department with the highest attrition rate (Resigned %).**

```sql
WITH cte_total AS (
    SELECT department, COUNT(*) AS dept_total FROM hr_data GROUP BY department
),
cte_reg AS (
    SELECT department, COUNT(*) AS reg_total FROM hr_data
    WHERE status = 'resigned' GROUP BY department
)
SELECT
    ct.department,
    ct.dept_total,
    cr.reg_total,
    CONCAT(ROUND(100 * cr.reg_total / ct.dept_total, 2), '%') AS resign_rate
FROM cte_total ct
JOIN cte_reg cr ON ct.department = cr.department;
```
**Insight:** Identifies departments with retention challenges.

---

### **Q4. Show the average performance rating by experience level.**

```sql
SELECT
    CASE
        WHEN experience_years <= 2 THEN '0-2'
        WHEN experience_years <= 5 THEN '3-5'
        WHEN experience_years <= 10 THEN '6-10'
        ELSE '10+'
    END AS exp_level,
    ROUND(AVG(performance_rating), 2) AS avg_performance_rating
FROM hr_data
GROUP BY
    CASE
        WHEN experience_years <= 2 THEN '0-2'
        WHEN experience_years <= 5 THEN '3-5'
        WHEN experience_years <= 10 THEN '6-10'
        ELSE '10+'
    END;
```
**Insight:** Evaluates if more experience translates into higher performance.

---

### **Q5. Find the year with the highest number of hires.**

```sql
SELECT
    YEAR(date_of_hire) AS year,
    COUNT(*) AS no_of_employees
FROM cl_hr_data
GROUP BY year
ORDER BY no_of_employees DESC;
```
**Insight:** Identifies peak recruitment years.

---

### **Q6. Identify employees whose salary is above the department average.**

```sql
SELECT
    h1.employee_id,
    h1.full_name,
    h1.salary_inr,
    h2.dept_avg
FROM hr_data h1
JOIN (
    SELECT department, ROUND(AVG(salary_inr), 2) AS dept_avg
    FROM hr_data
    GROUP BY department
) h2 ON h1.department = h2.department
WHERE h1.salary_inr > h2.dept_avg;
```
**Insight:** Highlights high performers or salary imbalances.

---

### **Q7. Show the average salary difference between Remote and On-site workers.**

```sql
WITH avg_salary AS (
    SELECT work_mode, ROUND(AVG(salary_inr), 2) AS avg_salary
    FROM hr_data
    GROUP BY work_mode
)
SELECT
    work_mode,
    avg_salary,
    avg_salary - LEAD(avg_salary) OVER () AS salary_diff
FROM avg_salary;
```
**Insight:** Compares compensation differences based on work mode.

---

### **Q8. Find the top 3 job titles with the highest average performance rating.**

```sql
SELECT
    job_title,
    ROUND(AVG(performance_rating), 2) AS avg_pf_rating
FROM hr_data
GROUP BY job_title
ORDER BY avg_pf_rating DESC
LIMIT 3;
```
**Insight:** Identifies job roles that consistently attract top performers.

---

### **Q9. Compare active vs resigned employees' average salary and experience.**

```sql
SELECT
    status,
    ROUND(AVG(salary_inr), 2) AS avg_salary,
    ROUND(AVG(experience_years)) AS avg_exp
FROM hr_data
GROUP BY status;
```
**Insight:** Shows whether higher pay or experience reduces attrition.

---

### **Q10. For each department, find the most common job title.**

```sql
WITH cmn_job_title AS (
    SELECT
        department,
        job_title,
        COUNT(*) AS no_of_emp,
        RANK() OVER (PARTITION BY department ORDER BY COUNT(*) DESC) AS rnks
    FROM hr_data
    GROUP BY department, job_title
)
SELECT department, job_title, no_of_emp
FROM cmn_job_title
WHERE rnks = 1;
```
**Insight:** Reveals dominant roles within each department.

---

### **Q11. Find the top 3 highest-paid employees in each department and experience level.**

```sql
WITH top_paid_emp AS (
    SELECT
        department,
        employee_id,
        full_name,
        experience_years,
        salary_inr,
        RANK() OVER (PARTITION BY department ORDER BY salary_inr DESC) AS ranks
    FROM hr_data
)
SELECT * FROM top_paid_emp WHERE ranks <= 3;
```
**Insight:** Highlights top-paid employees across departments and seniority levels.

---

### **Q12. Calculate % of employees in each department earning above average salary.**

```sql
WITH cte_dept AS (
    SELECT department, AVG(salary_inr) AS dept_avg_salary, COUNT(*) AS person_per_dept
    FROM hr_data
    GROUP BY department
),
above_dept_avg AS (
    SELECT h.department, COUNT(*) AS above_person
    FROM hr_data h
    JOIN cte_dept c ON h.department = c.department
    WHERE h.salary_inr > c.dept_avg_salary
    GROUP BY h.department
)
SELECT
    cd.department,
    CONCAT(ROUND(100 * ad.above_person / cd.person_per_dept, 2), '%') AS percent_above_avg
FROM cte_dept cd
JOIN above_dept_avg ad ON cd.department = ad.department;
```
**Insight:** Measures pay competitiveness within departments.

---

### **Q13. Determine attrition rate per department and work mode, ranked highest to lowest.**

```sql
WITH cte_total AS (
    SELECT department, COUNT(*) AS total_person_per_dept FROM hr_data GROUP BY department
),
cte_resign AS (
    SELECT department, COUNT(*) AS resign_person_per_dept
    FROM hr_data WHERE status = 'resigned' GROUP BY department
)
SELECT
    ct.department,
    CONCAT(ROUND(100 * cr.resign_person_per_dept / ct.total_person_per_dept, 2), '%') AS attrition_rate,
    RANK() OVER (ORDER BY 100 * cr.resign_person_per_dept / ct.total_person_per_dept DESC) AS ranks
FROM cte_total ct
JOIN cte_resign cr ON ct.department = cr.department;
```
**Insight:** Identifies risky departments and work modes with high attrition.

---

### **Q14. Correlation between experience and salary across departments.**

```sql
SELECT
    department,
    (
        (AVG(experience_years * salary_inr) - (AVG(experience_years) * AVG(salary_inr)))
        / (STDDEV(experience_years) * STDDEV(salary_inr))
    ) AS exp_salary_corr
FROM hr_data
GROUP BY department
ORDER BY exp_salary_corr DESC;
```
**Insight:** Measures how strongly experience impacts pay in each department.

---

## 🧩 Company Insights & Future Growth

- 🧍‍♂️ Departments with **high attrition** need urgent HR intervention.  
- 💰 Salary gaps between **remote vs on-site** require equity review.  
- ⭐ Some departments **reward performance better** than others.  
- 📊 Experience-to-salary correlation helps ensure **fair pay growth**.  
- 🧠 Insights guide **hiring, retention, and HR strategy optimization**.

---

## 🙏 Thank You  
**Suman Saha — Data Analyst**  
*Questions & Discussion Welcome*



