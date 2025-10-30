CREATE DATABASE MNC_DB;

USE MNC_DB;

CREATE TABLE HR_Data (
    Employee_ID INT PRIMARY KEY,
    Full_Name VARCHAR(100),
    Gender VARCHAR(10),
    Department VARCHAR(50),
    Job_Title VARCHAR(100),
    Hire_Date TEXT,
    Experience_Years INT,
    Salary_INR DECIMAL(12,2),
    Performance_Rating DECIMAL(3,2),
    Status VARCHAR(20),
    Work_Mode VARCHAR(20),
    City VARCHAR(50),
    Country VARCHAR(50)
);


SELECT	*
FROM HR_DATA;

SELECT COUNT(*)
FROM hr_data;

CREATE VIEW cl_hr_data AS (
        SELECT
            employee_id,
            full_name,
            department,
            job_title,
            (STR_TO_DATE(hire_date, '%d-%m-%Y')) AS date_of_hire,
            LEFT(location,LOCATE(',', location)-1) AS City,
            RIGHT(location,LENGTH(location)-LOCATE(',',location)) AS Country,
            performance_rating,
            experience_years,
            status,
            work_mode,
            salary_inr
        FROM hr_data
);


---------------------------------------------------problem statement--------------------------------------------------------------------------------------------------------------------



-- Q1. Find the top 5 highest-paid employees in each department.
WITH top_emp AS (
SELECT
    department,
    employee_id,
    full_name,
    salary_inr,
    RANK() OVER(PARTITION BY department ORDER BY salary_inr DESC) AS rnks
FROM hr_data
)
SELECT
    department,
    employee_id,
    full_name,
    salary_inr,
    rnks
FROM top_emp
WHERE rnks <=5;




-- Q2. Calculate the average salary by department and work mode.
SELECT
    h1.department,
    h1.work_mode,
    dept_avg,
    ROUND(AVG(h1.salary_inr),2) AS avg_salary
FROM hr_data h1
JOIN  (
    SELECT department,
            ROUND(AVG(salary_inr),2) AS dept_avg
    FROM hr_data
    GROUP BY department
    ) h2
ON h1.department = h2.department
GROUP BY h1.department, h1.work_mode, h2.dept_avg
ORDER BY department;






-- Q3. Find the department with the highest attrition rate (Resigned %).
WITH cte_total AS (
SELECT
    department,
    COUNT(*) AS dept_total
FROM hr_data
GROUP BY department
),
cte_reg AS (
        SELECT
            department,
            COUNT(*) AS reg_total
        FROM hr_data
        WHERE status = 'resigned'
        GROUP BY department
)
SELECT 
    ct.department,
    ct.dept_total,
    cr.reg_total,
    CONCAT(
        ROUND(100 * cr.reg_total / ct.dept_total, 2)
        ,'%') AS resign_rate
FROM cte_total ct
JOIN cte_reg cr 
ON ct.department = cr.department;



-- Q4. Show the average performance rating by experience level (0-2 yrs, 3-5 yrs, 6-10 yrs, 10+ yrs).
SELECT 
    CASE 
        WHEN experience_years <=2 THEN '0-2' 
        WHEN experience_years <=5 THEN '3-5'
        WHEN experience_years <=10 THEN '6-10'
        ELSE  '10+'
    END AS exp_level,
    ROUND(AVG(performance_rating),2) AS avg_performance_rating
FROM hr_data
GROUP BY CASE 
        WHEN experience_years <=2 THEN '0-2' 
        WHEN experience_years <=5 THEN '3-5'
        WHEN experience_years <=10 THEN '6-10'
        ELSE  '10+'
        END;




-- Q5. Find the year with the highest number of hires.
SELECT
    YEAR(date_of_hire) AS year,
    COUNT(*) AS no_of_employees
FROM cl_hr_data
GROUP BY year
ORDER BY no_of_employees DESC
;




-- Q6. Identify employees whose salary is above the department average.
SELECT
    h1.employee_id,
    h1.full_name,
    h1.salary_inr,
    h2.dept_avg
