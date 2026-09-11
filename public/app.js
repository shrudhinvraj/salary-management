const { useState, useEffect, useCallback, useRef } = React;

// ── API Helpers ──────────────────────────────────────────────────────
const api = {
  async get(url) {
    const res = await fetch(url);
    if (!res.ok) throw new Error((await res.json()).errors?.join(", ") || res.statusText);
    return res.json();
  },
  async post(url, body) {
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    const json = await res.json();
    if (!res.ok) throw new Error(json.errors?.join(", ") || res.statusText);
    return json;
  },
  async patch(url, body) {
    const res = await fetch(url, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    const json = await res.json();
    if (!res.ok) throw new Error(json.errors?.join(", ") || res.statusText);
    return json;
  },
};

const fmt = (n) =>
  new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", minimumFractionDigits: 0 }).format(n);

// ── Navigation ───────────────────────────────────────────────────────
function Nav({ page, onNavigate }) {
  const tabs = [
    { id: "dashboard", label: "Dashboard" },
    { id: "employees", label: "Employees" },
  ];
  return (
    <nav>
      <span style={{ fontWeight: 700, fontSize: 14, marginRight: 8 }}>ACME Salary Manager</span>
      {tabs.map((t) => (
        <a key={t.id} className={page === t.id ? "active" : ""} onClick={() => onNavigate(t.id)}>
          {t.label}
        </a>
      ))}
    </nav>
  );
}

// ── Dashboard ────────────────────────────────────────────────────────
function Dashboard({ onNavigate }) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get("/api/v1/analytics").then((r) => { setData(r.data); setLoading(false); });
  }, []);

  if (loading) return <div className="container"><p>Loading…</p></div>;
  if (!data) return <div className="container"><p>Failed to load analytics.</p></div>;
  const s = data.summary;

  return (
    <div className="container">
      <div className="page-header"><h1>Dashboard</h1></div>
      <div className="cards">
        <Card label="Total Employees" value={s.total_employees.toLocaleString()} sub={`${s.employees_paid} paid`} />
        <Card label="Avg Monthly (USD)" value={fmt(s.average_monthly_salary_usd)} />
        <Card label="Median Monthly (USD)" value={fmt(s.median_monthly_salary_usd)} />
        <Card label="Monthly Payroll (USD)" value={fmt(s.monthly_payroll_usd)} />
        <Card label="Annual Payroll (USD)" value={fmt(s.annual_payroll_usd)} />
        <Card label="Countries / Departments" value={`${s.countries_count} / ${s.departments_count}`} />
      </div>

      <h3 style={{ fontSize: 16, fontWeight: 600, marginBottom: 8 }}>By Department</h3>
      <BreakdownTable rows={data.by_department} />

      <h3 style={{ fontSize: 16, fontWeight: 600, marginTop: 24, marginBottom: 8 }}>By Country</h3>
      <BreakdownTable rows={data.by_country} />

      <h3 style={{ fontSize: 16, fontWeight: 600, marginTop: 24, marginBottom: 8 }}>By Gender</h3>
      <BreakdownTable rows={data.by_gender} />
    </div>
  );
}

function Card({ label, value, sub }) {
  return (
    <div className="card">
      <div className="card-label">{label}</div>
      <div className="card-value">{value}</div>
      {sub && <div className="card-sub">{sub}</div>}
    </div>
  );
}

