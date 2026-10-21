-- Development baseline: PostgreSQL is authoritative for clinical transactions.
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TABLE IF NOT EXISTS tenants (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 name text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS patients (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 tenant_id uuid NOT NULL REFERENCES tenants(id),
 mrn text NOT NULL,
 given_name text NOT NULL CHECK(length(given_name) BETWEEN 1 AND 120),
 family_name text NOT NULL CHECK(length(family_name) BETWEEN 1 AND 120),
 birth_date date NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(tenant_id,mrn),
 UNIQUE(tenant_id,id)
);
CREATE INDEX IF NOT EXISTS idx_patients_tenant_name ON patients(tenant_id, family_name, given_name);
CREATE TABLE IF NOT EXISTS outbox_events (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 tenant_id uuid NOT NULL REFERENCES tenants(id),
 aggregate_type text NOT NULL,
 aggregate_id uuid NOT NULL,
 event_type text NOT NULL,
 payload jsonb NOT NULL,
 occurred_at timestamptz NOT NULL DEFAULT now(),
 published_at timestamptz
);
CREATE INDEX IF NOT EXISTS idx_outbox_pending ON outbox_events(occurred_at) WHERE published_at IS NULL;
-- RLS policies are required before production; this demo database is NOT PHI-safe.
