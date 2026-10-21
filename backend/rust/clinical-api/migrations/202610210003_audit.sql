-- Development-only append-only audit foundation. Not HIPAA compliance evidence.
CREATE TABLE audit_events (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 tenant_id uuid NOT NULL REFERENCES tenants(id),
 entity_type text NOT NULL,
 entity_id uuid NOT NULL,
 action text NOT NULL,
 actor_label text NOT NULL DEFAULT 'development-shared-token',
 recorded_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX idx_audit_tenant_time ON audit_events(tenant_id,recorded_at DESC);

CREATE FUNCTION record_sandbox_audit() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE kind text;
BEGIN
 kind := TG_TABLE_NAME;
 INSERT INTO audit_events(tenant_id,entity_type,entity_id,action)
 VALUES (NEW.tenant_id,kind,NEW.id,
    CASE WHEN TG_OP='INSERT' THEN 'created'
         WHEN TG_OP='UPDATE' THEN 'updated'
         ELSE 'unknown' END);
 RETURN NEW;
END $$;
CREATE TRIGGER audit_patient_insert AFTER INSERT ON patients
FOR EACH ROW EXECUTE FUNCTION record_sandbox_audit();
CREATE TRIGGER audit_encounter_mutation AFTER INSERT OR UPDATE ON encounters
FOR EACH ROW EXECUTE FUNCTION record_sandbox_audit();
CREATE TRIGGER audit_note_insert AFTER INSERT ON clinical_notes
FOR EACH ROW EXECUTE FUNCTION record_sandbox_audit();

CREATE FUNCTION reject_audit_mutation() RETURNS trigger
LANGUAGE plpgsql SET search_path=public,pg_temp AS $$
BEGIN
 RAISE EXCEPTION 'audit events cannot be updated or deleted';
END $$;
CREATE TRIGGER audit_append_only BEFORE UPDATE OR DELETE ON audit_events
FOR EACH ROW EXECUTE FUNCTION reject_audit_mutation();

-- Fix demo tenant identity; NEVER accept arbitrary tenant ids from clients.
INSERT INTO tenants(id,name) VALUES
 ('00000000-0000-4000-8000-000000000001','Synthetic Test Organization')
ON CONFLICT (id) DO NOTHING;
