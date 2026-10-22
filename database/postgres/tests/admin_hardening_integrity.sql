BEGIN;
DO $$
DECLARE t uuid := '00000000-0000-4000-8000-000000000001'; r uuid; initial_count bigint; log_id bigint;
BEGIN
 SELECT count(*) INTO initial_count FROM config_change_log WHERE tenant_id=t;
 INSERT INTO app_roles(tenant_id,name,description) VALUES(t,'Synthetic Security Test','Config audit verification') RETURNING id INTO r;
 INSERT INTO app_role_permissions(tenant_id,role_id,permission_key) VALUES(t,r,'patients.view');
 DELETE FROM app_role_permissions WHERE tenant_id=t AND role_id=r AND permission_key='patients.view';
 UPDATE app_roles SET description='Updated test' WHERE id=r;
 IF (SELECT count(*) FROM config_change_log WHERE tenant_id=t) < initial_count+4 THEN
 RAISE EXCEPTION 'Missing role/config audit events';END IF;
 SELECT id INTO log_id FROM config_change_log WHERE tenant_id=t ORDER BY id DESC LIMIT 1;
 BEGIN
 DELETE FROM config_change_log WHERE id=log_id;
 RAISE EXCEPTION 'Audit delete unexpectedly allowed';
 EXCEPTION WHEN raise_exception THEN
 IF SQLERRM='Audit delete unexpectedly allowed' THEN RAISE; END IF;
 END;
 IF (SELECT count(*) FROM app_modules WHERE enabled=false AND key='medications')<>1 THEN
 RAISE EXCEPTION 'New module must start disabled';END IF;
END $$;
ROLLBACK;
