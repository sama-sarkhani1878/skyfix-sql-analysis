# SkyFix: SQL Analysis of Aircraft Maintenance Data

10 business questions answered with plain SQL (SQLite) on a small maintenance database for four fictional airlines.
Good as a **practice dataset** or a **template** for maintenance / operations analytics.

> **Note:** all data is **synthetic**, generated for practice. It does not describe any real airline.

## Quick start (no setup beyond SQLite)

```bash
git clone https://github.com/sama-sarkhani1878/skyfix-sql-analysis.git
cd skyfix-sql-analysis
sqlite3 -header -column skyfix.db < queries.sql      # run all 10 queries
```
Or open `skyfix.db` in [DB Browser for SQLite](https://sqlitebrowser.org/) (free) and paste any query from `queries.sql`.

## Data model

| Table | Rows | Columns |
|---|---|---|
| `aircraft` | 20 | aircraft_id, registration, model, airline |
| `technicians` | 12 | tech_id, name, department |
| `work_orders` | 200 | wo_id, aircraft_id, tech_id, task_type, status, hours, cost, opened_date |
| `parts_used` | 178 | wo_id, part_name, qty, unit_price |

```
aircraft 1──∞ work_orders ∞──1 technicians
                  1
                  │
                  ∞
             parts_used
```
Dates cover 2026-01-02 to 2026-09-28. Four aircraft have no work orders; two technicians have none.

## Key findings

- **Overhauls drive cost:** 41 overhauls (20% of jobs) cost 2.04 M of the 2.64 M total labour cost (77%).
- **SkyBridge** is the most expensive airline (843 k); Baltic Wings the cheapest (517 k).
- **ATR72 has the highest delay rate (14.3%)**, A320 the lowest (5.5%). Small samples, so treat with care (ATR72 has only 14 jobs).
- **One part dominates parts spend:** Navigation units are 130 k of 249 k (52%) although only 25 were used.
- **Spend is not flat:** May (33 jobs, 479 k) and September (22 jobs, 465 k) are the costliest months.
- Parts are only about 9% of the total cost; labour dominates.
- 4 aircraft were never serviced and 2 technicians have no jobs: worth checking in a real setting.

## The 10 questions and results

### Q1. How many work orders per status?

```sql
SELECT status, COUNT(*) AS n FROM work_orders GROUP BY status ORDER BY n DESC;
```

| status  |  n  |
|---------|-----|
| Closed  | 151 |
| Open    | 31  |
| Delayed | 18  |

### Q2. Total cost and average hours per task type

```sql
SELECT task_type, COUNT(*) AS n, SUM(cost) AS total_cost, ROUND(AVG(hours),1) AS avg_hours
FROM work_orders GROUP BY task_type ORDER BY total_cost DESC;
```

|  task_type  | n  | total_cost | avg_hours |
|-------------|----|------------|-----------|
| Overhaul    | 41 | 2039400    | 55.3      |
| Repair      | 54 | 338550     | 12.5      |
| Replacement | 51 | 180764     | 7.9       |
| Inspection  | 54 | 84960      | 5.2       |

### Q3. Which airline has the highest maintenance cost?

```sql
SELECT a.airline, COUNT(w.wo_id) AS n_orders, SUM(w.cost) AS total_cost
FROM aircraft a JOIN work_orders w ON a.aircraft_id = w.aircraft_id
GROUP BY a.airline ORDER BY total_cost DESC;
```

|   airline    | n_orders | total_cost |
|--------------|----------|------------|
| SkyBridge    | 77       | 843020     |
| Alpen Jet    | 48       | 657820     |
| Nordwind Air | 47       | 626119     |
| Baltic Wings | 28       | 516715     |

### Q4. Aircraft that were NEVER serviced

```sql
SELECT a.registration, a.model, a.airline
FROM aircraft a LEFT JOIN work_orders w ON a.aircraft_id = w.aircraft_id
WHERE w.wo_id IS NULL;
```

| registration | model |   airline    |
|--------------|-------|--------------|
| D-RWMW       | A320  | Nordwind Air |
| D-SXNX       | ATR72 | Nordwind Air |
| D-TYOY       | B737  | Alpen Jet    |
| D-UFPP       | E190  | Alpen Jet    |

### Q5. Technicians with number of orders and total hours (incl. those with none)

```sql
SELECT t.name, t.department, COUNT(w.wo_id) AS n_orders, ROUND(COALESCE(SUM(w.hours),0),1) AS total_hours
FROM technicians t LEFT JOIN work_orders w ON t.tech_id = w.tech_id
GROUP BY t.name, t.department ORDER BY total_hours DESC;
```

| name  | department | n_orders | total_hours |
|-------|------------|----------|-------------|
| Mia   | Avionics   | 33       | 803.8       |
| Nina  | Cabin      | 21       | 539.0       |
| Elif  | Avionics   | 21       | 417.6       |
| Lukas | Structures | 17       | 373.8       |
| Paul  | Structures | 24       | 369.0       |
| Karim | Engines    | 21       | 342.5       |
| Omid  | Engines    | 19       | 252.7       |
| Jonas | Engines    | 14       | 199.0       |
| Sara  | Cabin      | 15       | 192.8       |
| Lea   | Avionics   | 15       | 137.8       |
| Tom   | Structures | 0        | 0.0         |
| Yara  | Cabin      | 0        | 0.0         |

### Q6. Delay rate (%) per aircraft model

```sql
SELECT a.model, COUNT(*) AS n,
       SUM(CASE WHEN w.status = 'Delayed' THEN 1 ELSE 0 END) AS n_delayed,
       ROUND(100.0 * SUM(CASE WHEN w.status = 'Delayed' THEN 1 ELSE 0 END) / COUNT(*), 1) AS delay_pct
FROM work_orders w JOIN aircraft a ON w.aircraft_id = a.aircraft_id
GROUP BY a.model ORDER BY delay_pct DESC;
```

| model | n  | n_delayed | delay_pct |
|-------|----|-----------|-----------|
| ATR72 | 14 | 2         | 14.3      |
| B737  | 29 | 4         | 13.8      |
| A321  | 55 | 6         | 10.9      |
| E190  | 47 | 3         | 6.4       |
| A320  | 55 | 3         | 5.5       |

### Q7. Top 5 most expensive parts spend (qty * unit_price)

```sql
SELECT part_name, SUM(qty) AS total_qty, SUM(qty * unit_price) AS spend
FROM parts_used GROUP BY part_name ORDER BY spend DESC LIMIT 5;
```

|    part_name    | total_qty | spend  |
|-----------------|-----------|--------|
| Navigation unit | 25        | 130000 |
| Hydraulic pump  | 18        | 43200  |
| Tyre            | 63        | 40950  |
| Sensor          | 104       | 21840  |
| Brake pad       | 54        | 6480   |

### Q8. Orders per month (2026) with cost

```sql
SELECT SUBSTR(opened_date,1,7) AS month, COUNT(*) AS n, SUM(cost) AS total_cost
FROM work_orders GROUP BY month ORDER BY month;
```

|  month  | n  | total_cost |
|---------|----|------------|
| 2026-01 | 25 | 255095     |
| 2026-02 | 17 | 240435     |
| 2026-03 | 19 | 204750     |
| 2026-04 | 16 | 179665     |
| 2026-05 | 33 | 478840     |
| 2026-06 | 26 | 365865     |
| 2026-07 | 21 | 268354     |
| 2026-08 | 21 | 186090     |
| 2026-09 | 22 | 464580     |

### Q9. Departments whose average hours per order exceeds 18 (HAVING, 2 joins)

```sql
SELECT t.department, COUNT(*) AS n, ROUND(AVG(w.hours),1) AS avg_hours
FROM work_orders w JOIN technicians t ON w.tech_id = t.tech_id
GROUP BY t.department HAVING AVG(w.hours) > 18;
```

| department | n  | avg_hours |
|------------|----|-----------|
| Avionics   | 69 | 19.7      |
| Cabin      | 36 | 20.3      |
| Structures | 41 | 18.1      |

### Q10. Total cost of work orders INCLUDING parts, top 5 orders (3 tables)

```sql
SELECT w.wo_id, a.registration, w.cost AS labour_cost,
       COALESCE(SUM(p.qty*p.unit_price),0) AS parts_cost,
       w.cost + COALESCE(SUM(p.qty*p.unit_price),0) AS total
FROM work_orders w
JOIN aircraft a ON w.aircraft_id = a.aircraft_id
LEFT JOIN parts_used p ON w.wo_id = p.wo_id
GROUP BY w.wo_id, a.registration, w.cost
ORDER BY total DESC LIMIT 5;
```

| wo_id | registration | labour_cost | parts_cost | total |
|-------|--------------|-------------|------------|-------|
| 66    | D-PUKU       | 69300       | 1300       | 70600 |
| 100   | D-QVLV       | 68850       | 1660       | 70510 |
| 34    | D-JOTY       | 68490       | 1300       | 69790 |
| 147   | D-LQVQ       | 67320       | 1720       | 69040 |
| 39    | D-EJOT       | 68310       | 0          | 68310 |

## SQL concepts used

`SELECT` · `WHERE` · `GROUP BY` · `HAVING` · `ORDER BY` · `LIMIT` · `INNER JOIN` · `LEFT JOIN` + `IS NULL` · `CASE WHEN` · `COALESCE` · `ROUND` · `SUBSTR` · aggregates (`COUNT`, `SUM`, `AVG`)

## Pitfalls worth knowing

- **Join fan-out:** summing `work_orders.cost` after a `LEFT JOIN parts_used` counts each job once per part row (3,591,709 instead of 2,643,674). Q10 avoids this by grouping per work order.
- **Integer division:** use `100.0 * x / y` for percentages (Q6), otherwise SQLite truncates.
- **`COUNT(*)` vs `COUNT(col)`** after a `LEFT JOIN`: use the right-hand column to get 0 for rows with no match (Q5).

## Reuse

Swap in your own data with the same four tables and the queries work unchanged. MIT licensed, see `LICENSE`.
