-- Run using psql -v ON_ERROR_STOP=1 against a disposable migrated test DB.
BEGIN;
DO $$
DECLARE t uuid := '00000000-0000-4000-8000-000000000001';
        p uuid; e uuid; n uuid; a bigint;
BEGIN
 INSERT INTO patients(tenant_id,mrn,given_name,family_name,birth_date)
 VALUES(t,'AUDIT-SYNTHETIC-ONLY','Test','Audit','2000-01-01')
 RETURNING id INTO p;
 INSERT INTO encounters(tenant_id,patient_id,reason)
 VALUES(t,p,'Synthetic audit test') RETURNING id INTO e;
 INSERT INTO clinical_notes(tenant_id,encounter_id,author_label,content)
 VALUES(t,e,'Fictional Clinician','Synthetic note') RETURNING id INTO n;
 UPDATE encounters SET status='finished',finished_at=now() WHERE id=e;
 SELECT count(*) INTO a FROM audit_events
 WHERE tenant_id=t AND (
   (entity_type='patients' AND entity_id=p AND action='created') OR
   (entity_type='encounters' AND entity_id=e) OR
   (entity_type='clinical_notes' AND entity_id=n AND action='created'));
 IF a != 4 THEN RAISE EXCEPTION 'Expected 4 audit events, got %',a; END IF;
END $$;
ROLLBACK;

-- Confirm audit table cannot be silently edited, even with table write privileges.
BEGIN;
DO $$
DECLARE event_id bigint;
BEGIN
 INSERT INTO patients(tenant_id,mrn,given_name,family_name,birth_date)
 VALUES('00000000-0000-4000-8000-000000000001','AUDIT-GUARD-SYNTHETIC','Test','Guard','2001-01-01');
 SELECT id INTO event_id FROM audit_events ORDER BY id DESC LIMIT 1;
 BEGIN
   DELETE FROM audit_events WHERE id=event_id;
   RAISE EXCEPTION 'Deletion unexpectedly succeeded';
 EXCEPTION WHEN raise_exception THEN
   IF SQLERRM='Deletion unexpectedly succeeded' THEN RAISE; END IF;
 END;
END $$;
ROLLBACK;
