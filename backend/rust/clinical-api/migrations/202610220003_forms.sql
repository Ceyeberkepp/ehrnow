-- Development-only versioned form studio. No unrestricted DDL or executable code generated.
CREATE TABLE form_templates (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 tenant_id uuid NOT NULL REFERENCES tenants(id),
 name text NOT NULL CHECK(length(trim(name)) BETWEEN 2 AND 160),
 version integer NOT NULL DEFAULT 1 CHECK(version>0),
 status text NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','archived')),
 source_form_id uuid,
 fields jsonb NOT NULL CHECK(jsonb_typeof(fields)='array'),
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(tenant_id,id),
 FOREIGN KEY(tenant_id,source_form_id) REFERENCES form_templates(tenant_id,id)
);
CREATE INDEX idx_forms_tenant ON form_templates(tenant_id,created_at DESC);
CREATE TABLE form_entries (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 tenant_id uuid NOT NULL REFERENCES tenants(id),
 form_id uuid NOT NULL,
 form_version integer NOT NULL,
 patient_id uuid,
 answers jsonb NOT NULL CHECK(jsonb_typeof(answers)='object'),
 created_at timestamptz NOT NULL DEFAULT now(),
 FOREIGN KEY(tenant_id,form_id) REFERENCES form_templates(tenant_id,id),
 FOREIGN KEY(tenant_id,patient_id) REFERENCES patients(tenant_id,id)
);
-- Auto-mapping uses stable field IDs to JSON keys: form_entries.answers.
-- Typed fields must be checked at API validation, no dynamic SQL table creation.
