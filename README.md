# RBAC Design and Implementation — Entra ID
### A continuation of the Entra ID Lab — Role-Based Access Control, Least Privilege, and Access Monitoring

---

## Overview

This branch extends the Entra ID Lab (`main` branch) with a full role-based access control (RBAC) model. Where the JML lab manages the *lifecycle* of an identity — creation, role changes, offboarding, this project defines *what that identity is allowed to do* once it exists, and proves those boundaries actually hold.

The lab simulates a mid-size organization across 5 departments, mapping 8 job functions to precise application and cloud resource permissions in Microsoft Entra ID (`danotech.onmicrosoft.com`). It covers the full RBAC lifecycle: designing roles, implementing them through groups and app roles, enforcing privileged access boundaries with PIM, validating access boundaries with negative test cases, detecting excessive access, and proving all of it with log-based evidence.

**Why this project exists:** a role-based access model is only as good as its ability to answer three questions with evidence, not assumption — *who can access what, who granted that access, and can we prove the boundary actually holds when tested.* This lab is built to answer all three.

---

## How This Branch Relates to `JML`

This is a **separate branch of the same repository**, not a subdirectory, it builds on the identity foundation established in `JML Lab` (JML lab: provisioning, mover, leaver automation, and the shared NIST/ISO compliance mapping) but is developed independently so the two bodies of work don't collide structurally.

The `main` branch scripts are the *consumers* of the design work here — when `joiner.ps1` (in `JML`) adds a new hire to a role group, it's plugging into the access model this branch defines. To view both together, either check out `JML` for the JML lifecycle work or diff/merge as needed; this branch intentionally maintains its own copy of `/compliance` (see note below) so it can be reviewed standalone.

> **Note on `/compliance`:** since this branch may be reviewed independently of `JML` (e.g., linked directly in a portfolio), it carries its own `/compliance` directory with the RBAC-specific control mappings, rather than assuming the reader has `main` checked out simultaneously. If merged into `JML` in the future, these should be consolidated into a single control traceability matrix.

---

## Architecture

**Roles are never assigned directly to resources.** Every role flows through a dedicated security group, which is then assigned to an application's app role, an Entra ID administrative role (via PIM), or an Azure custom role. This mirrors the AGDLP pattern used on the on-prem AD side of the JML lab, translated to a cloud-only model.

![RBAC Role-Permission Map](diagrams/rbac-role-permission-map.png)

**Flow:** User Account → Role Group (`RBAC-*`) → App Role / PIM-Eligible Role / Azure Custom Role → Actual Permission

---

## Roles Defined

| Role Name | Department | Access Level | Applications/Resources |
|---|---|---|---|
| Sales Rep | Sales | Standard | CRM (own records only) |
| Sales Manager | Sales | Elevated | CRM (all team records) |
| Finance Analyst | Finance | Standard | Finance app (read/write, no approval) |
| Finance Approver | Finance | Elevated | Finance app (approval workflow) |
| HR Generalist | HR | Standard | HRIS (employee records) |
| IT Support | IT | Elevated | Helpdesk app |
| IT Admin | IT | Privileged | Entra ID admin roles (PIM-eligible only) |
| Standard Employee | All | Baseline | Email, Teams, dept. SharePoint site |

Full definitions and design rationale: [`roles/role-definitions.md`](roles/role-definitions.md)
Full permission-to-role mapping: [`roles/permission-matrix.md`](roles/permission-matrix.md)

---

## Implementation Mechanisms

This project deliberately uses multiple RBAC mechanisms, since real environments rarely rely on just one:

| Mechanism | Purpose | Scripts/Config |
|---|---|---|
| Security Groups | Role-layer grouping | `scripts/create-role-groups.ps1` |
| App Roles | In-app permission tiers (e.g., `.ReadWrite.Own` vs `.ReadWrite.All`) | `scripts/create-app-roles.md` |
| PIM (Privileged Identity Management) | Just-in-time activation for admin roles — zero standing access | Portal-configured |
| Azure Custom Roles | Granular Azure resource permissions beyond built-in roles | `scripts/create-custom-azure-role.json` |
| Entitlement Management | Bundled access requests with approval workflow | `/entitlement-management` |

---

## Least Privilege and Separation of Duties

Two design decisions are worth calling out explicitly, since they're the pieces most commonly missing from simpler RBAC implementations:

- **Separation of duties:** Finance Analyst (`Finance.ReadWrite`) and Finance Approver (`Finance.Approve`) are deliberately separate roles — no single account can both enter and approve a transaction.
- **No standing privileged access:** `IT Admin` has zero permanent administrative rights. All administrative role access is PIM-eligible only, requiring activation, approval, justification, and MFA, with a bounded activation window.

A custom Azure role (`scripts/create-custom-azure-role.json`) further demonstrates granular scoping by explicitly excluding key-listing rights (`NotActions`) that a built-in "Reader" role would otherwise implicitly allow.

---

## Testing

An 11-case test matrix validates both positive access (authorized roles work as intended) and negative access (unauthorized attempts are blocked) — full results in [`test-cases/rbac-test-matrix.md`](test-cases/rbac-test-matrix.md).

| Sample Test | Result |
|---|---|
| Sales Rep attempts to view another rep's records | Denied |
| Finance Analyst attempts to approve a transaction | Denied (no approval role) |
| IT Admin acts after PIM activation window expires | Denied |
| User removed from role group | Loses app access on next token refresh |
| Custom Azure role holder attempts to list storage keys | Denied (explicit NotActions exclusion) |

