# ACME Employee Salary Manager

Web-based employee salary management for ACME org's 10,000 employees across multiple countries. Built with **Ruby on Rails 7.2** (API backend + SQLite) and a **React 18** single-page UI.

## Problem

ACME's HR team manages salary data for 10,000 employees across multiple countries using Excel spreadsheets — tedious, error-prone, and hard to query. This app replaces that workflow so the HR Manager can manage salaries in a browser and answer questions about how the org pays people.

## Features

- **Dashboard** — salary analytics: headcount, mean/median/min/max monthly salary (USD), monthly & annual payroll, with breakdowns by department, country, job title, and gender (pay-equity view)
- **Employees** — searchable, filterable (department / country / status), paginated roster of all 10,000 employees
- **Employee detail** — profile, current salary (local + USD), full effective-date salary history
- **Salary adjustments** — apply a new salary with effective date and reason; previous salary is closed the day before (gapless temporal history)
- **Add employee** — create employees with an initial salary
- **Multi-currency** — salaries stored in local currency, USD equivalent computed via per-country exchange rate
- **CSV export** — one-click download of the full roster with current salary data
- **Seed data** — 10,000 employees, ~16.7k salary records generated with realistic Faker data

## Tech Stack

| Layer     | Choice                                                    |
|-----------|-----------------------------------------------------------|
| Backend   | Ruby 3.3, Rails 7.2 (API-only)                            |
| Database  | SQLite (via `sqlite3` gem)                                |
| Frontend  | React 18 (UMD, vendored locally) + Babel Standalone in-browser |
| Testing   | Minitest (models, services, controllers, integration)     |

### Why React without a Node toolchain?

This environment has no `npm`/modern Node.js. React 18's UMD builds and Babel Standalone are **vendored into `public/vendor/`**, so the SPA runs entirely in the browser with no build step and no external runtime dependencies. Everything is served from the same Rails origin (no CORS issues in normal use).

## Quick Start

Requirements: Ruby 3.2+ with Bundler. On Windows, use the matching Ruby the bundle was created with.

```bash
# 1. Install dependencies
bundle install

# 2. Create + migrate + seed the database (10,000 employees)
rails db:create db:migrate
rails db:seed          # optional — a seeded DB is NOT committed

# 3. Run the tests
rails test

# 4. Start the server
rails server
# open http://localhost:3000
```

## API Overview

| Method | Endpoint                          | Description                             |
|--------|-----------------------------------|------------------------------------------|
| GET    | `/api/v1/employees`               | Paginated, filterable employee list     |
| POST   | `/api/v1/employees`               | Create employee (+ initial salary)      |
| GET    | `/api/v1/employees/:id`           | Employee detail with current salary     |
| PATCH  | `/api/v1/employees/:id`           | Update employee attributes               |
| DELETE | `/api/v1/employees/:id`           | Delete (only if no salary history)      |
| GET    | `/api/v1/employees/:id/salaries`  | Salary history                          |
| POST   | `/api/v1/employees/:id/salaries`  | Apply a salary adjustment               |
| GET    | `/api/v1/analytics`               | Dashboard aggregates                    |
| GET    | `/api/v1/meta`                    | Lookup data (countries, departments)    |
| GET    | `/api/v1/exports/employees`       | CSV export of roster + current salaries |

Example — apply a salary adjustment:

```
POST /api/v1/employees/1/salaries
{ "amount": 15000, "effective_from": "2026-09-11", "reason": "Promotion" }
```

## Project Structure

```
app/
  controllers/api/v1/    # JSON API controllers
  models/                # Country, Department, Employee, Salary
  serializers/           # JSON serialization
  services/              # SalaryService, AnalyticsService
db/
  migrate/               # Schema (countries, departments, employees, salaries)
  seeds.rb               # 10,000-employee seed
public/
  index.html             # SPA shell
  app.js                 # React application (JSX, transpiled in-browser)
  vendor/                # Vendored React 18 + Babel Standalone
test/
  models/                # Model unit tests
  services/              # Service tests
  controllers/api/v1/    # Controller tests
  integration/           # End-to-end workflow tests
docs/
  requirements.md        # One-page requirements
  architecture.md        # Design decisions & trade-offs
  ai-prompts.md          # AI-augmented development log
```

## Key Design Decisions

- **Temporal salary model** — salaries carry `effective_from`/`effective_to` (NULL = current). Adjustments close the open record and open a new one inside a transaction (`SalaryService`).
- **All salary changes flow through `SalaryService`** so the "one current salary, no gaps, no overlaps" invariant lives in one place; `Salary` also validates against overlap.
- **USD normalization** — `amount_usd` is stored alongside local currency so analytics stay fast and cheap (no per-query conversion).
- **Service layer for analytics** — `AnalyticsService` centralizes SQL aggregations and median computation.
- **Incremental git history** — see `git log` for how the solution evolved.

## Testing

59 tests across models, services, controllers, and an end-to-end integration test. Fast and deterministic:

```bash
rails test
```

## Docs

- `docs/requirements.md` — one-page requirements (goal, scope, deliberate exclusions)
- `docs/architecture.md` — architecture + trade-offs
- `docs/ai-prompts.md` — the AI-assisted development process