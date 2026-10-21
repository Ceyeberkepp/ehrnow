-- Developer-only reported allergy history. NOT validated clinical allergy checking.
CREATE TABLE reported_allergies (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 tenant_id uuid NOT NULL REFERENCES tenants(id),
 patient_id uuid NOT NULL,
 substance_label text NOT NULL CHECK(length(trim(substance_label)) BETWEEN 1 AND 250),
 reaction_label text NOT NULL CHECK(length(trim(reaction_label)) BETWEEN 1 AND 500),
 recorded_at timestamptz NOT NULL DEFAULT now(),
 FOREIGN KEY(tenant_id,patient_id) REFERENCES patients(tenant_id,id)
);
CREATE INDEX idx_allergies_patient ON reported_allergies(tenant_id,patient_id,recorded_at DESC);
CREATE TRIGGER audit_reported_allergies AFTER INSERT ON reported_allergies FOR EACH ROW EXECUTE FUNCTION record_sandbox_audit();