---

## Excessive Access Detection

Beyond testing that boundaries hold, this project actively looks for accounts that shouldn't have the access they currently do:

- **Access Reviews** on elevated role groups (e.g., `RBAC-SalesManager`), with Entra ID's built-in inactivity recommendations surfaced to the reviewer
- **`scripts/audit-excessive-access.ps1`** — flags any account belonging to more than one role group simultaneously, since roles in this design are intended to be mutually exclusive

---

## Audit Logging and Monitoring

RBAC configuration alone doesn't prove the model works — this project backs every claim with log evidence, covered in depth in [`audit-logging/log-sources-overview.md`](audit-logging/log-sources-overview.md).

- **Sign-in logs** confirm the correct app role claim is actually issued in the token at authentication (not just assigned in the portal), and that unauthorized attempts fail with error 50105
- **Audit logs** provide an attributable change history for every group membership and app role assignment change
- **Log Analytics + KQL** enable proactive queries: dormant elevated accounts, repeated failed access patterns, and privileged role activation history
- **`audit-logging/scripts/detect-role-anomalies.ps1`** cross-references role membership against 30-day sign-in activity to surface stale privileged access
- A consolidated **Azure Monitor Workbook** brings all of the above into a single dashboard view

---

## Repository Structure (This Branch)
rbac-lab/ (branch root)
├── README.md
├── /roles
│ ├── role-definitions.md
│ └── permission-matrix.md
├── /scripts
│ ├── create-role-groups.ps1
│ ├── create-app-roles.md
│ ├── assign-users-to-roles.ps1
│ ├── create-custom-azure-role.json
│ └── audit-excessive-access.ps1
├── /entitlement-management
│ ├── access-package-config.md
│ └── access-package-policy.md
├── /test-cases
│ └── rbac-test-matrix.md
├── /audit-logging
│ ├── log-sources-overview.md
│ ├── /scripts
│ │ ├── export-signin-logs.ps1
│ │ ├── export-audit-logs.ps1
│ │ ├── detect-role-anomalies.ps1
│ │ └── generate-access-report.ps1
│ ├── /kql-queries
│ │ ├── role-assignment-changes.kql
│ │ ├── failed-app-access-by-role.kql
│ │ ├── privileged-role-activations.kql
│ │ └── dormant-role-accounts.kql
│ ├── /workbooks
│ │ └── rbac-monitoring-workbook.json
│ └── /screenshots
├── /compliance
│ └── control-traceability-matrix.md
├── /diagrams
│ └── rbac-role-permission-map.png
└── /screenshots

---

## Compliance Mapping

Every control in this project maps to NIST 800-53 Rev 5 and ISO 27001:2022 Annex A. This branch maintains its own `/compliance/control-traceability-matrix.md` (see note above on why it's not shared with `main`).

| Control Area | NIST 800-53 | ISO 27001 | Implementation |
|---|---|---|---|
| Role-based access | AC-2(7) | A.5.15, A.5.18 | RBAC-* groups + app roles |
| Separation of duties | AC-5 | A.5.3 | Finance Analyst/Approver split |
| Least privilege | AC-6 | A.5.18 | Custom Azure role with NotActions |
| Access recertification | AC-6(7), CA-7 | A.5.36 | Access Reviews |
| Excessive permission detection | AC-6(7) | A.8.2 | audit-excessive-access.ps1 |
| Audit logging | AU-2 | A.8.15 | Sign-in / Audit logs |
| Audit review and reporting | AU-6 | A.8.16 | KQL queries, monitoring workbook |
| Continuous monitoring | CA-7 | A.5.36 | Scheduled access reports |
| Anomaly detection | SI-4 | A.8.16 | detect-role-anomalies.ps1 |

---

## What This Project Demonstrates

- Design of a scalable RBAC model mapping job functions to precise, minimum-necessary permissions
- Implementation across multiple Entra ID mechanisms — groups, app roles, PIM, custom Azure roles, entitlement management
- Enforcement of separation of duties and elimination of standing privileged access
- Boundary validation through both positive and negative test cases
- Proactive detection of privilege creep and excessive access via scripted audits and Access Reviews
- Log-based proof — not just configuration screenshots — that role boundaries hold under real authentication conditions

---

## Known Gaps / Future Work

- Access Reviews are currently configured on a subset of role groups (elevated roles only); extending recurring reviews to all role groups would provide fuller coverage per AC-6(7).
- Log retention on the free Entra ID tier is limited to 7 days; the Log Analytics forwarding addresses this for the lab, but a production deployment would need a defined retention policy aligned to regulatory scope (commonly 90 days–1 year).
- The anomaly detection script currently checks for multi-group membership and dormancy independently; a future iteration could combine both signals into a single weighted risk score.
- Entitlement Management access packages are configured for one role bundle (Sales Manager) as a proof of concept; extending this pattern to all elevated roles would reduce manual multi-resource assignment further.
- This branch's `/compliance` directory duplicates some control families already tracked in `main`; if/when merged, these should be consolidated into a single repo-wide control traceability matrix rather than maintained separately.

---

## Related Work

- **`JML` branch** — Entra ID JML Lab: provisioning, mover, and leaver automation for the identities this RBAC model governs
