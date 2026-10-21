# EHRNow

**PROPRIETARY SOFTWARE — ALL RIGHTS RESERVED. NOT OPEN SOURCE.**\n\n**NO USE WITHOUT PERMISSION:** No person or organization may use, copy, modify, distribute, host, deploy, or commercialize EHRNow without prior express written permission from the copyright owner. Public access to this repository does **not** grant any license. See the [LICENSE](LICENSE) file.\n\n**Repository security:** Change GitHub repository visibility to **Private** before further proprietary development.

This repository is an **early engineering foundation, not a clinical system**. It must not store real patient data, be exposed to the Internet, or be used for clinical decisions. Only fictional test data is permitted until security and clinical safety controls have been independently verified.

## Included
- Rust/Axum patient API with PostgreSQL persistence (development only, loopback-bound).
- Go operations health service (development only, loopback-bound).
- React/TypeScript clinician UI for fictional patient registration and list.
- PostgreSQL, MongoDB, Neo4j, NATS and Redis local containers; PostgreSQL is the only source of truth for current patient features.
- Architecture specification, security gates, schema migration, CI and implementation backlog.

## Local development

Requirements: Docker Compose, Rust toolchain, Go toolchain, Node.js LTS.

1. `cp .env.example .env`
2. Set a **unique** `EHR_DEV_TOKEN` in `.env` (never commit it).
3. `docker compose up -d postgres`
4. `set -a; . ./.env; set +a; cd backend/rust/clinical-api && cargo run`
5. `cd backend/go/operations && go run .`
6. `cd apps/clinician-web && npm install && npm run dev`
7. In the UI, enter your matching development token. Test only with fictional records.

For the optional document, graph and message infrastructure: `docker compose --profile extended up -d`. These systems are provisioned for future adapters and are **not** yet wired to clinical transactions.

## Security limitations

The API uses a single shared development token, **not production user identity or RBAC**. It is disabled unless `EHR_DEV_MODE=1`, listens only on 127.0.0.1 and requires a configured development token. No production rollout until OIDC, MFA, authorization/consent, RLS, encryption, audit, rate limits, verification and threat modeling are completed. Run locally only and use synthetic records.

See [architecture](docs/ARCHITECTURE.md), [roadmap](docs/ROADMAP.md), and [security gates](docs/SECURITY.md).
