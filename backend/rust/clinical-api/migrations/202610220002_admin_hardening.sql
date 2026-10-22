-- Harden administrative configuration accountability in sandbox. Not clinical authorization.
CREATE TABLE config_change_log (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 tenant_id uuid NOT NULL REFERENCES tenants(id),
 entity_type text NOT NULL,
 entity_id text NOT NULL,
 operation text NOT NULL CHECK(operation IN ('INSERT','UPDATE','DELETE')),
 previous_value jsonb,
 current_value jsonb,
 actor_source text NOT NULL DEFAULT 'development-shared-token',
 changed_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX config_change_log_tenant_idx ON config_change_log(tenant_id,changed_at DESC);
CREATE FUNCTION audit_config_change() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE old_value jsonb; new_value jsonb; scope_tenant uuid; identifier text;
BEGIN
 old_value := CASE WHEN TG_OP='INSERT' THEN NULL ELSE to_jsonb(OLD) END;
 new_value := CASE WHEN TG_OP='DELETE' THEN NULL ELSE to_jsonb(NEW) END;
 scope_tenant := CASE
   WHEN TG_TABLE_NAME='app_modules' THEN '00000000-0000-4000-8000-000000000001'::uuid
   WHEN TG_OP='DELETE' THEN OLD.tenant_id ELSE NEW.tenant_id END;
 identifier := CASE
   WHEN TG_TABLE_NAME='app_modules' THEN CASE WHEN TG_OP='DELETE' THEN OLD.key ELSE NEW.key END
   WHEN TG_TABLE_NAME='app_roles' THEN CASE WHEN TG_OP='DELETE' THEN OLD.id::text ELSE NEW.id::text END
   ELSE CASE WHEN TG_OP='DELETE' THEN OLD.role_id::text||':'||OLD.permission_key ELSE NEW.role_id::text||':'||NEW.permission_key END END;
 INSERT INTO config_change_log(tenant_id,entity_type,entity_id,operation,previous_value,current_value)
 VALUES(scope_tenant,TG_TABLE_NAME,identifier,TG_OP,old_value,new_value);
 RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
END $$;
CREATE TRIGGER audit_role_mutation AFTER INSERT OR UPDATE OR DELETE ON app_roles
FOR EACH ROW EXECUTE FUNCTION audit_config_change();
CREATE TRIGGER audit_role_permission_mutation AFTER INSERT OR UPDATE OR DELETE ON app_role_permissions
FOR EACH ROW EXECUTE FUNCTION audit_config_change();
CREATE TRIGGER audit_module_mutation AFTER INSERT OR UPDATE OR DELETE ON app_modules
FOR EACH ROW EXECUTE FUNCTION audit_config_change();
CREATE TRIGGER config_log_append_only BEFORE UPDATE OR DELETE ON config_change_log
FOR EACH ROW EXECUTE FUNCTION reject_audit_mutation();

-- New modules registered as disabled scaffolds. UI must not claim implemented workflows.
INSERT INTO app_modules(key,label,enabled,sort_order) VALUES
 ('medications','Medications & Reconciliation',false,110),
 ('lab','Laboratory & Results',false,120),
 ('imaging','Radiology & Imaging',false,130),
 ('nursing','Nursing & eMAR',false,140),
 ('pharmacy','Pharmacy',false,150),
 ('emergency','Emergency Department',false,160),
 ('inpatient','Inpatient & ADT',false,170),
 ('surgery','Surgery & Anesthesia',false,180),
 ('revenue','Billing & Revenue Cycle',false,190),
 ('portal','Patient Portal',false,200),
 ('population','Population Health',false,210),
 ('interoperability','Interoperability',false,220),
 ('analytics','Analytics & Quality',false,230),
 ('forms','Form & Template Builder',false,240),
 ('workflows','Workflow Builder',false,250),
 ('audit','Audit Viewer',false,260),
 ('integrations','Integration Manager',false,270);
INSERT INTO app_permissions(key,module_key,label)
SELECT key||'.view',key,'View '||label FROM app_modules
WHERE key IN ('medications','lab','imaging','nursing','pharmacy','emergency',
'inpatient','surgery','revenue','portal','population','interoperability',
'analytics','forms','workflows','audit','integrations');
