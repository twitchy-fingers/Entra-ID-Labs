# leaver.ps1 — Termination / Offboarding

**Policy:** [SOP-JML-03 Leaver](../policies/sop-jml-03-leaver.md) · **Tests:** JML-11 to JML-16 in [test-matrix.md](../test-cases/test-matrix.md)

## Purpose

Removes all access for a departing user in a defined order, captures evidence of what was removed, and keeps the account disabled (not deleted) for the retention period.

## Order of operations, and why it matters

| Step | Action | Reason for this position |
|---|---|---|
| 0 | Evidence snapshot | Must run before anything is removed, or the record of what they had is lost |
| 1 | Disable account | Stops new sign-ins immediately; this is the most important step |
| 2 | Revoke sessions | Invalidates refresh tokens and session cookies already issued |
| 3 | Remove PIM eligibility | Eligibility could otherwise be re-used if the account were re-enabled |
| 4 | Report active directory roles | Activated or standing admin roles need human review |
| 5 | Remove assigned groups | Removes RBAC role groups and any other assigned groups |
| 6 | Remove direct app role assignments | Catches anything granted outside the role-group model (itself a finding) |
| 7 | Reclaim direct licenses | Cost control; skipped with `-KeepLicense` |

Dynamic groups are skipped on purpose. `RBAC-StandardEmployee` (Phase 3) includes only enabled accounts, so disabling the user removes them automatically. Test JML-13 proves this.

## Prerequisites

- Graph scopes (requested automatically): `User.ReadWrite.All`, `Group.ReadWrite.All`, `AppRoleAssignment.ReadWrite.All`, `RoleManagement.Read.Directory`, `RoleEligibilitySchedule.ReadWrite.Directory`

## Parameters

| Parameter | Required | Description |
|---|---|---|
| `-UserPrincipalName` | Yes | Departing user |
| `-TerminationType` | Yes | `Voluntary` or `Involuntary` (affects timing in the SOP; recorded in logs) |
| `-TicketNumber` | No | HR/ITSM reference, written to the log and PIM justification |
| `-KeepLicense` | No | Skip license reclamation (e.g., mailbox retention needs) |
| `-WhatIf` | No | Preview. The snapshot is still written, since it's read-only evidence. |

## Usage

```powershell
./leaver.ps1 -UserPrincipalName jchen@danotech.onmicrosoft.com -TerminationType Voluntary -TicketNumber HR-2041 -WhatIf
./leaver.ps1 -UserPrincipalName jchen@danotech.onmicrosoft.com -TerminationType Voluntary -TicketNumber HR-2041
```

## Expected output

- `Evidence snapshot — logs/leaver-snapshot-E1024-<timestamp>.json`
- `Disable account`, `Revoke sessions`
- `Remove group RBAC-SalesRep`
- `[SKIPPED] Group RBAC-StandardEmployee — Dynamic group ...`
- `Reclaim licenses`
- `Leaver complete — Account retained (disabled)`

## Verify

1. Jun Chen → **Overview**: Account status **Disabled**.
2. Try signing in as Jun in a private browser window. Sign-in fails with **AADSTS50057** (user account is disabled).
3. **Sign-in logs** → filter User = Jun, Status = Failure → error code `50057`.
4. Jun → **Groups**: no assigned groups remain. After a few minutes, the dynamic group is gone too.
5. Open the snapshot JSON in `logs/` to confirm it lists what was removed.

## Screenshots

| ID | File | Must show |
|---|---|---|
| P1-12 | `screenshots/jml/leaver-output.png` | Full leaver run |
| P1-13 | `screenshots/jml/leaver-account-disabled.png` | User overview showing account disabled |
| P1-14 | `screenshots/jml/leaver-signin-blocked-50057.png` | Sign-in log failure with error code 50057 |
| P1-15 | `screenshots/jml/leaver-snapshot-json.png` | Snapshot file contents (blur object IDs if you prefer) |
| P1-16 | `screenshots/jml/leaver-dynamic-group-removed.png` | (After Phase 3) RBAC-StandardEmployee members, Jun no longer listed |

## Limitations

- Activated PIM roles are reported, not removed, because removing an activated assignment requires a different PIM action. The SOP covers the manual step.
- Mailbox, OneDrive, and device wipe are out of scope for this identity-only lab and are noted in the SOP.
