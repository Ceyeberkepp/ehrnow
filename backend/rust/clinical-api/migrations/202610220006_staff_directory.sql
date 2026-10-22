-- Synthetic development staff directory; not an authentication or authorization store.
CREATE TABLE IF NOT EXISTS staff_directory (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 tenant_id uuid NOT NULL REFERENCES tenants(id),
 display_name text NOT NULL CHECK (length(trim(display_name)) BETWEEN 2 AND 150),
 email text NOT NULL CHECK (length(trim(email)) BETWEEN 3 AND 250),
 department text NOT NULL DEFAULT '',
 title text NOT NULL DEFAULT '',
 is_active boolean NOT NULL DEFAULT true,
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE (tenant_id,email)
);
CREATE INDEX IF NOT EXISTS idx_staff_directory_tenant ON staff_directory(tenant_id,is_active,display_name);
CREATE TRIGGER audit_staff_directory AFTER INSERT OR UPDATE ON staff_directory FOR EACH ROW EXECUTE FUNCTION record_sandbox_audit();
