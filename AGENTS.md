# EHRNow development rules

EHRNow is proprietary software, all rights reserved. See LICENSE. Never treat this repository as open source. No use, copying, redistribution, hosting or commercialization without express written permission.

## Frontend — mandatory
- Use **React + TypeScript + TSX** for every application frontend.
- Build reusable accessible components with a consistent design system and typed API clients.
- **Never create standalone HTML-based UI pages**, HTML templates, server-rendered interface markup, or static HTML demos as replacement implementations.
- The minimal Vite `index.html` bootstrap document is allowed; it must not implement application screens.
- Avoid direct DOM manipulation and unsafe HTML injection.
- No PHI in browser storage, logs, or demo data. Backends enforce permissions, not React.

## Backend and data
- Rust for clinical transactional core, Go for workflow/integrations.
- PostgreSQL source of truth; MongoDB and Neo4j only for specifically defined derived models until designs are reviewed.
- No real patient data or clinical use. OIDC, tenant isolation, consent, audit, safety validation and security controls must precede clinical deployment.

## Definition of done
Working end-to-end React screens, real API operations, durable persistence, proper permissions, error handling, tests and documented clinical safety checks. No fake claims of completeness.
