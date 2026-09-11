# Requirements Document: ACME Employee Salary Management System

## Goal

Replace the current Excel-based salary management workflow at ACME with a web-based application that allows HR Managers to manage salary data for 10,000 employees across multiple countries and answer questions about organizational compensation.

## User Persona

**HR Manager** at ACME (10,000 employees, multi-country):
- Manages salary records, adjustments, and historical changes
- Needs to answer ad-hoc questions about compensation (e.g., "How does ACME pay engineers in India vs Germany?")
- Requires visibility into salary distributions and pay equity
- Works with multiple currencies and tax jurisdictions

## In Scope (MVP)

### Core Features

1. **Employee Management**
   - List, search, and filter employees by name, department, country, role
   - View individual employee profiles with salary history

2. **Salary Management**
   - View current salary for each employee (base salary, currency, pay grade)
   - Record salary adjustments with effective dates and justification
   - Maintain full salary history per employee

3. **Analytics & Reporting Dashboard**
   - Salary distribution by department, country, and role
   - Average/median/min/max salary comparisons across dimensions
   - Headcount and salary summary statistics
   - Pay equity indicators (gender pay gap approximation where data available)

4. **Bulk Operations**
   - CSV import/export for employee salary data
   - Bulk salary adjustment workflow (with approval tracking)

5. **Multi-Currency Support**
   - Employees assigned to a country with local currency
   - Display salaries in both local and USD-equivalent (stored exchange rate)

## Out of Scope (Deliberate Exclusions)

| Feature | Reason |
|---------|--------|
| Authentication/Authorization | MVP focuses on core functionality; assume single-user HR Manager context. Auth adds complexity without demonstrating core domain logic. Would add in v2. |
| Payroll processing integration | This is a salary *management* tool, not a payroll system. Keeping scope focused. |
| Employee self-service portal | Different persona (employee vs HR manager) would double UI complexity. |
| Real-time exchange rate feeds | Fixed rates seeded for simplicity; real integration would need external API keys and error handling. |
| Tax calculation | Vastly complex per-jurisdiction; out of MVP scope. |
| Document attachment (offer letters, etc.) | Would require file storage infrastructure; not core to salary management. |
| Audit trail / compliance logging | Important for production but adds significant complexity; would be v2. |

## Technical Decisions

- **Backend**: Ruby on Rails 7.2 (API + server-rendered UI)
- **Frontend**: Rails views with vanilla JavaScript for interactive components (avoiding React build complexity for an assessment)
- **Database**: SQLite (sufficient for 10K records; easily swappable to PostgreSQL for production)
- **Testing**: Minitest (Rails default) + integration tests
- **Seeding**: Faker gem for realistic fake data, 10,000 employee records

## Success Criteria

- HR Manager can browse employees with filters and sorting
- HR Manager can view/edit individual employee salary records
- HR Manager can see analytics dashboard with salary breakdowns
- HR Manager can export data to CSV
- Seed script generates 10,000 realistic employee records
- All core functionality covered by automated tests
