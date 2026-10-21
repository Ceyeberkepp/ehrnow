CREATE TABLE patient_problems (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 tenant_id uuid NOT NULL REFERENCES tenants(id),
 patient_id uuid NOT NULL,
 description text NOT NULL CHECK(length(trim(description)) BETWEEN 1 AND 500),
 clinical_status text NOT NULL DEFAULT 'active' CHECK(clinical_status IN ('active','resolved')),
 recorded_at timestamptz NOT NULL DEFAULT now(),
 resolved_at timestamptz,
 FOREIGN KEY(tenant_id,patient_id) REFERENCES patients(tenant_id,id),
 CHECK ((clinical_status='resolved') = (resolved_at IS NOT NULL))
);
CREATE INDEX idx_problems_patient ON patient_problems(tenant_id,patient_id,recorded_at DESC);
CREATE TRIGGER audit_problems AFTER INSERT OR UPDATE ON patient_problems FOR EACH ROW EXECUTE FUNCTION record_sandbox_audit();
