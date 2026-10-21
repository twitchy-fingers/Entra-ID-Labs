# Screenshot Checklist

Every screenshot in the lab, where to save it, and what must be visible. Tick each one off as you capture it. New phases append to this file.

## Capture rules

- **Always blur:** temporary passwords, client secrets, subscription IDs, and any real personal data.
- **Optional blur:** tenant ID and object IDs (not secret, but some people prefer to hide them).
- **Make the evidence obvious:** the key field (status, error code, role name, "Eligible") should be visible without zooming. Crop to the relevant pane.
- **Keep timestamps visible** on log screenshots. They prove sequence (e.g., remove happened before add).
- Use PNG and the exact file name below so README links work.

## Phase 0 — Prerequisites

| ✓ | ID | File | Must show |
|---|---|---|---|
| ☐ | P0-01 | `screenshots/setup/p2-license-active.png` | Licenses → All products, P2/Governance product with license count |
| ☐ | P0-02 | `screenshots/setup/graph-connect-context.png` | `Get-MgContext` output: account and scopes |

## Phase 1 — JML

| ✓ | ID | Capture when | File | Must show |
|---|---|---|---|---|
| ☐ | P1-01 | Phase 1 | `screenshots/jml/joiner-whatif-output.png` | Cyan WHATIF lines; nothing created |
| ☐ | P1-02 | Phase 1 | `screenshots/jml/joiner-run-output.png` | Live joiner run, **password column blurred** |
| ☐ | P1-03 | Phase 1 | `screenshots/jml/users-list-with-attributes.png` | All users with Department, Job title, Employee ID columns |
| ☐ | P1-04 | Phase 1 | `screenshots/jml/user-properties-manager.png` | Kelechi Adeyemi: Employee ID, hire date, manager |
| ☐ | P1-05 | Phase 1 | `screenshots/jml/joiner-invalid-role-rejected.png` | ERROR line for `SalesDirector` |
| ☐ | P1-06 | Phase 1 | `screenshots/jml/itadmin-no-roles.png` | Tanisha Carter → Assigned roles: empty |
| ☐ | P1-07 | Phase 1 | `screenshots/jml/joiner-idempotent-rerun.png` | Re-run, all SKIPPED |
| ☐ | P1-08 | Phase 1 | `screenshots/jml/audit-log-add-user.png` | Audit log "Add user" with Initiated by |
| ☐ | P1-09 | Phase 3 | `screenshots/jml/mover-output.png` | Mover run with before/after |
| ☐ | P1-10 | Phase 3 | `screenshots/jml/mover-audit-remove-then-add.png` | Remove then add, same initiator, timestamps |
| ☐ | P1-11 | Phase 7 | `screenshots/jml/mover-pim-eligibility-removed.png` | Tanisha Carter: no eligible assignments after move |
| ☐ | P1-12 | Phase 3 | `screenshots/jml/leaver-output.png` | Full leaver run |
| ☐ | P1-13 | Phase 3 | `screenshots/jml/leaver-account-disabled.png` | Account status disabled |
| ☐ | P1-14 | Phase 3 | `screenshots/jml/leaver-signin-blocked-50057.png` | Sign-in log failure, error 50057 |
| ☐ | P1-15 | Phase 3 | `screenshots/jml/leaver-snapshot-json.png` | Snapshot JSON contents |
| ☐ | P1-16 | Phase 3 | `screenshots/jml/leaver-dynamic-group-removed.png` | RBAC-StandardEmployee without Jun |
| ☐ | P1-17 | Phase 1 | `screenshots/jml/revoke-sessions-output.png` | Revocation output with reason |
| ☐ | P1-18 | Phase 1 | `screenshots/jml/audit-log-invalidate-tokens.png` | "Invalidate all refresh tokens for user" entry |

## Phase 2 onward

*Appended as each phase is built.*
