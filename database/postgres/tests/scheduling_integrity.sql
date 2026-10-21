-- PostgreSQL synthetic scheduling integrity tests.
BEGIN;
DO $$
DECLARE tenant uuid := '00000000-0000-4000-8000-000000000001';
p uuid; doc uuid; room uuid;
BEGIN
 INSERT INTO patients(tenant_id,mrn,given_name,family_name,birth_date)
 VALUES(tenant,'SYNTHETIC-APPT-001','Sample','Schedule','2000-01-01') RETURNING id INTO p;
 INSERT INTO practitioners(tenant_id,display_name) VALUES(tenant,'Fictional Clinician') RETURNING id INTO doc;
 INSERT INTO care_locations(tenant_id,display_name) VALUES(tenant,'Demo Room A') RETURNING id INTO room;
 INSERT INTO appointments(tenant_id,patient_id,practitioner_id,location_id,starts_at,ends_at,reason)
 VALUES(tenant,p,doc,room,'2030-01-01 13:00+00','2030-01-01 13:30+00','Synthetic appointment');
 BEGIN
   INSERT INTO appointments(tenant_id,patient_id,practitioner_id,location_id,starts_at,ends_at,reason)
   VALUES(tenant,p,doc,room,'2030-01-01 13:15+00','2030-01-01 13:45+00','Overlapping synthetic appointment');
   RAISE EXCEPTION 'Overlapping booking erroneously accepted';
 EXCEPTION WHEN exclusion_violation THEN NULL;
 END;
 IF (SELECT COUNT(*) FROM audit_events WHERE tenant_id=tenant AND entity_type='appointments') != 1
 THEN RAISE EXCEPTION 'Expected one appointment audit event'; END IF;
END $$;
ROLLBACK;
