-- SkyFix SQL Analysis: 10 business questions on aircraft maintenance data
-- Database: skyfix.db (SQLite, synthetic practice data)
-- Run all:  sqlite3 -header -column skyfix.db < queries.sql

-- Q1: How many work orders per status?
SELECT status, COUNT(*) AS n FROM work_orders GROUP BY status ORDER BY n DESC;

-- Q2: Total cost and average hours per task type
SELECT task_type, COUNT(*) AS n, SUM(cost) AS total_cost, ROUND(AVG(hours),1) AS avg_hours
FROM work_orders GROUP BY task_type ORDER BY total_cost DESC;

-- Q3: Which airline has the highest maintenance cost?
SELECT a.airline, COUNT(w.wo_id) AS n_orders, SUM(w.cost) AS total_cost
FROM aircraft a JOIN work_orders w ON a.aircraft_id = w.aircraft_id
GROUP BY a.airline ORDER BY total_cost DESC;

-- Q4: Aircraft that were NEVER serviced
SELECT a.registration, a.model, a.airline
FROM aircraft a LEFT JOIN work_orders w ON a.aircraft_id = w.aircraft_id
WHERE w.wo_id IS NULL;

-- Q5: Technicians with number of orders and total hours (incl. those with none)
SELECT t.name, t.department, COUNT(w.wo_id) AS n_orders, ROUND(COALESCE(SUM(w.hours),0),1) AS total_hours
FROM technicians t LEFT JOIN work_orders w ON t.tech_id = w.tech_id
GROUP BY t.name, t.department ORDER BY total_hours DESC;

-- Q6: Delay rate (%) per aircraft model
SELECT a.model, COUNT(*) AS n,
       SUM(CASE WHEN w.status = 'Delayed' THEN 1 ELSE 0 END) AS n_delayed,
       ROUND(100.0 * SUM(CASE WHEN w.status = 'Delayed' THEN 1 ELSE 0 END) / COUNT(*), 1) AS delay_pct
FROM work_orders w JOIN aircraft a ON w.aircraft_id = a.aircraft_id
GROUP BY a.model ORDER BY delay_pct DESC;

-- Q7: Top 5 most expensive parts spend (qty * unit_price)
SELECT part_name, SUM(qty) AS total_qty, SUM(qty * unit_price) AS spend
FROM parts_used GROUP BY part_name ORDER BY spend DESC LIMIT 5;

-- Q8: Orders per month (2026) with cost
SELECT SUBSTR(opened_date,1,7) AS month, COUNT(*) AS n, SUM(cost) AS total_cost
FROM work_orders GROUP BY month ORDER BY month;

-- Q9: Departments whose average hours per order exceeds 18 (HAVING, 2 joins)
SELECT t.department, COUNT(*) AS n, ROUND(AVG(w.hours),1) AS avg_hours
FROM work_orders w JOIN technicians t ON w.tech_id = t.tech_id
GROUP BY t.department HAVING AVG(w.hours) > 18;

-- Q10: Total cost of work orders INCLUDING parts, top 5 orders (3 tables)
SELECT w.wo_id, a.registration, w.cost AS labour_cost,
       COALESCE(SUM(p.qty*p.unit_price),0) AS parts_cost,
       w.cost + COALESCE(SUM(p.qty*p.unit_price),0) AS total
FROM work_orders w
JOIN aircraft a ON w.aircraft_id = a.aircraft_id
LEFT JOIN parts_used p ON w.wo_id = p.wo_id
GROUP BY w.wo_id, a.registration, w.cost
ORDER BY total DESC LIMIT 5;
