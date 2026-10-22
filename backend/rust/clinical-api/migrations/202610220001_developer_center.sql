-- Developer console foundation. This is configuration, NOT an enforced authentication system.
CREATE TABLE app_modules (
 key text PRIMARY KEY CHECK (key ~ '^[a-z][a-z0-9_.-]{1,63}$'),
 label text NOT NULL,
 enabled boolean NOT NULL DEFAULT true,
 sort_order integer NOT NULL DEFAULT 100
);
CREATE TABLE app_permissions (
 key text PRIMARY KEY CHECK (key ~ '^[a-z][a-z0-9_.-]{1,95}$'),
 module_key text NOT NULL REFERENCES app_modules(key),
 label text NOT NULL
);
CREATE TABLE app_roles (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 tenant_id uuid NOT NULL REFERENCES tenants(id),
 name text NOT NULL CHECK (length(trim(name)) BETWEEN 2 AND 80),
 description text NOT NULL DEFAULT '',
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(tenant_id,name),
 UNIQUE(tenant_id,id)
);
CREATE TABLE app_role_permissions (
 tenant_id uuid NOT NULL,
 role_id uuid NOT NULL,
 permission_key text NOT NULL REFERENCES app_permissions(key),
 PRIMARY KEY(tenant_id,role_id,permission_key),
 FOREIGN KEY(tenant_id,role_id) REFERENCES app_roles(tenant_id,id) ON DELETE CASCADE
);
INSERT INTO app_modules(key,label,sort_order) VALUES
('overview','Overview',10),('patients','Patients',20),('encounters','Encounters',30),
('problems','Problem List',40),('allergies','Reported Allergies',50),
('scheduling','Scheduling',60),('infrastructure','Infrastructure',70),
('developer','Developer Center',90);
INSERT INTO app_permissions(key,module_key,label) VALUES
('overview.view','overview','View overview'),
('patients.view','patients','View patients'),('patients.create','patients','Register patients'),
('encounters.view','encounters','View encounters'),('encounters.create','encounters','Create encounters'),
('problems.view','problems','View problem list'),('problems.write','problems','Manage problems'),
('allergies.view','allergies','View allergy history'),('allergies.write','allergies','Record allergy history'),
('scheduling.view','scheduling','View scheduling'),('scheduling.create','scheduling','Create appointments'),
('infrastructure.view','infrastructure','View platform status'),
('developer.manage','developer','Manage configuration');
-- Application access must remain disabled for real clinical users until OIDC/ABAC
-- and server-side policy enforcement exist. These records only model the configuration.
