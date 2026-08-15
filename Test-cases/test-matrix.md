# Test Case Matrix — Entra ID JML Lab

**Document Owner:** Entra-ID Lab Administrator
**Last Reviewed:** 2026-08-15
**Environment:** danotech.onmicrosoft.com

---

## 1. Joiner Test Cases

| Test ID | Scenario | Expected Result | Related Control | Actual Result | Pass/Fail |
|---|---|---|---|---|---|
| TC-01 | New hire provisioned via `joiner.ps1` from HR feed | User created, correct department set, added to correct assigned role group | CTRL-01, CTRL-02 | | |
| TC-02 | New hire license assignment | License visible on user profile | CTRL-03 | | |

## 2. Mover Test Cases

| Test ID | Scenario | Expected Result | Related Control | Actual Result | Pass/Fail |
|---|---|---|---|---|---|
| TC-03 | Mover — old assigned group access | Removed immediately by `mover.ps1` | CTRL-04 | | |
| TC-04 | Mover — new assigned group access | Present immediately by `mover.ps1` | CTRL-04 | | |
| TC-05 | Mover — dynamic group | Auto-updates within processing window, no manual script step required | CTRL-05 | | |

## 3. Leaver Test Cases

| Test ID | Scenario | Expected Result | Related Control | Actual Result | Pass/Fail |
|---|---|---|---|---|---|
| TC-06 | Leaver — sign-in after disable | Fails with reason "account disabled" | CTRL-06 | | |
| TC-07 | Leaver — group memberships post-script | Zero remaining | CTRL-07 | | |
| TC-08 | Leaver — active session before `Revoke-MgUserSignInSession` | Confirmed still valid | CTRL-08 | | |
| TC-09 | Leaver — active session after `Revoke-MgUserSignInSession` | Confirmed terminated | CTRL-08 | | |
| TC-10 | Leaver — license status post-script | No licenses assigned | CTRL-09 | | |

## 4. Least Privilege Test Cases

| Test ID | Scenario | Expected Result | Related Control | Actual Result | Pass/Fail |
|---|---|---|---|---|---|
| TC-11 | Standard user group membership audit | Member of exactly one department role group; no privileged group membership | CTRL-10 | | |
| TC-12 | Audit log review for a joiner action | "Add user" and "Add member to group" entries present with correct timestamp | CTRL-18 | | |

## 5. PIM and Privileged Access Test Cases

| Test ID | Scenario | Expected Result | Related Control | Actual Result | Pass/Fail |
|---|---|---|---|---|---|
| TC-22 | PIM-eligible admin attempts action without activating role | Action blocked | CTRL-12 | | |
| TC-23 | PIM activation submitted without required approval | Role remains inactive, access denied | CTRL-12 | | |

## 6. Entitlement Management Test Cases

| Test ID | Scenario | Expected Result | Related Control | Actual Result | Pass/Fail |
|---|---|---|---|---|---|
| TC-24 | User requests an access package | Request appears in approver's queue with justification | CTRL-13 | | |
| TC-25 | Approver grants request | User added to corresponding group automatically | CTRL-13 | | |
| TC-26 | Access package assignment expires | User automatically removed from corresponding group | CTRL-14, CTRL-16, CTRL-17 | | |
| TC-27 | Privileged access package requested | Requires both approval stages before grant | CTRL-15 | | |

---

## 7. Test Execution Record

| Test Run Date | Executed By | Total Tests | Passed | Failed | Notes |
|---|---|---|---|---|---|
| | | 15 | | | |

## 8. Related Documents

- `../policies/joiner-sop.md`
- `../policies/mover-sop.md`
- `../policies/leaver-sop.md`
- `../policies/entitlement-management-policy.md`
- `../compliance/control-traceability-matrix.md`