function BreakdownTable({ rows }) {
  if (!rows || rows.length === 0) return <div className="empty">No data available</div>;
  return (
    <table>
      <thead><tr><th>Name</th><th style={{ textAlign: "right" }}>Headcount</th><th style={{ textAlign: "right" }}>Avg Monthly</th><th style={{ textAlign: "right" }}>Monthly Payroll</th></tr></thead>
      <tbody>
        {rows.map((r, i) => (
          <tr key={i}>
            <td>{r.key}</td>
            <td style={{ textAlign: "right" }}>{r.headcount}</td>
            <td style={{ textAlign: "right" }}>{fmt(r.average_monthly_salary_usd)}</td>
            <td style={{ textAlign: "right" }}>{fmt(r.monthly_payroll_usd)}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

// ── Employee List ────────────────────────────────────────────────────
function EmployeeList({ onNavigate }) {
  const [employees, setEmployees] = useState([]);
  const [meta, setMeta] = useState({ total: 0, page: 1, per_page: 20, total_pages: 0 });
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({ q: "", department_id: "", country_id: "", status: "" });
  const [metaData, setMetaData] = useState({ countries: [], departments: [] });
  const [showAdd, setShowAdd] = useState(false);
  const [toast, setToast] = useState(null);

  const load = useCallback((page = 1) => {
    setLoading(true);
    const params = new URLSearchParams({ page, per_page: 20 });
    Object.entries(filters).forEach(([k, v]) => { if (v) params.set(k, v); });
    api.get(`/api/v1/employees?${params}`).then((r) => {
      setEmployees(r.data);
      setMeta(r.meta);
      setLoading(false);
    });
  }, [filters]);

  useEffect(() => { api.get("/api/v1/meta").then((r) => setMetaData(r.data)); }, []);
  useEffect(() => { load(1); }, [load]);

  return (
    <div className="container">
      <div className="page-header">
        <h1>Employees ({meta.total.toLocaleString()})</h1>
        <div style={{ display: "flex", gap: 8 }}>
          <a className="btn btn-secondary" href="/api/v1/exports/employees" target="_blank">Export CSV</a>
          <button className="btn btn-primary" onClick={() => setShowAdd(true)}>Add Employee</button>
        </div>
      </div>
      {toast && <div className="alert alert-success">{toast}</div>}
      <div className="filter-bar">
        <input placeholder="Search name, email, code…" style={{ flex: "1 1 250px" }} value={filters.q} onChange={(e) => setFilters({ ...filters, q: e.target.value })} onKeyDown={(e) => e.key === "Enter" && load(1)} />
        <select value={filters.department_id} onChange={(e) => setFilters({ ...filters, department_id: e.target.value })}>
          <option value="">All Departments</option>
          {metaData.departments.map((d) => <option key={d.id} value={d.id}>{d.name}</option>)}
        </select>
        <select value={filters.country_id} onChange={(e) => setFilters({ ...filters, country_id: e.target.value })}>
          <option value="">All Countries</option>
          {metaData.countries.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
        </select>
        <select value={filters.status} onChange={(e) => setFilters({ ...filters, status: e.target.value })}>
          <option value="">All Statuses</option>
          <option value="active">Active</option>
          <option value="on_leave">On Leave</option>
          <option value="terminated">Terminated</option>
        </select>
      </div>
      {loading ? <p>Loading…</p> : (
        <>
          <table>
            <thead><tr>
              <th>Code</th><th>Name</th><th>Email</th><th>Department</th><th>Country</th><th style={{ textAlign: "right" }}>Monthly (USD)</th><th>Status</th><th></th>
            </tr></thead>
            <tbody>
              {employees.map((e) => (
                <tr key={e.id}>
                  <td>{e.employee_code}</td>
                  <td>{e.full_name}</td>
                  <td>{e.email}</td>
                  <td>{e.department}</td>
                  <td>{e.country}</td>
                  <td style={{ textAlign: "right" }}>{e.current_salary ? fmt(e.current_salary.amount_usd) : "—"}</td>
                  <td><span className={`badge badge-${e.status === "active" ? "active" : e.status === "terminated" ? "inactive" : "leave"}`}>{e.status}</span></td>
                  <td><button className="btn btn-sm btn-secondary" onClick={() => onNavigate("employee", e.id)}>View</button></td>
                </tr>
              ))}
              {employees.length === 0 && <tr><td colSpan="8" className="empty">No employees found</td></tr>}
            </tbody>
          </table>
          {meta.total_pages > 1 && (
            <div className="pagination">
              <button disabled={meta.page <= 1} onClick={() => load(meta.page - 1)}>← Prev</button>
              <span>Page {meta.page} of {meta.total_pages}</span>
              <button disabled={meta.page >= meta.total_pages} onClick={() => load(meta.page + 1)}>Next →</button>
            </div>
          )}
        </>
      )}
      {showAdd && <AddEmployeeModal meta={metaData} onClose={() => { setShowAdd(false); load(meta.page); }} onToast={(msg) => { setToast(msg); setTimeout(() => setToast(null), 3000); }} />}
    </div>
  );
}

// ── Add Employee Modal ───────────────────────────────────────────────
function AddEmployeeModal({ meta, onClose, onToast }) {
  const [form, setForm] = useState({ first_name: "", last_name: "", email: "", gender: "male", job_title: "", hire_date: "", department_id: "", country_id: "" });
  const [salary, setSalary] = useState({ amount: "" });
  const [error, setError] = useState(null);

  const submit = async () => {
    try {
      await api.post("/api/v1/employees", { employee: { ...form, department_id: +form.department_id, country_id: +form.country_id }, salary: { amount: +salary.amount } });
      onToast("Employee created successfully");
      onClose();
    } catch (e) {
      setError(e.message);
    }
  };

  return (
    <div className="overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h2>Add Employee</h2>
        {error && <div className="alert alert-error">{error}</div>}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
          <FormGroup label="First Name" value={form.first_name} onChange={(v) => setForm({ ...form, first_name: v })} />
          <FormGroup label="Last Name" value={form.last_name} onChange={(v) => setForm({ ...form, last_name: v })} />
        </div>
        <FormGroup label="Email" value={form.email} onChange={(v) => setForm({ ...form, email: v })} />
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
          <FormSelect label="Gender" value={form.gender} options={[["male","Male"],["female","Female"],["non_binary","Non-binary"]]} onChange={(v) => setForm({ ...form, gender: v })} />
          <FormGroup label="Job Title" value={form.job_title} onChange={(v) => setForm({ ...form, job_title: v })} />
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
          <FormGroup label="Hire Date" type="date" value={form.hire_date} onChange={(v) => setForm({ ...form, hire_date: v })} />
          <FormSelect label="Department" value={form.department_id} options={meta.departments.map((d) => [d.id, d.name])} onChange={(v) => setForm({ ...form, department_id: v })} />
        </div>
        <FormSelect label="Country" value={form.country_id} options={meta.countries.map((c) => [c.id, c.name])} onChange={(v) => setForm({ ...form, country_id: v })} />
        <FormGroup label="Initial Monthly Salary" type="number" value={salary.amount} onChange={(v) => setSalary({ amount: v })} />
        <div className="form-actions">
          <button className="btn btn-secondary" onClick={onClose}>Cancel</button>
          <button className="btn btn-primary" onClick={submit}>Create Employee</button>
        </div>
      </div>
    </div>
  );
}

// ── Employee Detail ──────────────────────────────────────────────────
function EmployeeDetail({ id, onBack }) {
  const [employee, setEmployee] = useState(null);
  const [salaries, setSalaries] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAdjust, setShowAdjust] = useState(false);
  const [toast, setToast] = useState(null);
  const [meta, setMetaData] = useState(null);

  const load = () => {
    setLoading(true);
    Promise.all([
      api.get(`/api/v1/employees/${id}`),
      api.get(`/api/v1/employees/${id}/salaries`),
    ]).then(([empRes, salRes]) => {
      setEmployee(empRes.data);
      setSalaries(salRes.data);
      setLoading(false);
    });
  };

  useEffect(() => {
    load();
    api.get("/api/v1/meta").then((r) => setMetaData(r.data));
  }, [id]);

  if (loading) return <div className="container"><p>Loading…</p></div>;
  if (!employee) return <div className="container"><p>Employee not found.</p><button className="btn btn-secondary" onClick={onBack}>← Back</button></div>;

  return (
    <div className="container">
      <button className="btn btn-secondary" onClick={onBack} style={{ marginBottom: 16 }}>← Back to Employees</button>
      {toast && <div className="alert alert-success">{toast}</div>}
      <div className="page-header">
        <h1>{employee.full_name} <span style={{ color: "#64748b", fontSize: 14, fontWeight: 400 }}>({employee.employee_code})</span></h1>
        {employee.status === "active" && (
          <button className="btn btn-primary" onClick={() => setShowAdjust(true)}>Adjust Salary</button>
        )}
      </div>

      <div className="section">
        <h3>Profile</h3>
        <dl className="detail-grid">
          <dt>Email</dt><dd>{employee.email}</dd>
          <dt>Job Title</dt><dd>{employee.job_title}</dd>
          <dt>Department</dt><dd>{employee.department}</dd>
          <dt>Country</dt><dd>{employee.country} ({employee.currency})</dd>
          <dt>Gender</dt><dd>{employee.gender?.replace("_", " ")}</dd>
          <dt>Status</dt><dd><span className={`badge badge-${employee.status === "active" ? "active" : employee.status === "terminated" ? "inactive" : "leave"}`}>{employee.status}</span></dd>
          <dt>Hire Date</dt><dd>{employee.hire_date}</dd>
          <dt>Tenure</dt><dd>{employee.tenure_years} year(s)</dd>
        </dl>
      </div>

      <div className="section">
        <h3>Current Salary</h3>
        {employee.current_salary ? (
          <div>
            <div className="salary-highlight">{fmt(employee.current_salary.amount_usd)} <span style={{ fontSize: 16, color: "#64748b" }}>/ month (USD)</span></div>
            <div style={{ marginTop: 8, fontSize: 13, color: "#64748b" }}>
              Local: {fmt(employee.current_salary.amount)} / {employee.current_salary.currency} · Effective since {employee.current_salary.effective_from}
            </div>
          </div>
        ) : (
          <div className="empty">No active salary record</div>
        )}
      </div>

      <div className="section">
        <h3>Salary History</h3>
        {salaries.length > 0 ? (
          <table>
            <thead><tr><th>Effective From</th><th>Effective To</th><th style={{ textAlign: "right" }}>Amount (Local)</th><th style={{ textAlign: "right" }}>Amount (USD)</th><th>Status</th><th>Reason</th></tr></thead>
            <tbody>
              {salaries.map((s) => (
                <tr key={s.id}>
                  <td>{s.effective_from}</td>
                  <td>{s.effective_to || "—"}</td>
                  <td style={{ textAlign: "right" }}>{fmt(s.amount)} / {s.currency}</td>
                  <td style={{ textAlign: "right" }}>{fmt(s.amount_usd)}</td>
                  <td>{s.current ? <span className="badge badge-active">Current</span> : <span className="badge badge-inactive">Closed</span>}</td>
                  <td>{s.reason || "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <div className="empty">No salary records</div>
        )}
      </div>

      {showAdjust && (
        <SalaryAdjustmentModal
          employee={employee}
          meta={meta}
          onClose={() => setShowAdjust(false)}
          onSaved={(msg) => { setToast(msg); load(); }}
        />
      )}
    </div>
  );
}

// ── Salary Adjustment Modal ──────────────────────────────────────────
function SalaryAdjustmentModal({ employee, meta, onClose, onSaved }) {
  const [form, setForm] = useState({ amount: "", currency: employee.currency, effective_from: new Date().toISOString().slice(0, 10), reason: "" });
  const [error, setError] = useState(null);

  const submit = async () => {
    try {
      await api.post(`/api/v1/employees/${employee.id}/salaries`, {
        amount: +form.amount,
        currency: form.currency || undefined,
        effective_from: form.effective_from,
        reason: form.reason || undefined,
      });
      onSaved("Salary adjusted successfully");
      onClose();
    } catch (e) {
      setError(e.message);
    }
  };

  return (
    <div className="overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h2>Adjust Salary – {employee.full_name}</h2>
        {error && <div className="alert alert-error">{error}</div>}
        <div className="form-group">
          <label>Current Salary</label>
          <p style={{ fontSize: 14 }}>{employee.current_salary ? `${fmt(employee.current_salary.amount)} / ${employee.current_salary.currency}` : "No salary"}</p>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
          <FormGroup label="New Monthly Amount" type="number" value={form.amount} onChange={(v) => setForm({ ...form, amount: v })} />
          <FormSelect label="Currency" value={form.currency} options={(meta?.currencies || [["USD","USD"],["EUR","EUR"],["GBP","GBP"],["INR","INR"],["JPY","JPY"],["AUD","AUD"],["CAD","CAD"],["SGD","SGD"]])} onChange={(v) => setForm({ ...form, currency: v })} />
        </div>
        <FormGroup label="Effective Date" type="date" value={form.effective_from} onChange={(v) => setForm({ ...form, effective_from: v })} />
        <FormGroup label="Reason" value={form.reason} onChange={(v) => setForm({ ...form, reason: v })} />
        <div className="form-actions">
          <button className="btn btn-secondary" onClick={onClose}>Cancel</button>
          <button className="btn btn-success" onClick={submit}>Apply Adjustment</button>
        </div>
      </div>
    </div>
  );
}

// ── Shared Form Controls ─────────────────────────────────────────────
function FormGroup({ label, value, onChange, type = "text" }) {
  return (
    <div className="form-group">
      <label>{label}</label>
      <input type={type} value={value || ""} onChange={(e) => onChange(e.target.value)} />
    </div>
  );
}

function FormSelect({ label, value, options, onChange }) {
  return (
    <div className="form-group">
      <label>{label}</label>
      <select value={value} onChange={(e) => onChange(e.target.value)}>
        <option value="">Select…</option>
        {options.map((o) => <option key={o[0]} value={o[0]}>{o[1]}</option>)}
      </select>
    </div>
  );
}

// ── App (Router) ────────────────────────────────────────────────────
function App() {
  const [page, setPage] = useState("dashboard");
  const [params, setParams] = useState({});

  const navigate = (p, id) => { setPage(p); setParams(id ? { id } : {}); };

  return (
    <>
      <Nav page={page} onNavigate={setPage} />
      {page === "dashboard" && <Dashboard onNavigate={navigate} />}
      {page === "employees" && <EmployeeList onNavigate={navigate} />}
      {page === "employee" && <EmployeeDetail id={params.id} onBack={() => navigate("employees")} />}
    </>
  );
}

// ── Mount ────────────────────────────────────────────────────────────
ReactDOM.createRoot(document.getElementById("root")).render(<App />);