CREATE TABLE encounters (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 tenant_id uuid NOT NULL REFERENCES tenants(id),
 patient_id uuid NOT NULL,
 status text NOT NULL DEFAULT 'in-progress' CHECK (status IN ('in-progress','finished')),
 reason text NOT NULL CHECK (length(reason) BETWEEN 1 AND 500),
 started_at timestamptz NOT NULL DEFAULT now(),
 finished_at timestamptz,
 UNIQUE (tenant_id,id),
 FOREIGN KEY (tenant_id,patient_id) REFERENCES patients(tenant_id,id)
);
CREATE INDEX idx_encounters_patient ON encounters(tenant_id,patient_id,started_at DESC);
CREATE TABLE clinical_notes (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 tenant_id uuid NOT NULL REFERENCES tenants(id),
 encounter_id uuid NOT NULL,
 author_label text NOT NULL CHECK (length(author_label) BETWEEN 1 AND 120),
 content text NOT NULL CHECK (length(content) BETWEEN 1 AND 10000),
 created_at timestamptz NOT NULL DEFAULT now(),
 FOREIGN KEY (tenant_id,encounter_id) REFERENCES encounters(tenant_id,id)
);
CREATE INDEX idx_notes_encounter ON clinical_notes(tenant_id,encounter_id,created_at DESC);
-- Developer sandbox only. Production requires validated author identities, RLS,
-- consent, note amendments, clinical signatures and immutable audited history.
