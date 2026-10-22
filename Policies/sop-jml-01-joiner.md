# SOP-JML-01: Joiner (New Hire Provisioning)

| Field | Value |
|---|---|
| Document ID | SOP-JML-01 |
| Owner | Identity & Access Management (IAM) |
| Version | 1.0 |
| Effective date | YYYY-MM-DD |
| Review cycle | Annual, or on any change to the role catalog |
| Related | SOP-JML-02 Mover, SOP-JML-03 Leaver, RBAC Access Control Policy (Phase 2) |

## 1. Purpose

Ensures every new workforce member receives exactly one identity, created from an authoritative HR record, with access limited to the role they were hired into.

## 2. Scope

Applies to all workforce member accounts in the `danotech.onmicrosoft.com` tenant. Out of scope: guest (B2B) accounts, service accounts and workload identities, and emergency access accounts.

## 3. Roles and responsibilities

| Role | Responsibility |
|---|---|
| HR | Authoritative source. Submits the approved HR record including role from the approved catalog. |
| Hiring manager | Confirms the role is correct for the position. |
| IAM operator | Runs the joiner process and verifies results. |
| Security lead | Approves any privileged (PIM) eligibility request. |

## 4. Trigger

An approved HR record with a start date, received at least **3 business days** before the start date.

## 5. Requirements

1. **One identity per person.** The HR `EmployeeId` is the immutable anchor; duplicates are not permitted.
2. **Approved roles only.** The role must exist in the role catalog (`config/jml-config.json`). Unknown roles are rejected and returned to HR.
3. **Access through role groups only.** Access is granted by membership of the RBAC role group for the role. Direct assignment of applications or resources to a user is prohibited.
4. **No privileged access at joiner.** Privileged roles receive no access through the joiner process; see 6.5.
5. **Credential hygiene.** Temporary passwords are random, delivered through a secure channel, never logged, and must be changed at first sign-in.
6. **Traceability.** Every action is logged by the script and recorded in the Entra audit log under the operator's identity.

## 6. Procedure

6.1 Receive the HR feed and save it to the controlled location (lab: `data/`).

6.2 Preview the run and review the output for errors:
```powershell
./scripts/joiner.ps1 -CsvPath ./data/<feed>.csv -WhatIf
```

6.3 Resolve any validation errors with HR. Do not edit roles in the feed yourself.

6.4 Execute:
```powershell
./scripts/joiner.ps1 -CsvPath ./data/<feed>.csv
```

6.5 **Privileged roles.** For each `[WARNING] Privileged access` line, raise a PIM eligibility request with business justification. The security lead approves, and the IAM operator creates an **eligible** (never active) assignment as defined in the PIM configuration (Phase 7).

6.6 Deliver temporary passwords through the approved secure channel. Do not send by email or store in tickets.

## 7. Verification

The IAM operator confirms within 1 business day:
- The account exists with correct Department, Job title, Employee ID, and Manager
- The user is a member of exactly one RBAC role group (or none for baseline/privileged roles)
- No Entra directory roles are assigned
- The run log and Entra audit log contain matching entries

## 8. Exceptions

| Situation | Handling |
|---|---|
| Role not in catalog | Reject; HR obtains approval for a new catalog role through the RBAC change process |
| Same-day urgent hire | Run the standard process; record the urgency reason in the ticket |
| Rehire within retention period | Re-enable the existing account through the mover process instead of creating a new one |

## 9. Records

| Record | Location | Retention |
|---|---|---|
| Script run log | `logs/jml-YYYY-MM-DD.csv` | 1 year (lab: local) |
| Entra audit log | Entra ID / Log Analytics (Phase 13) | 30 days native; extended in Log Analytics |

## 10. Control mapping

NIST SP 800-53 Rev. 5: AC-2, AC-2(1), AC-6, IA-5 · ISO/IEC 27001:2022: A.5.16, A.5.17, A.5.18. See [control-traceability-matrix.md](../compliance/control-traceability-matrix.md).
