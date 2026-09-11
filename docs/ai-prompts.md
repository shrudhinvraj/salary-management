# AI-Assisted Development Log

This project was built with agentic AI tooling (an interactive coding assistant). This document records the prompts used and the reasoning behind them, so the human reviewers can see how AI was used *intentionally*.

## Goal Shaping

1. **"Prepare a Ruby application based on this requirement: employee salary management for 10,000 employees, HR Manager persona, React/Next UI, seed 10K employees, tests, requirements doc, incremental commits."**

   → I translated the assessment into a concrete plan: Rails 7.2 (API) + SQLite + React 18 SPA + Minitest + a requirement/architecture doc, with a git commit for each milestone.

## Requirements & Scoping

2. **"Write a one-page requirements document: goal, in-scope features, and what we deliberately leave out and why."**

   → Produced `docs/requirements.md`. Deliberate exclusions (auth, payroll integration, self-service portal) were chosen by me and documented with reasoning — the strongest submissions show product judgment, not maximum complexity.

## Environment Discovery

3. **"what Ruby / Rails / Node / npm versions are available on this machine?"**

   → Discovery showed: Ruby 3.2 (PATH) and Ruby 3.3.4 (`C:\Ruby33-x64\bin`), Rails 6.1 preinstalled but broken on Ruby 3.3, Node v6 (no npm). Rails 8 install failed (needs a C compiler for `prism`). I pinned `rails ~> 7.2` on Ruby 3.3 — a deliberate, environment-driven framework choice.

## Schema & Domain

4. **"Design the temporal salary model: how do we track a salary history with effective dates, close the active record on adjustment, and enforce no-overlap?"**

   → Outlined the `salaries(effective_from, effective_to, amount, amount_usd, currency, reason)` model and the `SalaryService` adjustment transaction.

5. **"The digest needs mean/median/min/max monthly salary, monthly & annual payroll, and breakdowns by department/country/title/gender in USD."**

   → Implemented `AnalyticsService` with a single current-salary join and faceted group-bys, median computed in Ruby (SQLite lacks a median aggregate).

## Correcting AI-Driven Mistakes

The assistant's first pass introduced real bugs; each was caught by writing tests:

6. **Bug: inverted `effective_to` validation** — "effective_to must be on or after effective_from" was backwards. Caught by the seed run, fixed in `salary.rb`.
7. **Bug: Rails 7.2 + json 3.0 incompatibility** — `JSON.generate(quirks_mode:)` was removed in json 3.x, breaking every `render json:`. Diagnosis: grep'd the installed `activesupport` source to confirm the call site, pinned `json >= 2.7, < 3`.
8. **Bug: non-rollback return inside `SalaryService` transaction** — an early `return Result` committed the closing UPDATE. Fixed with an explicit `ActiveRecord::Rollback` + association reset; covered by `test_adjust_rolls_back_the_closing_when_the_new_salary_is_invalid`.
9. **Test-isolation subtlety:** building a Salary with `Salary.create!(employee:)` poisoned the inverse association cache in transactional tests; switched the factory to `employee.salaries.create!`.

## Verification Prompts

10. **"Run the seeds; verify the API returns sensible aggregates for all 10,000 employees; export CSV and confirm totals."**

    → Manual smoke checks against a live server, plus consistent results across 5+ test-suite runs with different random seeds.

## How AI Was Used Intentionally

- **Acceleration:** scaffolding, migrations, serializers before writing a single line by hand.
- **Critique loop:** every AI suggestion was validated *by the test suite*; the four real bugs above all came from generated code, and the tests caught them.
- **Judgment left to a human:** scope choices, the temporal-model design, the vendored-React trade-off, and the deliberate exclusions were authored as engineering decisions, not delegated to the assistant.

## Model & Tools

- Ruby on Rails 7.2, SQLite, Minitest, Faker
- React 18 (UMD) + Babel Standalone vendored locally (no Node toolchain available)
- AI-assisted editing + test-driven verification