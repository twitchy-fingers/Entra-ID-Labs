# Control Traceability Matrix

Maps lab implementation to **NIST SP 800-53 Rev. 5** and **ISO/IEC 27001:2022 Annex A**. Each row points to the evidence that shows the control is operating, not just documented.

> This is a lab mapping to demonstrate control thinking. It is not an audit attestation.

## Identity lifecycle (Phase 1)

| Control objective | NIST 800-53 Rev. 5 | ISO 27001:2022 | Implementation | Evidence |
|---|---|---|---|---|
| Account management | AC-2 | A.5.16 Identity management | Accounts created only from the HR feed with an EmployeeId anchor (SOP-JML-01) | `joiner.ps1`, JML-01, P1-03 |
| Automated account management | AC-2(1) | A.5.16 | Joiner, mover, and leaver are scripted, repeatable, and support `-WhatIf` | `/scripts`, JML-02, JML-03 |
| Disable accounts | AC-2(3) | A.6.5 Responsibilities after termination or change of employment | Leaver disables the account first; retained 30 days, then deleted (SOP-JML-03) | `leaver.ps1`, JML-11, P1-13, P1-14 |
| Automated audit of account actions | AC-2(4) | A.8.15 Logging | Every JML action is logged locally and in the Entra audit log with the operator identity | `logs/`, JML-16, P1-08 |
| Access rights provisioning and removal | AC-2, AC-6 | A.5.18 Access rights | Access only through role groups; mover removes before adding; leaver removes all access paths | JML-07, JML-08, JML-12 |
| Least privilege at joiner | AC-6 | A.8.2 Privileged access rights | Privileged roles get no access at joiner; PIM request required | JML-06, P1-06 |
| Personnel termination | PS-4 | A.6.5 | Leaver timing by termination type; evidence snapshot | SOP-JML-03, P1-15 |
| Personnel transfer | PS-5 | A.6.5 | Mover removes previous-role access and PIM eligibility | SOP-JML-02, JML-08, JML-10 |
| Authenticator management | IA-5 | A.5.17 Authentication information | Cryptographically random temporary passwords, forced change, never logged | `JmlCommon.psm1` `New-JmlTempPassword` |
| Session termination on access change | AC-12 | A.8.5 Secure authentication | Sessions revoked at leaver and optionally at mover | `revoke-sessions.ps1`, JML-17 |

## RBAC and app access (Phases 2–4)

*Added in Phases 2–4.*

## SSO and federation (Phase 5)

*Added in Phase 5.*

## MFA and Conditional Access (Phase 6)

*Added in Phase 6.*

## Privileged access management (Phase 7)

*Added in Phase 7.*

## Cloud IAM (Phase 8)

*Added in Phase 8.*

## Non-human identity lifecycle and governance (Phase 9)

*Added in Phase 9.*

## Agent-to-tool authorization (Phase 10)

*Added in Phase 10.*

## Entitlement management and access reviews (Phases 11–12)

*Added in Phases 11–12.*

## Audit logging and monitoring (Phase 13)

*Added in Phase 13.*
