# Security and clinical safety release gates

**Current application is developer-only and unsafe for PHI.** No claim of HIPAA compliance or clinical suitability.

- [ ] Make GitHub repository private; do not commit patient records, secrets or licensed terminologies.
- [ ] Replace shared development token and client tenant header with validated OIDC/OAuth2 identity, PKCE, MFA and organization membership.
- [ ] Implement default-deny RBAC/ABAC, care relationships, break-glass and consent management.
- [ ] Enforce PostgreSQL row-level security based on trusted backend context; add tenant escape tests.
- [ ] Implement tamper-evident immutable audit pipeline, event correlation and retention.
- [ ] Implement TLS/mTLS, secrets management, encryption policies, rotation and production deployment hardening.
- [ ] Add request and event idempotency, source-provenance and conflict reconciliation.
- [ ] Review clinical hazards, medication safety and workflow risk with qualified clinicians.
- [ ] Enforce CI scans, SAST, DAST, SBOM, signed builds, incident response and tested recovery.
- [ ] Obtain needed external integration agreements, terminology licenses, attestations and certification testing.
- [ ] Validate accessibility, usability, performance and data restoration before any go-live.

The local seeded PostgreSQL password is intentionally for disposable loopback-only development. Do not reuse it, publish ports publicly or use patient data.
