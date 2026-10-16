# Entra ID Identity Lifecycle & RBAC Lab

> Joiner-Mover-Leaver (JML) automation, role-based access control (RBAC), privileged access management, and audit monitoring in Microsoft Entra ID, built and validated in the lab tenant `danotech.onmicrosoft.com`.

## What this lab demonstrates

A mature IAM program does four things: it **designs** an access model, **implements** it, **validates** that it enforces what it claims, and **monitors** it over time. This repo builds one fictional company's identity program end to end, in phases that each stand alone but plug into the same tenant, the same ten employees, and the same role catalog.

| Stage | What it proves | Phases |
|---|---|---|
| Lifecycle | Identities are created, changed, and removed from an authoritative HR feed | 1 |
| Access design | Every job function maps to the minimum access it needs | 2–4 |
| Authentication | Users sign in once (SSO) with strong, risk-aware MFA | 5–6 |
| Privileged and cloud access | Admins have no standing privilege; cloud access is scoped precisely | 7–8 |
| Governance | Access is requested, approved, expires, and is re-certified with audit-ready evidence | 9–10 |
| Monitoring | Logs prove who used which access, when, and who granted it | 11 |

## Build phases

| Phase | Focus | Builds on | Feeds into | Status |
|---|---|---|---|---|
| 0 | Prerequisites and tenant setup | — | Everything | ☐ |
| 1 | JML lifecycle automation | 0 | Who holds each role (all later phases) | ☐ |
| 2 | RBAC design: role definitions, permission matrix, access control policy | 1 | The model every later phase enforces | ☐ |
| 3 | Role groups (assigned + dynamic baseline) | 1, 2 | App assignment, SSO, CA targeting, reviews | ☐ |
| 4 | App roles and an OIDC test app | 3 | Proves role claims; OIDC half of SSO | ☐ |
| 5 | **SSO and federation:** SAML to Salesforce, Entra ID ↔ Okta federation | 3, 4 | Apps that MFA and access reviews protect | ☐ |
| 6 | **MFA and Conditional Access:** authentication methods, risk-based policies | 3, 5 | MFA requirement for privileged access | ☐ |
| 7 | **Privileged access management:** separate admin accounts, PIM just-in-time, credential vault | 1, 6 | Privileged access in reviews and monitoring | ☐ |
| 8 | **Cloud IAM policy design:** least-privilege Azure custom roles, scoping, validation | 3, 7 | Cloud access in reviews | ☐ |
| 9 | Entitlement management: access packages with approval and expiry | 3, 5 | Time-bound access for reviews | ☐ |
| 10 | **Access reviews and audit readiness:** boundary tests, excessive/dormant access, remediation, review report | 1–9 | Audit evidence package | ☐ |
| 11 | Audit logging and monitoring: log export, KQL, workbook | 1–10 | Ongoing assurance | ☐ |
| 12 | Capstone: compliance mapping, architecture diagram, lessons learned | All | — | ☐ |

## Repository structure

```
entra-id-lab/
├── README.md
├── .gitignore
├── config/
│   └── jml-config.json            # Tenant settings and the approved role catalog
├── data/                          # Fictional HR feed (+ invalid feed for negative tests)
├── docs/
│   ├── 00-prerequisites.md
│   └── screenshot-checklist.md    # Every screenshot, where it goes, what it must show
├── scripts/                       # Phase 1: JML scripts, each with a companion .md
├── policies/                      # SOPs and policies from every phase
├── compliance/
│   └── control-traceability-matrix.md
├── test-cases/                    # JML test matrix
├── rbac/                          # Phases 2–4, 9
├── sso-federation/                # Phase 5: Salesforce SAML, Okta federation
├── mfa-conditional-access/        # Phase 6
├── privileged-access/             # Phase 7: admin accounts, PIM, vault
├── cloud-iam/                     # Phase 8: Azure custom roles
├── access-reviews/                # Phase 10: review exports, findings, report
├── audit-logging/                 # Phase 11: KQL, workbook, reports
├── screenshots/                   # One subfolder per phase
└── diagrams/                      # Phase 12
```

## Quick start

1. Complete [docs/00-prerequisites.md](docs/00-prerequisites.md).
2. Update `config/jml-config.json` with your tenant domain and license SKU.
3. Preview the joiner run without making changes:
   ```powershell
   cd scripts
   ./joiner.ps1 -CsvPath ../data/sample-hr-feed.csv -WhatIf
   ```
4. Run it for real, then work through [test-cases/test-matrix.md](test-cases/test-matrix.md).

## Licensing

This lab uses Microsoft Entra ID P2 (or Entra ID Governance) features: group-based app assignment, Conditional Access, ID Protection risk policies, PIM, access reviews, and entitlement management. A free trial in a dedicated lab tenant is enough. Phases 5, 7, and 8 also use free Salesforce Developer Edition, Okta developer, and Azure accounts.

## Safety notes

- Lab tenant only. Every person in `data/` is fictional.
- Temporary passwords are printed once to the console and **never written to disk or logs**. Never commit credentials, tenant IDs you consider sensitive, or subscription IDs.
- The `logs/` folder is git-ignored because it contains run records with user identifiers.
