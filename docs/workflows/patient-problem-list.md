# Patient problem list — development vertical slice

## Scope
Synthetic patient problem records only. **No diagnoses, prescribing, medication advice, clinical decision support, patient care or real PHI.**

## API contract (developer sandbox)
All paths require the configured development bearer token and fixed synthetic-tenant header.

- `GET /api/v1/patients/{id}/problems` — returns up to 100 ordered problem records for the synthetic patient; 404 when patient missing.
- `POST /api/v1/patients/{id}/problems` — JSON `{"description":"Synthetic test condition"}`; returns 201 on success. Rejects blank or >500-character descriptions.
- `POST /api/v1/problems/{id}/resolve` — transitions active -> resolved and records timestamp, returning 409 for nonexistent/already resolved.

The create and resolve operations write domain outbox events within the same SQL transaction. Audit triggers record inserts and updates.

## Acceptance criteria
- React page is navigable and supports selection, create, list, and resolve.
- SQL enforces tenant-scoped patient links and clinical_status constraints.
- Duplicate resolution attempts cannot change an already resolved record.
- API rejects unauthenticated requests and non-demo tenant IDs.
- SQL integrity test exercises insert, transition, audit events and invalid blank description.
- Rust Clippy/tests, TypeScript build and PostgreSQL test jobs pass.

## Clinical release blockers
Do not use this for clinical data until: verified clinician identity, RBAC/ABAC and consent, RLS, provenance and source attribution, SNOMED CT/ICD coding workflow and licensing, clinical status semantics, longitudinal chart integration, error review, full audit protections, interface conformance, clinical review and independent security validation are complete.
