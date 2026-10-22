# mover.ps1 — Role Change (Transfer / Promotion)

**Policy:** [SOP-JML-02 Mover](../policies/sop-jml-02-mover.md) · **Tests:** JML-08 to JML-10 in [test-matrix.md](../test-cases/test-matrix.md)

## Purpose

Moves a user from one role to another. Old role access is removed **before** new access is added, so users never accumulate access from previous roles. Privilege creep usually comes from movers, not joiners.

## Design decisions

| Decision | Why |
|---|---|
| Remove before add | Prevents a window where the user holds both old and new access, and prevents leftover access building up. |
| Only RBAC role groups are touched | Non-role groups (project teams, distribution) are out of scope for an automated role change and are reviewed by the manager. |
| PIM eligibility removed when moving to a non-privileged role | Admin eligibility shouldn't survive a move out of IT Admin. |
| Moving into a privileged role is flagged, not granted | Same rule as joiner: privileged access needs a separate PIM request. |
| `-RevokeSessions` switch | App role claims live in the token. Revoking forces a new token so the app sees the new role at next sign-in. |
| Before/after state logged | Gives auditors evidence of exactly what changed. |

## Prerequisites

- Phase 3 complete (role groups exist). Mover fails clearly if the target role group is missing.
- Graph scopes (requested automatically): `User.ReadWrite.All`, `Group.ReadWrite.All`, `RoleManagement.Read.Directory`, `RoleEligibilitySchedule.ReadWrite.Directory`

## Parameters

| Parameter | Required | Description |
|---|---|---|
| `-UserPrincipalName` | Yes | User to move |
| `-NewRole` | Yes | Key from the role catalog, e.g. `SalesManager` |
| `-NewDepartment` | No | Updates `department` |
| `-NewJobTitle` | No | Updates `jobTitle` |
| `-NewManagerUserPrincipalName` | No | Sets a new manager |
| `-RevokeSessions` | No | Forces fresh tokens with new role claims |
| `-WhatIf` | No | Preview without changes |

## Usage

```powershell
# Promotion: Sales Rep → Sales Manager
./mover.ps1 -UserPrincipalName kadeyemi@danotech.onmicrosoft.com `
    -NewRole SalesManager -NewJobTitle "Sales Manager" -RevokeSessions -WhatIf

./mover.ps1 -UserPrincipalName kadeyemi@danotech.onmicrosoft.com `
    -NewRole SalesManager -NewJobTitle "Sales Manager" -RevokeSessions

# Move out of a privileged role (run after Phase 7 so there is a PIM eligibility to remove)
./mover.ps1 -UserPrincipalName tcarter@danotech.onmicrosoft.com `
    -NewRole ITSupport -NewJobTitle "IT Support Specialist"
```

## Expected output

```
[SUCCESS] Mover   kadeyemi@...   Before state — Dept=Sales; Title=Sales Representative; RoleGroups=RBAC-SalesRep
[SUCCESS] Mover   kadeyemi@...   Remove role group RBAC-SalesRep
[SUCCESS] Mover   kadeyemi@...   Add role group RBAC-SalesManager — Added
[SUCCESS] Mover   kadeyemi@...   Update attributes — JobTitle=Sales Manager
[SUCCESS] Mover   kadeyemi@...   Revoke sessions
[SUCCESS] Mover   kadeyemi@...   After state — Role=SalesManager; RoleGroups=RBAC-SalesManager
```

## Verify in the portal

1. Kelechi Adeyemi → **Groups**: only `RBAC-SalesManager` among role groups.
2. **Audit logs** → Category `GroupManagement`: a `Remove member from group` entry followed by `Add member to group`, same initiator, seconds apart.
3. After Phase 4: sign in as Kelechi and decode the token at jwt.ms. The `roles` claim shows `Sales.ReadWrite.All`, not `.Own`.

## Screenshots

| ID | File | Must show |
|---|---|---|
| P1-09 | `screenshots/jml/mover-output.png` | Full mover run with before/after lines |
| P1-10 | `screenshots/jml/mover-audit-remove-then-add.png` | Audit log with remove-then-add entries and timestamps |
| P1-11 | `screenshots/jml/mover-pim-eligibility-removed.png` | (After Phase 7) Tanisha Carter's PIM eligible assignments: empty after the move |

## Limitations

- Changes take effect immediately. A real deployment would schedule moves for the effective date.
- Non-role group memberships are deliberately left for manager review (see SOP-JML-02 §6).
