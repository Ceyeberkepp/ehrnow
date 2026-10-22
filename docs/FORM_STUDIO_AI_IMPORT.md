# Form Studio and AI-assisted form migration

## Implemented in this development milestone
- React/TypeScript form builder with typed fields, validation requirements, draft storage and duplication.
- Rust API to create/list/copy form templates and preview deterministic field-to-JSON mapping.
- PostgreSQL versioned templates and form-entry table. **Form entry submission API is not implemented yet**.
- Mappings use stable field IDs inside form_entries.answers JSONB rather than unsafe arbitrary DDL.
- Development only, shared-token access. No real patient data.

## Screenshot/video form recreation — planned pipeline (NOT yet implemented)
1. Only upload screenshots or recordings owned by the organization or authorized for migration. Never extract or redistribute proprietary vendor source.
2. Scan media for malware and PHI, obtain authorization, encrypt storage and enforce retention/purge.
3. OCR/video frame selection and visual layout understanding extract labels, fields, validations, dropdowns, conditional sections and navigation.
4. Generate an editable **draft** form schema and reusable React components. Never auto-execute inferred code.
5. Map visible fields to canonical EHRNow clinical models where verified; otherwise store in a versioned extension schema.
6. Present confidence scores and unresolved fields with side-by-side reference comparisons.
7. Require human correction, clinically qualified review for clinical content, automated field validation, workflow test and authorized publication.
8. Log source provenance, AI model/version, prompt/rules, reviewer decisions and mapping history.

## Future studio functionality
- Drag/drop layouts, grids, repeatable sections, conditional logic and calculated fields with restricted expression grammar.
- Import/export, clone, template history, diff, rollback, form publishing and permissions.
- Typed form response API, migrations from JSONB draft fields to canonical clinical data, mapping conflict reports and reconciliation.
- Video recording process discovery for multipage workflow recreation rather than merely matching one image.
- Role-based view/create/edit/publish permissions enforced in Rust and PostgreSQL RLS, with access tests.
- Visual regression comparisons and accessibility validation for every generated form.

## Safety and legal guards
Do not assume vendor UI screenshots imply permission to clone proprietary visual branding, text, or protected workflows. Use only authorized references and produce independently owned interfaces. AI output does not constitute verified clinical logic.
