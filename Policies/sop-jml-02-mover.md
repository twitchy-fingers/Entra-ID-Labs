# SOP-JML-02: Mover (Role Change, Transfer, Promotion)

| Field | Value |
|---|---|
| Document ID | SOP-JML-02 |
| Owner | Identity & Access Management (IAM) |
| Version | 1.0 |
| Effective date | YYYY-MM-DD |
| Review cycle | Annual |
| Related | SOP-JML-01 Joiner, SOP-JML-03 Leaver |

## 1. Purpose

Ensures that when a user changes role, access from the previous role is removed and only access for the new role is granted, preventing accumulation of access over time (privilege creep).

## 2. Scope

Any change of role, department, or reporting line for an active workforce member account.

## 3. Roles and responsibilities

| Role | Responsibility |
|---|---|
| HR | Submits the approved role change with an effective date |
| New manager | Approves the new role; reviews any non-role group memberships the user should keep or lose |
| Previous manager | Confirms handover; is notified of access removal |
| IAM operator | Runs the mover process and verifies results |
| Security lead | Approves any move into a privileged role |

## 4. Trigger

An approved HR change record with a role from the approved catalog and an effective date.

## 5. Requirements

1. **Remove before add.** Access tied to the previous role is removed before new role access is granted.
2. **No carry-over.** Users don't keep previous-role access "for the transition." Temporary overlap requires a time-bound exception approved by the security lead.
3. **Privileged changes.** Moving into a privileged role follows SOP-JML-01 §6.5 (PIM request). Moving out of a privileged role removes all PIM eligibility.
4. **Fresh tokens.** Sessions are revoked on the effective date so applications receive updated role claims.

## 5a. Lab note

In this lab, mover changes take effect immediately. In production, schedule the run for the effective date.

## 6. Procedure

6.1 Preview:
```powershell
./scripts/mover.ps1 -UserPrincipalName <upn> -NewRole <Role> [-NewDepartment ...] [-NewJobTitle ...] [-NewManagerUserPrincipalName ...] -RevokeSessions -WhatIf
```
6.2 Confirm the preview removes the old role group(s) and adds only the new one.

6.3 Execute without `-WhatIf`.

6.4 Send the new manager the list of the user's **non-role** group memberships (`Get-MgUserMemberOfAsGroup`) for review. Remove any the new manager does not confirm within 5 business days.

## 7. Verification

- The user is in the new role group only
- PIM eligibility removed when leaving a privileged role
- Audit log shows `Remove member from group` before `Add member to group`
- After Phase 4: the user's token shows the new app role claim

## 8. Exceptions

| Situation | Handling |
|---|---|
| Overlap needed for handover | Time-bound exception (max 14 days), approved by the security lead, tracked in the ticket and removed on expiry |
| Target role group missing | Process stops. Create the group through the RBAC change process first |

## 9. Records

Run log (`logs/jml-YYYY-MM-DD.csv`) with before/after state; Entra audit log.

## 10. Control mapping

NIST SP 800-53 Rev. 5: AC-2, AC-6, PS-5 · ISO/IEC 27001:2022: A.5.18, A.6.5.
