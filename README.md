# Danotech Inc — Entra ID IAM Lab

> An end-to-end identity program for a fictional 200-person company, built phase by phase in the Microsoft Entra ID lab tenant `danotechinc.onmicrosoft.com`.

## What this lab demonstrates

A mature IAM program **designs** an access model, **implements** it, **validates** that it enforces what it claims, and **monitors** it over time. Every phase in this repo reuses the same three things:

- **One HR feed:** [`data/hr-feed.csv`](data/hr-feed.csv), 200 employees, IDs `DNT10001`–`DNT10200`
- **One role catalog:** [`config/jml-config.json`](config/jml-config.json)
- **One tenant:** `danotechinc.onmicrosoft.com`

## Phases

| Phase | Focus | Builds on | Status |
|---|---|---|---|
| [00](phases/00-tenant-setup/) | Tenant setup, emergency access, hardening, tooling | — | ☐ |
| [01](phases/01-jml-lifecycle/) | Joiner-mover-leaver: PowerShell + Graph creates users, Lifecycle Workflows run the tasks | 00 | ☐ |
| [02](phases/02-rbac-design/) | RBAC design: role catalog, permission matrix, access policy | 01 | ☐ |
| [03](phases/03-groups-and-app-roles/) | Role groups (dynamic + assigned), app roles, OIDC test app | 01, 02 | ☐ |
| [04](phases/04-sso-federation/) | **SSO and federation:** SAML SSO + provisioning to Salesforce; Entra ID ↔ Okta federation | 03 | ☐ |
| [05](phases/05-mfa-conditional-access/) | Authentication methods, Conditional Access, risk policies | 03, 04 | ☐ |
| [05a](phases/05a-global-secure-access/) | *Optional:* Global Secure Access (Private + Internet Access) | 03, 05 | ☐ |
| [06](phases/06-privileged-access/) | Separate admin accounts, PIM just-in-time access | 01, 05 | ☐ |
| [07](phases/07-cloud-iam/) | Least-privilege Azure custom roles and scoping | 03, 06 | ☐ |
| [08](phases/08-non-human-identities/) | Managed identities; GitHub Actions workload identity federation | 01, 06, 07 | ☐ |
| [09](phases/09-agent-authorization/) | AI agent identity calling scoped tool APIs with human approval | 03, 08 | ☐ |
| [10](phases/10-entitlement-management/) | Access packages with approval and expiry | 03, 04 | ☐ |
| [10a](phases/10a-verified-id/) | *Optional:* Verified ID credentials for access requests and helpdesk | 01, 10 | ☐ |
| [11](phases/11-access-reviews/) | Access reviews and audit readiness (people + non-human) | 01–10 | ☐ |
| [12](phases/12-audit-monitoring/) | Sign-in and audit logs, KQL, workbook | 01–11 | ☐ |
| [13](phases/13-capstone/) | Compliance mapping, architecture diagram, lessons learned | All | ☐ |

Phases 05a and 10a are optional and use Entra Suite features. Each phase folder holds its own walkthrough (`README.md`), scripts, and `screenshots/`. A phase is finished before the next one starts.

## Repository structure

```
danotechinc-entra-iam-lab/
├── README.md
├── .gitignore
├── config/
│   └── jml-config.json        # Tenant settings, attribute map, role catalog, policies
├── data/
│   ├── README.md              # Data notice: all people are fictional
│   └── hr-feed.csv            # 200-person HR feed (source of truth)
├── docs/
│   ├── hr-feed-mapping.md     # HR columns -> Entra ID properties, planted findings
│   └── naming-conventions.md  # Prefixes for every object type
├── phases/
│   ├── 00-tenant-setup/
│   │   ├── README.md          # Walkthrough
│   │   ├── Test-LabPrerequisites.ps1
│   │   └── screenshots/
│   └── 01-jml-lifecycle/ … 13-capstone/
└── logs/                      # Git-ignored run records
```

## Company at a glance

| Department | People | Offices |
|---|---|---|
| Sales | 47 | Austin, Atlanta, Seattle, London |
| HR | 39 | Austin, Atlanta, London |
| IT | 39 | Austin, Atlanta, Seattle, London |
| Finance | 37 | Austin, Atlanta, London |
| Engineering | 31 | Seattle, Austin, London |
| Executive | 7 | Austin |

## Licensing and accounts

- **Microsoft Entra ID P2:** Conditional Access, ID Protection risk policies, PIM. It also satisfies the P1 prerequisite for Entra Suite.
- **Microsoft Entra Suite:** includes every Microsoft Entra ID Governance feature: Lifecycle Workflows, advanced access reviews, and entitlement management. Lifecycle Workflows drive the joiner, mover, and leaver tasks in Phase 01.
- If either license is a trial, record its expiry in Phase 00 and plan phases 01–11 inside that window.
- **Outside accounts (free tiers), all created in Phase 00:**

| Account | Used in | Purpose |
|---|---|---|
| Salesforce Developer Edition | 04, 05, 10, 11 | SAML SSO target app, SCIM provisioning, app access reviews |
| Okta Integrator Free Plan | 04, 05, 11 | Federation with Entra ID as the identity provider |
| Azure subscription | 05a, 07, 08, 12 | Custom roles, managed identities, Log Analytics |
| GitHub | 08 | Repo + Actions workload identity federation |

## Safety notes

- Lab tenant only. Every person in `data/` is fictional.
- Temporary passwords are shown once at run time and **never written to disk or logs**.
- Never commit secrets, certificates, subscription IDs, or `logs/`.
- Emergency access account credentials live offline, never in this repo.
