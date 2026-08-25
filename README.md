# Entra-ID-Labs

A hands-on lab series covering identity and access management scenarios in Microsoft Entra ID (Azure AD), built against the **danotech.onmicrosoft.com** tenant.

This `main` branch is the landing page for the project. Each individual lab lives in its own branch, with a full step-by-step guide, scripts/screenshots (where applicable), and cleanup instructions. Use the table below to jump to a lab.

## Tenant / Environment

| Item | Value |
|---|---|
| Tenant name | danotech.onmicrosoft.com |
| Tenant type | Microsoft Entra ID (Azure AD) |
| Licensing assumed | Entra ID P1/P2 (noted per-lab if a feature requires P2, e.g. Access Reviews, PIM) |
| Admin role used | Global Administrator (lab/sandbox only — not representative of least-privilege practice) |

> ⚠️ **Lab disclaimer**: This tenant is a personal/sandbox environment used for learning and demonstration purposes only. Configurations here are not hardened for production use. Do not replicate role assignments or trust settings as-is in a production tenant without a security review.

## How this repo is organized

- **`main`** — this README. Index of all labs, prerequisites, and general tenant notes.
- **`lab/jml`** — Joiner-Mover-Leaver (JML) lifecycle lab.
- **`lab/rbac`** — Role-Based Access Control (RBAC) lab.
- Future labs will be added below as new branches, following the naming convention `lab/<short-name>`.

Each lab branch contains its own `README.md` with:
1. Objective and scenario
2. Prerequisites (roles, licensing, pre-created objects)
3. Step-by-step configuration walkthrough
4. Validation / testing steps
5. Cleanup / teardown steps
6. Lessons learned / notes

## Lab Index

| # | Lab | Branch | Status | Summary |
|---|---|---|---|---|
| 1 | Joiner-Mover-Leaver (JML) | [`lab/jml`](../../tree/lab/jml) | ✅ Complete | Simulates the employee lifecycle in Entra ID — provisioning a new hire (Joiner), handling an internal transfer with group/role changes (Mover), and deprovisioning on exit (Leaver). Covers dynamic groups, group-based licensing, access assignment, and offboarding (account disable, license removal, access revocation). |
| 2 | Role-Based Access Control (RBAC) | [`lab/rbac`](../../tree/lab/rbac) | ⏳ In Progress | Builds out a least-privilege access model using Entra ID built-in roles, custom roles, and administrative units. Covers role assignment scope (tenant vs. AU-scoped), Privileged Identity Management (PIM) for just-in-time elevation, and validating effective permissions. |
| 3 | Single Sign-On (SSO) | [`lab/sso`](../../tree/lab/sso) | ⏳ In Progress |  |

## Lab Summaries

### 1. Joiner-Mover-Leaver (JML) Lab — `lab/jml`

**Goal:** Model the end-to-end identity lifecycle for an employee in Entra ID.

- **Joiner:** Create a new user account, assign to department/role-based dynamic security groups, auto-assign licenses via group-based licensing, and grant baseline app access.
- **Mover:** Simulate an internal role change — update user attributes (department, job title, manager) and observe dynamic group membership update automatically; adjust access accordingly.
- **Leaver:** Disable the account, remove group memberships/licenses, revoke active sessions, and (optionally) convert to a soft-delete/offboarding state before final deletion.

**Key concepts covered:** dynamic membership rules, group-based licensing, attribute-driven access, session revocation, offboarding hygiene.

➡️ Full guide: see the `README.md` on the [`lab/jml`](../../tree/lab/jml) branch.

### 2. RBAC Lab — `lab/rbac`

**Goal:** Design and implement a least-privilege administrative access model in Entra ID.

- Review Entra ID built-in directory roles vs. Azure RBAC roles (and how they differ in scope).
- Create/assign built-in roles (e.g., User Administrator, Helpdesk Administrator) scoped to Administrative Units rather than the whole tenant.
- Build a custom role with a narrowly-scoped permission set.
- Configure Privileged Identity Management (PIM) for just-in-time, time-bound, approval-gated role activation.
- Validate effective access using the "Check access" / sign-in logs and audit logs.

**Key concepts covered:** built-in vs. custom roles, Administrative Units, least privilege, PIM eligible vs. active assignments, access validation.

➡️ Full guide: see the `README.md` on the [`lab/rbac`](../../tree/lab/rbac) branch.

### 3. SSO Lab — `lab/sso`

**Goal:** 

## Prerequisites (general, applies across labs)

- Access to the `danotech.onmicrosoft.com` tenant with Global Administrator (or the specific role called out in each lab).
- Entra ID P1 at minimum; P2 required for PIM and Access Reviews (called out per-lab).
- A small set of test/dummy user accounts (naming convention: `lab-<firstname>.<lastname>@danotech.onmicrosoft.com`) — created fresh per lab or reused where noted.
- Basic familiarity with the Entra admin center (entra.microsoft.com) and PowerShell (Microsoft Graph SDK) for scripted steps.

## Roadmap

- [ ] Conditional Access lab
- [ ] Privileged Identity Management (PIM) deep-dive
- [ ] Access Reviews lab
- [ ] Hybrid Identity / Entra Connect sync lab
- [ ] App Registrations & Enterprise Applications (SSO/SCIM) lab

## Notes

This repo is a personal learning project tracking hands-on Entra ID practice. Feedback, corrections, and suggestions for additional lab scenarios are welcome via issues/PRs.
