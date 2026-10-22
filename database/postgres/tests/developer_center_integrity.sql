BEGIN;
DO $$
DECLARE t uuid := '00000000-0000-4000-8000-000000000001';
r uuid;
BEGIN
 INSERT INTO app_roles(tenant_id,name,description) VALUES(t,'Test Role','Synthetic only') RETURNING id INTO r;
 INSERT INTO app_role_permissions(tenant_id,role_id,permission_key) VALUES(t,r,'patients.view');
 IF (SELECT count(*) FROM app_role_permissions WHERE role_id=r AND tenant_id=t) != 1 THEN
 RAISE EXCEPTION 'Role assignment was not persisted'; END IF;
 BEGIN
  INSERT INTO app_role_permissions(tenant_id,role_id,permission_key) VALUES(t,r,'unknown.permission');
  RAISE EXCEPTION 'Unregistered permission accepted';
 EXCEPTION WHEN foreign_key_violation THEN NULL;
 END;
 IF (SELECT count(*) FROM app_modules WHERE key='developer') != 1 THEN
 RAISE EXCEPTION 'Missing developer subsystem';END IF;
END $$;
ROLLBACK;
