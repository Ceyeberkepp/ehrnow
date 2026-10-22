-- Development-only organizational directory, not authorization boundaries.
CREATE TABLE organization_departments (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 tenant_id uuid NOT NULL REFERENCES tenants(id),
 name text NOT NULL CHECK(length(trim(name)) BETWEEN 2 AND 120),
 description text NOT NULL DEFAULT '',
 active boolean NOT NULL DEFAULT true,
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(tenant_id,name)
);
CREATE INDEX idx_org_dept_tenant ON organization_departments(tenant_id,active,name);
CREATE TRIGGER audit_org_departments AFTER INSERT OR UPDATE ON organization_departments FOR EACH ROW EXECUTE FUNCTION record_sandbox_audit();
