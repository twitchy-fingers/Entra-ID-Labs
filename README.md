# Entra ID Lab

> Joiner-Mover-Leaver (JML) automation, role-based access control (RBAC), privileged access management, and audit monitoring in Microsoft Entra ID, built and validated in the lab tenant `danotech.onmicrosoft.com`.

## What this lab demonstrates

A mature IAM program does four things: it **designs** an access model, **implements** it, **validates** that it enforces what it claims, and **monitors** it over time. This repo builds one fictional company's identity program end to end, in phases that each stand alone but plug into the same tenant, the same 209 employees, and the same role catalog.

| Stage | What it proves | Phases |
|---|---|---|
| Lifecycle | Identities are created, changed, and removed from an authoritative HR feed | 1 |
| Access design | Every job function maps to the minimum access it needs | 2–4 |
| Authentication | Users sign in once (SSO) with strong, risk-aware MFA | 5–6 |
| Privileged and cloud access | Admins have no standing privilege; cloud access is scoped precisely | 7–8 |
| Non-human identities and AI agents | Service principals, managed identities, and agents have owners, scoped permissions, short-lived credentials, and authorized tool access | 9–10 |
| Governance | Access is requested, approved, expires, and is re-certified with audit-ready evidence | 11–12 |
| Monitoring | Logs prove who (or what) used which access, when, and who granted it | 13 |

## Build phases

| Phase | Focus | Builds on | Feeds into | Status |
|---|---|---|---|---|
| 0 | Prerequisites and tenant setup | — | Everything | ☐ |
| 1 | JML lifecycle automation | 0 | Who holds each role (all later phases) | ☐ |
| 2 | RBAC design: role definitions, permission matrix, access control policy | 1 | The model every later phase enforces | ☐ |
| 3 | Role groups (assigned + dynamic baseline) | 1, 2 | App assignment, SSO, CA targeting, reviews | ☐ |
| 4 | App roles and an OIDC test app | 3 | Proves role claims; OIDC half of SSO; the API agents call in Phase 10 | ☐ |
| 5 | **SSO and federation:** SAML to Salesforce, Entra ID ↔ Okta federation | 3, 4 | Apps that MFA and access reviews protect | ☐ |
| 6 | **MFA and Conditional Access:** authentication methods, risk-based policies | 3, 5 | MFA requirement for privileged access | ☐ |
| 7 | **Privileged access management:** separate admin accounts, PIM just-in-time, credential vault | 1, 6 | Privileged access in reviews and monitoring | ☐ |
| 8 | **Cloud IAM policy design:** least-privilege Azure custom roles, scoping, validation | 3, 7 | Roles assigned to workload identities in Phase 9 | ☐ |
| 9 | **Non-human identity lifecycle and governance:** inventory, ownership, managed identities, workload identity federation, credential hygiene, NHI joiner-mover-leaver | 1, 7, 8 | The JML automation itself runs as a workload identity; agent identities in Phase 10 | ☐ |
| 10 | **Agent-to-tool authorization:** an AI agent identity calling protected tool APIs with scoped, delegated or app-only permissions and human approval for high-risk actions | 4, 9 | Agent access in reviews and monitoring | ☐ |
| 11 | Entitlement management: access packages with approval and expiry | 3, 5 | Time-bound access for reviews | ☐ |
| 12 | **Access reviews and audit readiness:** boundary tests, excessive/dormant access for people *and* non-human identities, remediation, review report | 1–11 | Audit evidence package | ☐ |
| 13 | Audit logging and monitoring: sign-in logs (user and service principal), audit logs, KQL, workbook | 1–12 | Ongoing assurance | ☐ |
| 14 | Capstone: compliance mapping, architecture diagram, lessons learned | All | — | ☐ |

## Repository structure

```
entra-id-jml-lab/
├── README.md
├── .gitignore
├── config/
│   └── jml-config.json            # Tenant settings and the approved role catalog
├── data/
│   ├── sample-hr-feed.csv         # 209-person HR feed built from the Danotech tenant export
│   ├── pilot-hr-feed.csv          # 14 test personas and their managers
│   ├── sample-hr-feed-invalid.csv # Negative test: role not in catalog
│   └── expected-upns.csv          # Expected UPN per employee, for verification
├── docs/
│   ├── 00-prerequisites.md
│   ├── hr-feed-mapping.md         # How the export became the feed: roles, managers, UPNs, findings
│   └── screenshot-checklist.md    # Every screenshot, where it goes, what it must show
├── scripts/                       # Phase 1: JML scripts, each with a companion .md
├── policies/                      # SOPs and policies from every phase
├── compliance/
│   └── control-traceability-matrix.md
├── test-cases/                    # JML test matrix
├── rbac/                          # Phases 2–4, 11
├── sso-federation/                # Phase 5: Salesforce SAML, Okta federation
├── mfa-conditional-access/        # Phase 6
├── privileged-access/             # Phase 7: admin accounts, PIM, vault
├── cloud-iam/                     # Phase 8: Azure custom roles
├── non-human-identities/          # Phase 9: NHI inventory, ownership, credential hygiene
├── agent-authorization/           # Phase 10: agent identity, tool API, authorization tests
├── access-reviews/                # Phase 12: review exports, findings, report
├── audit-logging/                 # Phase 13: KQL, workbook, reports
├── screenshots/                   # One subfolder per phase
└── diagrams/                      # Phase 14
```

## Quick start

1. Complete [docs/00-prerequisites.md](docs/00-prerequisites.md).
2. Update `config/jml-config.json` with your tenant domain and license SKU.
3. If the tenant already has users, reset it (prerequisites §8).
4. Preview the 14-person pilot without making changes:
   ```powershell
   cd scripts
   ./joiner.ps1 -CsvPath ../data/pilot-hr-feed.csv -WhatIf
   ```
5. Run the pilot, verify it, then run the full 209-person feed (`../data/sample-hr-feed.csv`) and work through [test-cases/test-matrix.md](test-cases/test-matrix.md).

## Licensing

This lab uses Microsoft Entra ID P2 (or Entra ID Governance) features: group-based app assignment, Conditional Access, ID Protection risk policies, PIM, access reviews, and entitlement management. A free trial in a dedicated lab tenant is enough. Phases 5, 7, 8, 9, and 10 also use free Salesforce Developer Edition, Okta developer, GitHub, and Azure accounts. Conditional Access for workload identities (optional in Phase 9) needs the separate Workload Identities Premium license.

## Safety notes

- Lab tenant only. The people in `data/` are fictional lab users from the Danotech tenant.
- Temporary passwords are printed once to the console and **never written to disk or logs**. Never commit credentials, tenant IDs you consider sensitive, or subscription IDs.
- The `logs/` folder is git-ignored because it contains run records with user identifiers.
