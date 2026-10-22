# EHRNow full platform delivery map

## Current baseline
Private HTTPS deployment, PostgreSQL, Rust development API, React shell, synthetic patient registry, early encounters, scheduling, problems, allergies, Developer Center configuration preview, and optional Adminer. None of these constitute a validated clinical EHR.

## Product areas requested — implementation scope
| Area | Work required before declaring available |
|---|---|
| Global administration | Installer bootstrap, user directory, organizations/facilities/departments, enforced RBAC, identity/MFA, delegated administrators, group membership, policies, audit and access reviews |
| Clinical desktop | Customizable dashboard, patient banner, longitudinal chart, encounters, chart search, clinical documentation, care team, tasks, handoffs |
| Patient management | Registration, MPI, demographics, consent, insurance, referrals, document intake, patient merge with audit |
| Orders and results | Labs, imaging, procedures, catalog, signed orders, result ingestion, abnormal-result routing, critical alerts |
| Medication | Reconciliation, allergies/interactions, formulary, prescription orders, controlled-substance controls, external electronic prescribing partner |
| Specialty workflows | Primary care, urgent care, emergency, inpatient, ICU, nursing, surgery, anesthesia, therapy, behavioral health, oncology and specialty modules |
| Revenue cycle | Eligibility, charges, coding, claims, denials, payment posting, contracts, patient billing |
| Patient engagement | Portal, secure messaging, questionnaires, appointments, telehealth, outreach |
| Operations | Scheduling resources, staffing, beds, locations, assets, queue management, inventory, reporting and analytics |
| Integration | HL7 v2, FHIR R4/R5 depending target, terminology, identity, payer clearinghouses, PACS/DICOM, external labs/pharmacy integrations; each needs actual implementation and conformance tests |
| Developer Center | Enforced role/permission editor, tenant controls, feature flags, form studio, workflow designer, mappings, integrations, audit, publishing/versioning/rollback and API developer tooling |
| Data | PostgreSQL transactional data; optional document/graph/search services only when actual adapters and reconciliation exist |
| Infrastructure | Fast reproducible installer, HTTPS, database GUI, secure config, secrets, backup/restore, monitoring, automated upgrades, migration rollback |

## Release gates, in dependency order
1. **Identity and safety baseline:** first-run administrator with anti-takeover control; secure password hashing, sessions, logout, account lockout/rate limits, MFA plan, HTTP-only cookies/CSRF, RBAC enforcement on every backend endpoint, tenant isolation and audit coverage. No real PHI before full review.
2. **Functional clinical core:** chart, encounters, notes, problems, allergies, scheduling, orders and results, with transaction/integration tests and synthetic fixtures.
3. **Administration:** global admin console with users, roles, permissions, organization settings, workflows, module settings and change history.
4. **Form Studio / workflow platform:** visual form designer, schema-backed mappings, validation, versioning, review/publish, import from images/video as a separate, review-required assistant feature.
5. **Specialties and operations:** build workflows by specialty with clinical review, roles, APIs, database migrations and tests.
6. **Interoperability and revenue cycle:** standards-based integration and external partner certification/testing.
7. **Preproduction verification:** threat modeling, accessibility, disaster recovery, operational monitoring, performance, compliance and independent clinical safety evaluations.

## Honest completion rule
A navigation item or placeholder is not equivalent to an implemented subsystem. An item is complete only when its UI, API, persistence, authorization, audit, automated tests, workflow validation and documentation are delivered and tested. This repo is currently synthetic-data-only.
