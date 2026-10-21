# Architecture decision record — initial baseline

## Principles

1. Maintain one authoritative PostgreSQL transaction model for clinical data.
2. Keep transactional boundaries inside the Rust clinical core initially; split distributed components only for justified domains.
3. Use Go for asynchronous integrations, scheduling and revenue workflows.
4. Publish domain events via a PostgreSQL transactional outbox; downstream NATS events and MongoDB/Neo4j projections are **future work**, not implemented.
5. All domain entities carry tenant provenance and enforce effective authorization. Current header-supplied tenant and shared token are development-only, not real tenant isolation.
6. HL7 FHIR R4, US Core, SMART on FHIR, HL7 v2, C-CDA, DICOM and X12 adapters each need a conformance and security test suite before claiming support.
7. Treat medication safety, wrong-patient errors and alerting as safety-critical, with explicit human review and clinical hazard management.

## Target domains

Patient identity/MPI, longitudinal chart, encounters, allergies, medications, orders/results, diagnostics, emergency, admissions/transfers/discharges, nursing/eMAR, surgery, pharmacy, imaging, schedules, billing, claims, patient portal, specialty extensions, HIE/TEFCA, clinical analytics, population health, governance.

## Data model

**PostgreSQL:** authoritative clinical and financial operations + transactional outbox.
**MongoDB:** versioned non-authoritative read projections/forms, not independent clinical writes.
**Neo4j:** access-constrained care and provenance relationships derived from verified source data.
**S3:** imaging and clinical document binaries with object integrity and lifecycle rules.
**OpenSearch:** authorization-filtered search projections.
**Redis:** ephemeral cache only, no chart system of record.

No distributed dual-write on a critical clinical transaction. Graph and document projection lag must never affect whether a clinical commit succeeds. Sensitive reads must enforce authorization against the source of truth.

## Development slice (implemented)

POST /dev/bootstrap — development-only fictional tenant setup.
GET /api/v1/patients — list latest 100 fictional patients under demo tenant.
POST /api/v1/patients — insert fictional patient + outbox event atomically.
GET /api/v1/patients/{id} — fetch a fictional patient record.
GET /health — local liveness.

All clinical-domain endpoints require the local development bearer token. No real authentication, permission model, consent engine, or FHIR certification is implemented.

## Next vertical slices

Replace shared secret with OIDC authentication, tenant membership and ABAC policies, then add enforced PostgreSQL RLS. Build MPI, encounters, notes/signing, provenance, order workflow, terminology, FHIR resource validation, interface engine, and consent. Clinical features remain disabled until clinical safety review.
