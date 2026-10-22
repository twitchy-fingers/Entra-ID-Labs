# SOP-JML-03: Leaver (Termination and Offboarding)

| Field | Value |
|---|---|
| Document ID | SOP-JML-03 |
| Owner | Identity & Access Management (IAM) |
| Version | 1.0 |
| Effective date | YYYY-MM-DD |
| Review cycle | Annual |
| Related | SOP-JML-01 Joiner, SOP-JML-02 Mover |

## 1. Purpose

Ensures all access is removed promptly when a workforce member leaves, evidence of removed access is retained, and the account is disposed of after a defined retention period.

## 2. Scope

All workforce member accounts at termination, voluntary or involuntary.

## 3. Roles and responsibilities

| Role | Responsibility |
|---|---|
| HR | Notifies IAM of the termination, type, and last working day |
| Manager | Confirms data handover needs (mailbox, files) |
| IAM operator | Runs the leaver process, verifies, and handles exceptions |
| Security lead | Notified immediately for involuntary terminations and any privileged account |

## 4. Timing

| Termination type | Access removal deadline |
|---|---|
| Involuntary | **Immediately**, coordinated with HR so access is removed at or before the time the person is notified |
| Voluntary | End of the last working day |
| Privileged account (any type) | Immediately, with security lead notified |

## 5. Requirements

1. **Disable, then revoke.** The account is disabled first, then sessions are revoked. Revocation alone is not offboarding.
2. **Remove all access paths:** assigned groups, PIM eligibility, active directory roles, direct app role assignments.
3. **Evidence before removal.** A snapshot of all access is captured before anything is changed.
4. **Retain, then delete.** Disabled accounts are retained for **30 days**, then deleted. Deleted accounts remain recoverable for a further 30 days (Entra soft-delete).
5. **No reuse.** UPNs of departed users aren't reassigned to new people during the retention period.

## 6. Procedure

6.1 Preview:
```powershell
./scripts/leaver.ps1 -UserPrincipalName <upn> -TerminationType <Voluntary|Involuntary> -TicketNumber <ticket> -WhatIf
```

6.2 Execute without `-WhatIf`.

6.3 For each `[WARNING] Active directory role found`: open **PIM → Microsoft Entra roles → Assignments**, remove the active assignment, and record it in the ticket.

6.4 For any `[ERROR]` group removal: remove manually and record it.

6.5 Out of scope for this identity lab, but required in production: mailbox conversion or delegation, OneDrive ownership transfer, device wipe or retirement, and revocation of any non-SSO application accounts.

6.6 After 30 days: confirm with HR there is no rehire or legal hold, then delete the account and record the deletion.

## 7. Verification (same day)

- Account status **Disabled**
- Test sign-in fails with **AADSTS50057**
- No assigned groups, PIM eligibility, or direct app role assignments remain
- Snapshot JSON exists in `logs/`
- Entra audit log shows: `Update user` (disable), `Invalidate all refresh tokens for user`, `Remove member from group`

## 8. Exceptions

| Situation | Handling |
|---|---|
| Legal hold | Retain disabled indefinitely until legal releases the hold |
| Rehire within 30 days | Re-enable and process as a mover into the new role |
| Contractor end date | Same process; triggered by the contract end date |

## 9. Records

Run log, evidence snapshot, ticket, and Entra audit log. Retain for 1 year minimum.

## 10. Control mapping

NIST SP 800-53 Rev. 5: AC-2, AC-2(3), PS-4 · ISO/IEC 27001:2022: A.5.18, A.6.5.
