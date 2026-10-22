-- Synthetic patient contact details. Not a verified identity or emergency response system.
CREATE TABLE IF NOT EXISTS patient_contacts (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 tenant_id uuid NOT NULL,
 patient_id uuid NOT NULL,
 contact_name text NOT NULL CHECK(length(trim(contact_name)) BETWEEN 2 AND 150),
 relationship text NOT NULL CHECK(length(trim(relationship)) BETWEEN 2 AND 100),
 phone text NOT NULL CHECK(length(trim(phone)) BETWEEN 3 AND 50),
 created_at timestamptz NOT NULL DEFAULT now(),
 FOREIGN KEY(tenant_id,patient_id) REFERENCES patients(tenant_id,id)
);
CREATE INDEX IF NOT EXISTS idx_patient_contacts_patient ON patient_contacts(tenant_id,patient_id,created_at DESC);
CREATE TRIGGER audit_patient_contacts AFTER INSERT ON patient_contacts FOR EACH ROW EXECUTE FUNCTION record_sandbox_audit();
