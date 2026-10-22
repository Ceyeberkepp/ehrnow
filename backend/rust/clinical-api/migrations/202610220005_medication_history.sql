-- Synthetic-only historical medication statements; NO prescribing or clinical validation.
CREATE TABLE patient_medication_history (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 tenant_id uuid NOT NULL REFERENCES tenants(id),
 patient_id uuid NOT NULL,
 medication_name text NOT NULL CHECK(length(trim(medication_name)) BETWEEN 1 AND 250),
 dose_text text NOT NULL CHECK(length(trim(dose_text)) BETWEEN 1 AND 250),
 status text NOT NULL DEFAULT 'reported' CHECK(status IN ('reported','stopped')),
 noted_at timestamptz NOT NULL DEFAULT now(),
 stopped_at timestamptz,
 FOREIGN KEY(tenant_id,patient_id) REFERENCES patients(tenant_id,id)
);
CREATE INDEX idx_med_history_patient ON patient_medication_history(tenant_id,patient_id,noted_at DESC);
CREATE TRIGGER audit_patient_med_history AFTER INSERT OR UPDATE ON patient_medication_history FOR EACH ROW EXECUTE FUNCTION record_sandbox_audit();
