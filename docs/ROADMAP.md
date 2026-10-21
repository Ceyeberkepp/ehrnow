# Product delivery roadmap

## Phase 0 — repository and nonclinical developer foundation
- [x] Rust patient registration/list/read and transactionally persisted outbox event
- [x] Go operations liveness service
- [x] React clinician shell with registry forms
- [x] PostgreSQL migration and loopback-only Docker development
- [x] Security gates and architecture
- [x] CI workflow verified on audit-integrity milestone
- [x] Initial audit integrity tests with disposable synthetic database (full integration coverage still needed)

## Phase 1 — identity and defensible tenant isolation
- [ ] OIDC / PKCE / MFA, clinician identities
- [ ] Organization/facility/department/practitioner model
- [ ] Consent, RBAC/ABAC and record-level permissions
- [ ] PostgreSQL RLS, audit and access justification

## Phase 2 — real clinical workflow foundation
- [ ] MPI matching/link/unlink/merge, identifiers and histories
- [ ] Encounter and provider workspace
- [ ] Notes, clinical provenance, signatures, immutable revisions
- [ ] FHIR R4 Patient/Encounter/Observation + validation and conformance

## Phase 3 — care workflows
- [ ] Allergies, conditions, medications, CPOE, order signing
- [ ] Laboratory lifecycle and result acknowledgment
- [ ] Nursing workflows, eMAR and patient safety
- [ ] Clinical decision support governed by validated terminology

## Phase 4 — hospital and specialty workflows
- [ ] ED, ADT, inpatient, surgery, pharmacy, imaging, device interfaces
- [ ] Specialty packs including pediatrics, cardiology and behavioral health

## Phase 5 — administration and patient services
- [ ] Scheduling, practice management, claims, revenue cycle, payments (appointment/practitioner/location schema committed; UI and APIs still pending)
- [ ] Patient portal, messaging, proxy permissions, telehealth

## Phase 6 — federation and analytics
- [ ] HL7 v2, C-CDA, DICOMweb, X12, pharmacy and network adapters
- [ ] MongoDB/Neo4j projections, search and governed analytics
- [ ] Certified interface/vendor agreement validations

## Phase 7 — production clinical safety review
- [ ] Threat modeling, extensive security/authorization tests, pen test
- [ ] Clinical safety hazard assessment, usability and qualified reviews
- [ ] HA, recovery drills, operational runbooks and regulatory certification where required
