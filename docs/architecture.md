# Architecture & Design Notes

## System Overview

```
Browser (React 18 SPA)
   │  fetch()  →  Rails 7.2 (API, JSON)
   ▼                │
public/app.js ──►  Api::V1::*Controllers
                     │  EmployeeSerializer / SalarySerializer
                     ▼
                  Services
                     ├── SalaryService     (adjustments, temporal integrity)
                     └── AnalyticsService  (aggregations)
                     ▼
                  ActiveRecord models
                     ├── Employee (has_many :salaries)
                     ├── Salary   (effective_from / effective_to)
                     ├── Country  (currency + exchange rate)
                     └── Department
                     ▼
                  SQLite (storage/development.sqlite3)
```

All assets (React, Babel, JSX) ship from the Rails `/public` directory, so the frontend and API share one origin; CORS is enabled anyway for flexibility.

## Data Model

### Salary timeline (the core domain)

Each employee has a chronological series of salary records:

| field            | meaning                                            |
|------------------|----------------------------------------------------|
| `effective_from` | first day the rate applies                        |
| `effective_to`   | last day the rate applies; **NULL = current**     |
| `amount`         | monthly amount in local currency                  |
| `amount_usd`     | monthly USD equivalent at the time of the record  |
| `currency`       | local currency code                                |
| `reason`         | why the change happened (promotion, review, …)    |

Invariant enforced by `SalaryService` + `Salary` validations: **exactly one current salary, no overlapping periods, no gaps** when adjusting.

**Why not a "current salary" column on employees?** History is a first-class requirement. A temporal table answers "what did this person earn in March 2024?" and powers the analytics without denormalizing state into the employee row.

**Why store `amount_usd`?** Aggregating 10,000 records across 12 currencies on every dashboard view would multiply currency conversions at query time. Storing the normalized USD value makes `SUM/AVG` trivial and cheap. Trade-off: if exchange rates move, historical records keep the rate at the time — which is desirable for a compensation audit trail.

## Backend

- **Rails 7.2 API-only.** Controllers stay thin; domain logic lives in services so it's unit-testable without HTTP.
- **`SalaryService`** owns the adjustment transaction: closes the current record (`effective_to = new_date - 1`), creates the next, and rolls back cleanly if the new record is invalid (verified by test `test_adjust_rolls_back_the_closing_when_the_new_salary_is_invalid`).
- **`AnalyticsService`** centralizes the SQL for current-salary joins and faceted group-bys (department/country/job_title/gender), plus Ruby median calculation (SQLite lacks a `median` aggregate).
- **Serializers** decouple the JSON contract from the models.

### Pagination & performance

- Hand-rolled `page`/`per_page` (capped at 100) to avoid a pagination gem dependency.
- Indexes on every filter/join column: `employees(status)`, `employees(job_title)`, `salaries(employee_id, effective_from)`, `salaries(effective_to, employee_id)`, plus unique indexes on `employee_code` and `email`.
- Seeding batches and prints progress; even a single-transaction seed of 10K records completes quickly on SQLite.

## Frontend

- **React 18** SPA. Because this environment lacks `npm`/Node.js ≥ 14, React's UMD build and Babel Standalone are **vendored under `public/vendor/`** (no build step, no CDN dependency at runtime).
- Components: `Nav`, `Dashboard`, `EmployeeList`, `EmployeeDetail`, `AddEmployeeModal`, `SalaryAdjustmentModal`, shared `FormGroup`/`FormSelect`.
- Accessible semantics: modal overlays with click-outside close, keyboard-friendly forms.

## Trade-offs (deliberate)

| Decision | Why | Consequence |
|----------|-----|-------------|
| SQLite over PostgreSQL | Zero-ops, file-based, plenty for 10K rows | Would need config change for production PG |
| Vendored UMD React | No Node toolchain available | Larger initial page HTML; JSX compiled in-browser (slightly slower first load, negligible for an internal tool) |
| Stored USD snapshot | Fast analytics | Rate changes don't retroactively re-price history |
| No auth in MVP | Assessed in requirements doc as out of scope for the persona | Not production-ready for multi-user org |
| CSV export only (no bulk import) | Export + adjustment API cover the HR workflows scored here | Bulk import is a documented v2 item |

## Scaling Notes

At 10K employees this design is comfortably single-machine. If ACME grows an order of magnitude:

1. Swap SQLite → PostgreSQL (ActiveRecord makes this a config change).
2. Move invoicing of analytics into cached summary tables or a reporting replica.
3. Add paging + `SELECT` column narrowing on the CSV export (virtual file / streaming).
4. Add an `audits` table and employee-level locking for concurrent salary edits.