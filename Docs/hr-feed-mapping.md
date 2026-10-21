# HR Feed Mapping — From Tenant Export to Authoritative Feed

This document records how the Danotech user export (`users_10_20_2026_11_09_54_PM.csv`, 211 rows) was converted into the HR feed the lab provisions from (`data/sample-hr-feed.csv`, 209 rows). It is also the main input to the RBAC design in Phase 2.

The lab treats the directory as **empty before Phase 1** (see `docs/00-prerequisites.md` §8). Every workforce user is recreated by the joiner from this feed, so the directory is built from HR data rather than from whatever was created by hand.

## 1. Source and exclusions

| Item | Value |
|---|---|
| Source rows | 211 |
| Excluded | 2 — `dopara@DanoTech.onmicrosoft.com` (lab administrator) and `breakglass@DanoTech.onmicrosoft.com` (emergency access). These are not employees in the HR system and must never be provisioned or deprovisioned by JML automation. |
| Workforce rows in feed | 209 |
| Departments | Sales 52 · HR 44 · IT 42 · Finance 40 · Engineering 31 |

## 2. Fields

| Feed column | Source | Notes |
|---|---|---|
| EmployeeId | Generated | `E1001`–`E1209`, assigned alphabetically by last name, then first name. The export has no employee ID, which is itself a finding: nothing anchored these accounts to an HR record. |
| FirstName / LastName | First name / Last name | Trimmed |
| Department | Department | Unchanged |
| JobTitle | Title | Unchanged |
| Role | Derived from Title | See section 3 |
| ManagerEmployeeId | Derived | See section 4 |
| StartDate | When created (date part) | Stands in for hire date |
| UsageLocation | Usage location | All `US` |

## 3. Job title → role catalog mapping

Twenty-six job titles collapse into nine roles from `config/jml-config.json`. The catalog grew from eight to ten roles to cover Engineering:

- **Engineer** — software delivery roles that need application access but no cloud infrastructure rights.
- **CloudEngineer** — DevOps, architecture, and network roles. These become the scoped Azure custom role holders in Phase 8 and the owners of workload identities in Phase 9.

| Department | Job title | Role | Count |
|---|---|---|---|
| Sales | Regional Sales Lead | `SalesManager` | 5 |
| Sales | Sales Manager | `SalesManager` | 10 |
| Sales | Account Executive | `SalesRep` | 7 |
| Sales | Business Development Rep | `SalesRep` | 15 |
| Sales | Sales Representative | `SalesRep` | 15 |
| Finance | Accountant | `FinanceAnalyst` | 12 |
| Finance | Accounts Payable Specialist | `FinanceAnalyst` | 3 |
| Finance | Financial Analyst | `FinanceAnalyst` | 5 |
| Finance | Payroll Coordinator | `FinanceAnalyst` | 7 |
| Finance | Finance Manager | `FinanceApprover` | 12 |
| Finance | Financial Administrator | `FinanceApprover` | 1 |
| HR | Benefits Administrator | `HRGeneralist` | 8 |
| HR | HR Coordinator | `HRGeneralist` | 12 |
| HR | HR Generalist | `HRGeneralist` | 8 |
| HR | HR Manager | `HRGeneralist` | 7 |
| HR | Recruiter | `HRGeneralist` | 9 |
| IT | Network Engineer | `CloudEngineer` | 8 |
| IT | IT Administrator | `ITAdmin` | 14 |
| IT | Systems Administrator | `ITAdmin` | 7 |
| IT | Help Desk Technician | `ITSupport` | 8 |
| IT | IT Support Specialist | `ITSupport` | 5 |
| Engineering | DevOps Engineer | `CloudEngineer` | 8 |
| Engineering | Systems Architect | `CloudEngineer` | 6 |
| Engineering | Engineering Manager | `Engineer` | 7 |
| Engineering | QA Engineer | `Engineer` | 6 |
| Engineering | Software Engineer | `Engineer` | 4 |

| Role | People | Access level |
|---|---|---|
| HRGeneralist | 44 | Standard |
| SalesRep | 37 | Standard |
| FinanceAnalyst | 27 | Standard |
| CloudEngineer | 22 | Elevated (cloud, scoped) |
| ITAdmin | 21 | **Privileged — PIM eligible only, no access at joiner** |
| Engineer | 17 | Standard |
| SalesManager | 15 | Elevated |
| ITSupport | 13 | Elevated |
| FinanceApprover | 13 | Elevated |

### Mapping decisions to confirm in Phase 2

