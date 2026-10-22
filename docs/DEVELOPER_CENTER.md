# EHRNow Developer Center — implementation contract

## Intended UI
The developer/administration center will contain user management, role/permission matrix, department workspaces, feature/module catalog, navigation builder, field/form builder, workflow approvals, API connectors, clinical terminology registry, audit viewer, versioned configuration and rollback. All changes must be made within React workspaces rather than through direct SQL editing.

## Current development scope
- React role designer and permission checkboxes.
- PostgreSQL role, permission and module catalog with basic constraints.
- Rust sandbox API for creating roles, saving grants and toggling module configuration.
- Module list for UI rendering.
- No real identity binding yet. All endpoints currently accept the same shared development token, so any user holding that token can edit all settings.
- **Not an authorization implementation**: role configuration cannot restrict clinical API access or represent safe patient data segregation.

## Production security acceptance (not implemented)
1. Authenticate actual users through OIDC with phishing-resistant MFA.
2. Grant role assignments to verified users within verified tenants and departments; prohibit client-chosen identity.
3. Backend guards evaluate module visibility, action permissions, resource policies and patient context on EVERY endpoint.
4. Enforce PostgreSQL RLS tied to trusted actor/tenant context and default deny.
5. Navigation is returned from a server-authorized manifest, and hidden modules cannot be accessed by direct URL or REST calls.
6. Distinguish manage / view / create / edit / delete / export / approve / break-glass capabilities. Require step-up authentication for privileged assignments.
7. Log old/new changes, actor, reason, approval and time; require two-person approvals for dangerous policy changes.
8. Prevent lockout of organization administration; version settings and support rollback.
9. Test unauthorized navigation, API calls, cross-tenant boundaries, revoked grants and stale sessions.
10. Restrict builder-defined forms and workflows to validated schemas; no arbitrary server-side code execution.

## Clinical safety
No custom role, tab, form, decision rule or workflow can bypass mandated clinical safety checks, audit trail, medical signatures, or approved drug-ordering validations.
