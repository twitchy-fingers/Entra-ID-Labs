# Entra ID JML Lab
### Cloud-Native Joiner-Mover-Leaver Automation Using Microsoft Graph PowerShell

---

## Overview

This project simulates the full **identity lifecycle** — onboarding, role transfers, and offboarding — entirely within Microsoft Entra ID, using Microsoft Graph PowerShell for automation. Unlike a hybrid on-prem/cloud setup, this lab is cloud-native by design: it reflects how IAM is increasingly implemented in SaaS-first organizations that have no on-prem Active Directory at all.

**Why this project exists:** Joiner-Mover-Leaver (JML) failures are the most common source of access-related risk in real organizations — access granted too broadly on hire, access left behind after a role change ("privilege creep"), and access that outlives an employee's departure. This lab builds and validates controls against each of those failure points using Entra ID's native tooling.

---

## Architecture

**Environment:** Microsoft Entra ID (Microsoft 365 Developer tenant, E5/P2 licensing)

**Components:**
- Assigned security groups for scripted, role-based access control
- Dynamic security groups for attribute-driven, self-maintaining access
- Microsoft Graph PowerShell for all provisioning, transfer, and deprovisioning automation
- Entra ID Audit Logs and Sign-in Logs for validation and evidence
- License assignment tied to provisioning, reflecting real onboarding requirements

---

## Core Workflows

### 1. Joiner (Onboarding)
Users are provisioned from a simulated HRIS feed (CSV) using `New-MgUser`, with department, job title, and usage location set at creation. Each user is immediately added to the corresponding role-based assigned group, and licensed automatically.

`/scripts/joiner.ps1`

### 2. Mover (Role/Department Change)
The script removes the user's old role-group membership before adding the new one, and updates the `Department` attribute on the user object. This attribute update is also what drives automatic re-evaluation of any dynamic groups the user qualifies for — no separate script logic needed for those.

`/scripts/mover.ps1`

### 3. Leaver (Offboarding)
Disables future sign-in (`AccountEnabled:$false`), strips all group memberships, removes licenses, and — critically — calls `Revoke-MgUserSignInSession` to invalidate any already-active sessions and tokens. This closes the common offboarding gap where a disabled account's existing session remains valid until natural token expiry.

`/scripts/leaver.ps1`

---

## Repository Structure
entra-id-jml-lab/
├── README.md
├── /scripts
│ ├── joiner.ps1
│ ├── mover.ps1
│ └── leaver.ps1
├── /data
│ └── sample-hr-feed.csv
├── /policies
│ ├── access-control-policy.md
│ ├── joiner-sop.md
│ ├── mover-sop.md
│ └── leaver-sop.md
├── /test-cases
│ └── test-matrix.md
├── /logs
│ └── audit-export-sample.csv
└── /screenshots
├── entra-groups-list.png
├── dynamic-group-rule.png
├── user-groups-before-after.png
├── failed-signin-post-disable.png
└── audit-log-filtered.png

---

## Access Control Model

Access is assigned through role-based security groups rather than directly to individual users, using two complementary group types:

- **Assigned groups** (`SG-<Dept>-Users`) — static membership, managed entirely by the joiner/mover/leaver scripts. Used as the primary model in this lab because it mirrors how most organizations still manage access today.
- **Dynamic groups** (`SG-<Dept>-Dynamic`) — rule-based membership (e.g., `user.department -eq "Finance"`) that updates automatically whenever the underlying attribute changes. Built alongside the assigned model specifically to demonstrate the more scalable pattern and to structurally solve the mover/privilege-creep problem without relying on a script running correctly every time.

Privileged access (`SG-IT-Admins`) is kept as a separate, deliberately small group rather than folded into the general IT role group — consistent with least-privilege design.

---

## Testing

A 12-case test matrix validates provisioning, transfer, deprovisioning, and audit trail integrity — including the disable-vs-session-revocation distinction and dynamic group auto-update behavior.

Full matrix: `/test-cases/test-matrix.md`

| Sample Test | Result |
|---|---|
| Sign-in attempt with disabled leaver credentials | Fails with "account disabled" |
| Active session before `Revoke-MgUserSignInSession` | Confirmed still valid |
| Active session after `Revoke-MgUserSignInSession` | Confirmed terminated |
| User's department attribute updated | Dynamic group membership updates automatically, no script step required |

---

## Audit and Evidence

Every workflow is validated against Entra ID's native logging rather than assumed to work:

- **Audit Logs** — captures "Add user," "Update user," "Add member to group," "Remove member from group," confirming each scripted action actually executed as intended, including who/what initiated it.
- **Sign-in Logs** — confirms real-world authentication behavior, including failed sign-in attempts post-deprovisioning with the specific failure reason.

A sample exported audit log (sanitized) is included at `/logs/audit-export-sample.csv` as a portable evidence artifact.

---

## What This Project Demonstrates

- Cloud-native user provisioning and deprovisioning using Microsoft Graph PowerShell
- Role-based access control using both assigned and dynamic Entra ID groups
- Understanding of the distinction between account disablement and active session/token revocation — a control gap frequently missed in real offboarding processes
- Audit-log-driven validation, rather than assuming automation succeeded without verifying it
- Practical understanding of Entra ID licensing tiers and which IAM capabilities (dynamic groups, Access Reviews, PIM) require P1/P2 vs. what's available on Free

---

## Future Enhancements

- Replace the manual CSV import with an inbound SCIM provisioning connector from a real HRIS (e.g., Workday, BambooHR) for event-driven joiner/mover/leaver triggers
- Add Entra ID Entitlement Management (Access Packages) for self-service, approval-based access requests as an alternative to admin-scripted provisioning
- Extend leaver validation to include Microsoft 365 mailbox conversion/retention steps
- Add Conditional Access and PIM layers (P2) for a fuller least-privilege and just-in-time access story
