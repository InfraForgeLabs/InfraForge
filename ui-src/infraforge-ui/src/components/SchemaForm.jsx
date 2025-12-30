import { useState } from "react";

/*
  SchemaForm expects schemas as an ARRAY.
  We now defensively normalize input to avoid runtime crashes.
*/

export default function SchemaForm({ schemas = {}, onSubmit }) {
  // Normalize object → array
  const schemaList = Array.isArray(schemas)
    ? schemas
    : Object.values(schemas);

  const [values, setValues] = useState({});

  function handleChange(id, value) {
    setValues((prev) => ({
      ...prev,
      [id]: value
    }));
  }

  function handleSubmit(e) {
    e.preventDefault();
    onSubmit(values);
  }

  if (!schemaList.length) {
    return (
      <div className="text-sm text-neutral-500">
        No schemas available
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {schemaList.map((schema) => (
        <div key={schema.id}>
          <label className="block text-sm mb-1">
            {schema.label}
          </label>

          <input
            type="text"
            className="w-full px-2 py-1 rounded bg-neutral-900 border border-neutral-800"
            value={values[schema.id] || ""}
            onChange={(e) =>
              handleChange(schema.id, e.target.value)
            }
          />
        </div>
      ))}

      <button
        type="submit"
        className="px-4 py-2 text-sm rounded
                   bg-emerald-600 hover:bg-emerald-500
                   text-black"
      >
        Generate
      </button>
    </form>
  );
}
