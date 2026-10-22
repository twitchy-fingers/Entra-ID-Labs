# JML Test Matrix

Each test lists the earliest phase after which it can run. Fill in **Actual result**, **Evidence**, and **Status** as you execute. Status values: `Not run` · `Pass` · `Fail` · `Blocked`.

Test users come from `data/pilot-hr-feed.csv` (14 personas) and `data/sample-hr-feed.csv` (all 209), built from the Danotech tenant export as described in `docs/hr-feed-mapping.md`. Jun Chen (E1024) is reserved as the leaver test subject; don't use Jun for RBAC tests in later phases.

## Joiner

| ID | Run after | Scenario | Steps | Expected result | Actual result | Evidence | Status |
|---|---|---|---|---|---|---|---|
| JML-01 | Phase 1 | Joiner creates accounts from HR feed | Run `joiner.ps1` with `pilot-hr-feed.csv`, then `sample-hr-feed.csv` | Pilot: 14 accounts. Full: 195 more (209 total) with Department, Job title, Employee ID, and hire date populated; every UPN matches `data/expected-upns.csv` | | P1-02, P1-03 | Not run |
| JML-02 | Phase 1 | `-WhatIf` makes no changes | Run joiner with `pilot-hr-feed.csv -WhatIf` before JML-01 | WHATIF lines only; user count unchanged | | P1-01 | Not run |
| JML-03 | Phase 1 | Re-run is idempotent | Run the full feed after the pilot, then run it again | First full run: the 14 pilot users SKIPPED. Second run: all 209 SKIPPED; no duplicate accounts | | P1-07 | Not run |
| JML-04 | Phase 1 | Unknown role rejected | Run joiner with `sample-hr-feed-invalid.csv` | ERROR logged for `SalesDirector`; no account created for E1999 (Riley Moss) | | P1-05 | Not run |
| JML-05 | Phase 1 | Manager relationships set | Check Kelechi Adeyemi, Javier Cruz, Sofia Sanchez, Sarah Allen | Managers are Sarah Allen, Alicia Freeman, Alejandro Gutierrez, and Isaiah Dixon respectively; IT staff (e.g., Tanisha Carter) have no manager, a known data gap | | P1-04 | Not run |
| JML-06 | Phase 1 | Privileged role gets no access at joiner | Check Tanisha Carter → Assigned roles; count WARNING lines | WARNING logged for all 21 ITAdmin users; Tanisha has no directory roles | | P1-06 | Not run |
| JML-07 | Phase 3 | Joiner adds role group membership | Re-run joiner after role groups exist | Each non-baseline, non-privileged user added to exactly one RBAC role group | | P3 screenshot | Not run |

## Mover

| ID | Run after | Scenario | Steps | Expected result | Actual result | Evidence | Status |
|---|---|---|---|---|---|---|---|
| JML-08 | Phase 3 | Promotion removes old role, adds new | `mover.ps1` Kelechi Adeyemi → `SalesManager` | Removed from RBAC-SalesRep, added to RBAC-SalesManager, title updated; audit log shows remove before add | | P1-09, P1-10 | Not run |
| JML-09 | Phase 4 | New role claim issued after move | Sign in as Kelechi after mover with `-RevokeSessions`; decode token | `roles` claim contains `Sales.ReadWrite.All` and not `Sales.ReadWrite.Own` | | Phase 4 screenshot | Not run |
| JML-10 | Phase 7 | Moving out of privileged role removes PIM eligibility | `mover.ps1` Tanisha Carter → `ITSupport` | PIM eligibility removed; added to RBAC-ITSupport | | P1-11 | Not run |

## Leaver

| ID | Run after | Scenario | Steps | Expected result | Actual result | Evidence | Status |
|---|---|---|---|---|---|---|---|
| JML-11 | Phase 3 | Account disabled and sign-in blocked | `leaver.ps1` Jun Chen; attempt sign-in | Account disabled; sign-in fails with AADSTS50057 | | P1-13, P1-14 | Not run |
| JML-12 | Phase 3 | Assigned groups removed, evidence captured | Inspect Jun's groups and `logs/leaver-snapshot-E1024-*.json` | No assigned groups remain; snapshot lists the removed RBAC-SalesRep membership | | P1-12, P1-15 | Not run |
| JML-13 | Phase 3 | Dynamic group drops disabled user | Check RBAC-StandardEmployee members after leaver | Jun no longer listed (allow a few minutes for processing) | | P1-16 | Not run |
| JML-14 | Phase 7 | Leaver removes PIM eligibility | Give a test user PIM eligibility, then run leaver on them | Eligibility removed; logged | | Leaver output | Not run |
| JML-15 | Phase 1 | Direct license reclaimed | Check Jun → Licenses after leaver | Directly assigned license removed | | Portal | Not run |
| JML-16 | Phase 1 | All JML actions attributable | Audit logs filtered to the operator account | Every create, update, group change, and revoke is present with the operator as initiator | | P1-08 | Not run |

## Session revocation

| ID | Run after | Scenario | Steps | Expected result | Actual result | Evidence | Status |
|---|---|---|---|---|---|---|---|
| JML-17 | Phase 1 | Standalone revocation forces re-authentication | Sign in as Javier Cruz; run `revoke-sessions.ps1`; refresh | Re-authentication required within the token lifetime; audit log shows "Invalidate all refresh tokens for user" | | P1-17, P1-18 | Not run |

## Summary

| Total | Pass | Fail | Blocked | Not run |
|---|---|---|---|---|
| 17 | 0 | 0 | 0 | 17 |
