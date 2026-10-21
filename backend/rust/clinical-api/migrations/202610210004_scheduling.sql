-- Synthetic-data scheduling domain foundation only; not yet a complete scheduling service.
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE TABLE practitioners (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  display_name text NOT NULL CHECK(length(trim(display_name)) BETWEEN 1 AND 160),
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(tenant_id,id)
);
CREATE TABLE care_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  display_name text NOT NULL CHECK(length(trim(display_name)) BETWEEN 1 AND 160),
  active boolean NOT NULL DEFAULT true,
  UNIQUE(tenant_id,id)
);
CREATE TABLE appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  patient_id uuid NOT NULL,
  practitioner_id uuid NOT NULL,
  location_id uuid NOT NULL,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  status text NOT NULL DEFAULT 'booked' CHECK(status IN ('booked','arrived','completed','cancelled','no-show')),
  reason text NOT NULL CHECK(length(trim(reason)) BETWEEN 1 AND 500),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK(ends_at > starts_at),
  FOREIGN KEY(tenant_id,patient_id) REFERENCES patients(tenant_id,id),
  FOREIGN KEY(tenant_id,practitioner_id) REFERENCES practitioners(tenant_id,id),
  FOREIGN KEY(tenant_id,location_id) REFERENCES care_locations(tenant_id,id)
);
-- Overlapping active appointments are rejected per practitioner and location.
ALTER TABLE appointments ADD CONSTRAINT no_practitioner_overlap EXCLUDE USING gist
(tenant_id WITH =, practitioner_id WITH =, tstzrange(starts_at,ends_at,'[)') WITH &&)
WHERE(status IN ('booked','arrived'));
ALTER TABLE appointments ADD CONSTRAINT no_location_overlap EXCLUDE USING gist
(tenant_id WITH =, location_id WITH =, tstzrange(starts_at,ends_at,'[)') WITH &&)
WHERE(status IN ('booked','arrived'));
CREATE INDEX idx_appointments_patient_time ON appointments(tenant_id,patient_id,starts_at DESC);
CREATE INDEX idx_appointments_schedule ON appointments(tenant_id,starts_at,status);
CREATE TRIGGER audit_appointment_mutation AFTER INSERT OR UPDATE ON appointments
FOR EACH ROW EXECUTE FUNCTION record_sandbox_audit();