FROM hr_data h1 
JOIN (
        SELECT
            department,
            ROUND(AVG(salary_inr),2) AS dept_avg
        FROM hr_data
        GROUP BY department
) h2
ON h1.department = h2.department
WHERE h1.salary_inr > h2.dept_avg;






-- Q7. Show the average salary difference between Remote, and On-site workers.
WITH avg_salary AS (
SELECT
    work_mode,
    ROUND(AVG(salary_inr),2) AS avg_salary
FROM hr_data
GROUP BY work_mode
)
SELECT 
    Work_Mode,
    avg_salary,
    avg_salary - LEAD(avg_salary) OVER() AS salary_diff
FROM avg_salary ;



-- Q8. Find the top 3 job titles with the highest average performance rating.
SELECT
    job_title,
    ROUND(AVG(performance_rating),2) AS avg_pf_rating
FROM hr_data
GROUP BY job_title
ORDER BY avg_pf_rating DESC
LIMIT 3;





-- Q9. Compare active vs resigned employees' average salary and experience.
SELECT
    status,
    ROUND(AVG(salary_inr),2) AS avg_salary,
    ROUND(AVG(experience_years)) AS avg_exp
FROM hr_data
GROUP BY status;




-- Q10. For each department, find the most common job title.
WITH cmn_job_title AS (
SELECT
    department,
    job_title,
    COUNT(*) AS no_of_emp,
    RANK() OVER(PARTITION BY Department ORDER BY COUNT(*) DESC) AS rnks
FROM hr_data
GROUP BY department, job_title
ORDER BY department
)
SELECT
    department,
    job_title,
    no_of_emp,
    rnks
FROM cmn_job_title
WHERE rnks = 1;




-- Q11. Find the top 3 highest-paid employees in each department and experience level.
WITH top_paid_emp AS (
SELECT
    Department,
    Employee_ID,
    Full_Name,
    Experience_Years,
    salary_inr,
    RANK() OVER(PARTITION BY Department ORDER BY salary_inr DESC) AS ranks
FROM hr_data
)
SELECT *
FROM top_paid_emp
WHERE ranks <= 3;







-- Q12. Calculate the percentage of employees in each department who earn above their department’s average salary.
WITH cte_dept AS (
        SELECT
            department,
            AVG(salary_inr) AS dept_avg_salary,
            COUNT(*) AS person_per_dept
        FROM hr_data
        GROUP BY department
),
        above_dept_avg AS (
        SELECT
            h.department,
            COUNT(*) AS above_person
        FROM hr_data h
        JOIN cte_dept c
        ON h.department = c.department
        WHERE h.salary_inr > c.dept_avg_salary
        GROUP BY h.department
)
SELECT
    cd.department,
    CONCAT(
        ROUND(100 * ad.above_person / cd.person_per_dept,2)
        ,'%') AS '%_of_emp'
FROM cte_dept cd 
JOIN above_dept_avg ad 
ON cd.department = ad.department ;





-- Q13. Determine the attrition rate (%) per department and work mode, and rank the departments by highest attrition.
WITH cte_total AS (
                SELECT
                    department,
                    COUNT(*) AS total_person_per_dept
                FROM hr_data
                GROUP BY department
),
cte_resign AS (
                SELECT
                    department,
                    COUNT(*) as resign_person_per_dept
                FROM hr_data
                WHERE status = 'resigned'
                GROUP BY department
)
SELECT
    ct.department,
    CONCAT(
        ROUND(
        100 * cr.resign_person_per_dept / ct.total_person_per_dept
        ,2)
    ,'%') AS attrition_rate,
    RANK() OVER(ORDER BY 100 * cr.resign_person_per_dept / ct.total_person_per_dept desc) AS ranks
FROM cte_total ct
JOIN cte_resign cr
ON ct.department = cr.department;








-- Q14. Find the correlation between experience years and salary across departments to see where experience impacts pay the most.
SELECT 
    department,
    (
        (AVG(experience_years * salary_inr) - (AVG(experience_years) * AVG(salary_inr)))
        /
        (STDDEV(experience_years) * STDDEV(salary_inr))
    ) AS exp_salary_corr
FROM hr_data
GROUP BY department
ORDER BY exp_salary_corr DESC;