| Decision | Chosen | Alternative |
|---|---|---|
| HR Manager | `HRGeneralist` (managers approve through access reviews, not a separate HR app role) | A separate `HRManager` role |
| Regional Sales Lead | `SalesManager` | A separate role with cross-region visibility |
| Network Engineer (IT dept.) | `CloudEngineer` (needs Azure networking rights) | `ITSupport` |
| Engineering Manager | `Engineer` | Its own role |
| Payroll Coordinator | `FinanceAnalyst` | A payroll-specific role, given payroll data sensitivity |

## 4. Manager relationships

The export has no manager field, so reporting lines were generated deterministically (round-robin by employee ID):

| Department | Managers | Reports to |
|---|---|---|
| Sales | Regional Sales Lead (5) | — (top of department) |
| Sales | Sales Manager (10) | A Regional Sales Lead |
| Sales | Reps, AEs, BDRs (37) | A Sales Manager |
| Finance | Finance Manager (12) | — |
| Finance | Everyone else (28) | A Finance Manager |
| HR | HR Manager (7) | — |
| HR | Everyone else (37) | An HR Manager |
| Engineering | Engineering Manager (7) | — |
| Engineering | Everyone else (24) | An Engineering Manager |
| IT | **None** | **No manager title exists in IT** |

136 of 209 people have a manager. The **42 IT staff have no manager** because the source data has no IT management title. This is left as a deliberate data-quality gap: it matters in Phase 12, where access reviews assigned to "the user's manager" need a fallback reviewer.

## 5. UPN convention

The tenant uses **first initial + last name** (`acoleman`), with `2`, `3` appended on collision. The joiner reproduces this via `"upnFormat": "firstInitialLastName"` in the config.

Because the joiner processes the feed in employee ID order, collisions resolve alphabetically by first name. **199 of 209 UPNs match the export exactly.** Ten swap their `2` suffix with a namesake:

| Pair | Gets the plain UPN | Gets the `2` |
|---|---|---|
| Gutierrez | Alejandra | Alejandro |
| Ibrahim | Chidi | Chinonso |
| Johnson | James | Jessica |
| Miller | Daniel | David |
| Mosley | Imani | Isaiah |

`data/expected-upns.csv` lists the expected UPN for all 209 people; test JML-01 compares the joiner's result against it.

## 6. Data-quality findings carried into later phases

| Finding | Evidence | Addressed in |
|---|---|---|
| No employee ID on any account | Export has no ID column | Phase 1 (fixed by the feed) |
| No manager on any account | Export has no manager column | Phase 1 (136 set); IT gap → Phase 12 |
| **21 of 209 people (10%) hold admin job titles** | IT Administrator 14, Systems Administrator 7 | Phase 7: not everyone with an admin title needs an admin role |
| Password never expires on all 211 accounts | `Password never expires = True` | Phase 6: replace with MFA and passwordless rather than expiry |
| Only 1 account licensed | 210 unlicensed | Phase 0 / joiner: P2 trials usually cover fewer seats than 209 users; the joiner licenses until seats run out and then logs a warning |

## 7. Pilot feed

`data/pilot-hr-feed.csv` is a 14-person subset containing every persona used in the test cases plus their managers. Run it first, verify, then run the full feed: the pilot users are skipped on the second run, which doubles as the idempotency test.

| Persona | Employee ID | Role | Used for |
|---|---|---|---|
| Kelechi Adeyemi | E1003 | SalesRep | Promotion to SalesManager (mover) |
| Sarah Allen | E1007 | SalesManager | Kelechi's manager |
| Isaiah Dixon | E1040 | SalesManager (Regional Sales Lead) | Sarah's and Hiro's manager |
| Jun Chen | E1024 | SalesRep | Leaver |
| Hiro Kumar | E1097 | SalesManager | Jun's manager |
| Tanisha Carter | E1021 | ITAdmin | Privileged joiner; later moves to ITSupport |
| Terrell Banks | E1015 | ITSupport | IT Support boundary tests |
| Javier Cruz | E1035 | FinanceAnalyst | Session revocation; separation of duties |
| Alicia Freeman | E1055 | FinanceApprover | Javier's manager; approver side of SoD |
| Alicia Holloway | E1078 | HRGeneralist | HR app tests |
| Wei Yamamoto | E1206 | HRGeneralist (HR Manager) | Alicia Holloway's manager |
| Sofia Sanchez | E1158 | CloudEngineer | Azure custom role (Phase 8), workload identity owner (Phase 9) |
| Alejandro Gutierrez | E1065 | Engineer (Engineering Manager) | Sofia's manager; UPN collision |
| Alejandra Gutierrez | E1064 | ITSupport | UPN collision (gets `agutierrez`) |
