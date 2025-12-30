import { useEffect, useState } from "react";

export default function SchemaForm({ schema, onSubmit, disabled }) {
  const version = schema.version || "1.0";
  const storageKey = `infraforge:inputs:${schema.id}:${version}`;

  const [values, setValues] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem(storageKey)) || {};
    } catch {
      return {};
    }
  });

  const [errors, setErrors] = useState({});
  const [showAdvanced, setShowAdvanced] = useState(false);

  /* -----------------------------
     Validation
  ------------------------------*/
  const validateField = (field, value) => {
    if (field.required && (value === undefined || value === "")) {
      return "This field is required";
    }

    if (field.type === "number" && value !== undefined && value !== "") {
      const n = Number(value);
      if (Number.isNaN(n)) return "Must be a number";
      if (field.min !== undefined && n < field.min)
        return `Minimum is ${field.min}`;
      if (field.max !== undefined && n > field.max)
        return `Maximum is ${field.max}`;
    }

    if (field.type === "select" && field.options) {
      if (value && !field.options.includes(value)) {
        return "Invalid selection";
      }
    }

    return null;
  };

  /* -----------------------------
     Update + Persist
  ------------------------------*/
  const updateValue = (field, value) => {
    const err = validateField(field, value);

    setValues((prev) => {
      const next = { ...prev, [field.key]: value };
      localStorage.setItem(storageKey, JSON.stringify(next));
      return next;
    });

    setErrors((prev) => ({ ...prev, [field.key]: err }));
  };

  /* -----------------------------
     Form Validity
  ------------------------------*/
  const isValid = () =>
    schema.fields.every((field) => {
      const val = values[field.key];
      return !validateField(field, val);
    });

  /* -----------------------------
     Grouping
  ------------------------------*/
  const basicFields = schema.fields.filter(
    (f) => !f.group || f.group === "basic"
  );

  const advancedFields = schema.fields.filter(
    (f) => f.group === "advanced"
  );

  /* -----------------------------
     Submit
  ------------------------------*/
  const submit = (e) => {
    e.preventDefault();
    if (!isValid()) return;
    onSubmit(values);
  };

  return (
    <form onSubmit={submit} style={styles.form}>
      <h2>{schema.name}</h2>
      <p style={styles.desc}>{schema.description}</p>

      {/* BASIC */}
      {basicFields.map((field) => (
        <Field
          key={field.key}
          field={field}
          value={values[field.key]}
          error={errors[field.key]}
          onChange={(v) => updateValue(field, v)}
        />
      ))}

      {/* ADVANCED */}
      {advancedFields.length > 0 && (
        <>
          <button
            type="button"
            style={styles.advancedToggle}
            onClick={() => setShowAdvanced((v) => !v)}
          >
            {showAdvanced ? "Hide Advanced" : "Show Advanced"}
          </button>

          {showAdvanced &&
            advancedFields.map((field) => (
              <Field
                key={field.key}
                field={field}
                value={values[field.key]}
                error={errors[field.key]}
                onChange={(v) => updateValue(field, v)}
              />
            ))}
        </>
      )}

      <button
        type="submit"
        disabled={disabled || !isValid()}
        style={{
          ...styles.submit,
          ...(disabled || !isValid() ? styles.submitDisabled : {}),
        }}
      >
        Generate
      </button>
    </form>
  );
}

/* ==============================
   Field Renderer
============================== */

function Field({ field, value, error, onChange }) {
  return (
    <div style={styles.field}>
      <label style={styles.label}>{field.label}</label>

      {field.type === "text" && (
        <input
          style={styles.input}
          value={value || ""}
          onChange={(e) => onChange(e.target.value)}
        />
      )}

      {field.type === "number" && (
        <input
          type="number"
          style={styles.input}
          value={value || ""}
          onChange={(e) => onChange(e.target.value)}
        />
      )}

      {field.type === "select" && (
        <select
          style={styles.input}
          value={value || ""}
          onChange={(e) => onChange(e.target.value)}
        >
          <option value="">Select</option>
          {field.options.map((o) => (
            <option key={o} value={o}>
              {o}
            </option>
          ))}
        </select>
      )}

      {field.type === "boolean" && (
        <input
          type="checkbox"
          checked={Boolean(value)}
          onChange={(e) => onChange(e.target.checked)}
        />
      )}

      {field.hint && <div style={styles.hint}>{field.hint}</div>}
      {error && <div style={styles.error}>{error}</div>}
    </div>
  );
}

/* ==============================
   Styles
============================== */

const styles = {
  form: {
    border: "1px solid var(--border)",
    borderRadius: "10px",
    padding: "16px",
    background: "#0d1117",
  },
  desc: {
    color: "var(--muted)",
    marginBottom: "12px",
  },
  field: {
    marginBottom: "14px",
  },
  label: {
    display: "block",
    marginBottom: "4px",
  },
  input: {
    width: "100%",
    padding: "8px",
    borderRadius: "6px",
    border: "1px solid var(--border)",
    background: "#161b22",
    color: "var(--fg)",
  },
  hint: {
    fontSize: "12px",
    color: "var(--muted)",
    marginTop: "4px",
  },
  error: {
    fontSize: "12px",
    color: "#f85149",
    marginTop: "4px",
  },
  advancedToggle: {
    margin: "10px 0",
    background: "transparent",
    border: "none",
    color: "var(--accent)",
    cursor: "pointer",
  },
  submit: {
    marginTop: "12px",
    padding: "10px",
    borderRadius: "8px",
    border: "1px solid var(--accent)",
    background: "transparent",
    color: "var(--accent)",
    cursor: "pointer",
  },
  submitDisabled: {
    opacity: 0.4,
    cursor: "not-allowed",
  },
};
