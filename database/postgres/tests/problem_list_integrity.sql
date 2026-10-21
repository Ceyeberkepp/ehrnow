BEGIN;
DO $$
DECLARE t uuid := '00000000-0000-4000-8000-000000000001';
p uuid; pr uuid;
BEGIN
 INSERT INTO patients(tenant_id,mrn,given_name,family_name,birth_date)
 VALUES(t,'SYNTH-PROBLEM-TEST','Demo','Only','2000-01-01') RETURNING id INTO p;
 INSERT INTO patient_problems(tenant_id,patient_id,description) VALUES(t,p,'Synthetic problem')
 RETURNING id INTO pr;
 IF (SELECT clinical_status FROM patient_problems WHERE id=pr) != 'active' THEN
   RAISE EXCEPTION 'New problem status unexpected';
 END IF;
 UPDATE patient_problems SET clinical_status='resolved',resolved_at=now() WHERE id=pr;
 IF (SELECT count(*) FROM audit_events WHERE tenant_id=t AND entity_type='patient_problems' AND entity_id=pr) != 2 THEN
   RAISE EXCEPTION 'Problem audit event mismatch';
 END IF;
 BEGIN
  INSERT INTO patient_problems(tenant_id,patient_id,description) VALUES(t,p,'');
  RAISE EXCEPTION 'Empty description accepted';
 EXCEPTION WHEN check_violation THEN NULL;
 END;
END $$;
ROLLBACK;
