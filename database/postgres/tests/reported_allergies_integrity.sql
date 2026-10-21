BEGIN;
DO $$
DECLARE t uuid := '00000000-0000-4000-8000-000000000001';
p uuid; a uuid;
BEGIN
 INSERT INTO patients(tenant_id,mrn,given_name,family_name,birth_date) VALUES(t,'ALLERGY-SYNTHETIC-ONLY','Fictional','Patient','2001-01-01') RETURNING id INTO p;
 INSERT INTO reported_allergies(tenant_id,patient_id,substance_label,reaction_label)
 VALUES(t,p,'Synthetic test substance','Synthetic test reaction') RETURNING id INTO a;
 IF (SELECT count(*) FROM audit_events WHERE entity_type='reported_allergies' AND entity_id=a AND action='created') != 1 THEN
   RAISE EXCEPTION 'Expected audit event';
 END IF;
 BEGIN
  INSERT INTO reported_allergies(tenant_id,patient_id,substance_label,reaction_label)
  VALUES(t,p,'','Reaction');
  RAISE EXCEPTION 'Blank reported substance unexpectedly accepted';
 EXCEPTION WHEN check_violation THEN NULL;
 END;
END $$;
ROLLBACK;
