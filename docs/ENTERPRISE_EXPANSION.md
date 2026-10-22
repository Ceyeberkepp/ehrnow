# EHRNow Enterprise Capability Expansion

Status: **product requirements backlog, not implemented capabilities.** These subsystems appear disabled in the Developer Center until tested and approved.

## Clinical
- Longitudinal patient chart with reconciled identities, chart timeline, document provenance and allergy/problem/medication histories.
- Orders and results: CPOE, lab specimens, critical values, imaging, referral tracking, medical devices.
- Inpatient ADT/bed boards; nursing/eMAR/barcode; ED triage and surgical/anesthesia.
- Medication reconciliation, formulary, contraindications, verification, pharmacy exchanges and clinical decision support (only with qualified review).
- Specialty-specific workflows, including pediatrics, OB/GYN, behavioral health, oncology and cardiology.

## Administrative
- Scheduling templates, availability rules, resource calendars and patient check-in.
- Eligibility, benefits, prior authorization, claims/ERA, denial management and revenue reporting.
- Multi-facility organization hierarchy, capacity planning, staffing and asset control.
- Patient portal with verified proxy access, results, messaging, telehealth and payments.

## Developer Center subsystems
1. Identity and tenant administration with scoped roles, user memberships, lifecycle deprovisioning.
2. Declarative navigation manager: versioned menu entries, route permissions, workspace ordering and localization.
3. Typed form designer using a reviewed schema registry, no arbitrary JavaScript execution.
4. Workflow designer with validation, bounded retry, recovery, approvals and published immutable workflow versions.
5. Rules and clinical template registry with versioned medical content and clinical change-control.
6. Integration Center with credential vault references, FHIR/HL7 mapping, queues, failures and safe replays.
7. Operational observability: job queues, backups, service health, interface latency and DR evidence.
8. Audit Explorer for authorized security officers with patient-access disclosure logs, suspicious activity flags and immutable evidence.
9. Feature release center with staging, test/approval, activation, rollback, dependency checks and change trails.
10. Tenant scope manager to separate organization, facility, department and user-level customizations.

## Release enforcement invariants
- Default-deny is applied at the API, DB and job-worker boundaries; hiding a React navigation entry cannot grant or revoke resource access.
- Every privilege decision references verified actor identity, tenant membership, organization scope, resource context and specific requested action.
- Configuration publish requires signed/versioned diffs, validation, impact preview, audit trail and review for sensitive changes.
- Destructive clinical/admin actions require explicit safety constraints, approvals and rollback/recovery where appropriate.
- Clinical content must be evidence-based, licensed if applicable, reviewed by qualified clinicians and separately validated.
- Migrated patient data must preserve source identifiers and provenance and be testable for completeness and reconciliation.
- Never claim HIPAA compliance, ONC certification or patient-data readiness based only on code scaffolding.
