# joiner.ps1 — New Hire Provisioning

**Policy:** [SOP-JML-01 Joiner](../policies/sop-jml-01-joiner.md) · **Tests:** JML-01 to JML-07 in [test-matrix.md](../test-cases/test-matrix.md)

## Purpose

Creates Entra ID accounts for new hires from the authoritative HR feed and grants access **only** through the RBAC role group for their role. Privileged roles are never granted automatically.

## Design decisions

| Decision | Why |
|---|---|
| `EmployeeId` is the identity anchor | Names change and UPNs can collide; the HR employee ID is unique and immutable. It also makes the script idempotent. |
| Role must exist in `config/jml-config.json` | Prevents ad-hoc roles. An unknown role is rejected and returned to HR. |
| Access via role group only | Implements the "no direct assignment" principle the RBAC model depends on. |
| Privileged roles flagged, not granted | Admin access requires a separate, approved PIM eligibility request. |
| Two-pass processing | Managers can appear anywhere in the feed; managers are set after everyone exists. |
| Temporary password shown once | Never written to the log or disk. Users must change it at first sign-in. |
| Retry wrapper | Newly created users can take a few seconds to replicate before group or license operations succeed. |

## Prerequisites

- Phase 0 complete
- Graph scopes (requested automatically): `User.ReadWrite.All`, `User-LifeCycleInfo.ReadWrite.All` (for hire date), `Group.ReadWrite.All`, `Organization.Read.All`
- Role groups are optional. If they don't exist yet, the script logs a warning and you re-run it after Phase 3.

## Input: HR feed format

| Column | Required | Example | Notes |
|---|---|---|---|
| EmployeeId | Yes | `E1003` | Unique, immutable |
| FirstName / LastName | Yes | `Kelechi` / `Adeyemi` | Used to build the UPN (`kadeyemi`, per `upnFormat` in the config) |
| Department | Yes | `Sales` | |
| JobTitle | Yes | `Account Executive` | |
| Role | Yes | `SalesRep` | Must match a key in the role catalog |
| ManagerEmployeeId | No | `E1001` | Blank for top-level managers |
| StartDate | No | `2026-10-12` | Format `yyyy-MM-dd`; sets `employeeHireDate` |
| UsageLocation | Yes | `US` | Required for license assignment |

## Usage

The feed was built from the Danotech tenant export; see [docs/hr-feed-mapping.md](../docs/hr-feed-mapping.md). Run the 14-person pilot first, verify it, then run the full 209-person feed.

```powershell
cd scripts

# 1. Preview the pilot — no changes made
./joiner.ps1 -CsvPath ../data/pilot-hr-feed.csv -WhatIf

# 2. Run the pilot
./joiner.ps1 -CsvPath ../data/pilot-hr-feed.csv

# 3. Negative test — invalid role
./joiner.ps1 -CsvPath ../data/sample-hr-feed-invalid.csv

# 4. Full feed — the 14 pilot users are skipped, 195 are created
./joiner.ps1 -CsvPath ../data/sample-hr-feed.csv

# 5. Re-run the full feed — all 209 skipped
./joiner.ps1 -CsvPath ../data/sample-hr-feed.csv
```

The full run makes several Graph calls per person, so allow 15–30 minutes for 209 users.

## Expected output

**Pilot (14 people):**
- 14 `[SUCCESS] Joiner ... Create user` lines, with UPNs in first-initial-plus-last-name form (`kadeyemi@`, `tcarter@`, ...)
- Alejandra Gutierrez (E1064) gets `agutierrez@`; Alejandro Gutierrez (E1065) gets `agutierrez2@`, showing collision handling
- A yellow `[WARNING]` for Tanisha Carter (ITAdmin): privileged, no access granted
- `[WARNING]` "group does not exist yet" for role groups, until Phase 3 is done
- 7 `Set manager` lines (Terrell, Tanisha, Isaiah, Alicia Freeman, both Gutierrezes, and Wei Yamamoto have no manager in the feed)
- License lines until your P2 seats run out, then a warning per user: `No AAD_PREMIUM_P2 seats left. Account created unlicensed.`
- A table of temporary passwords, then the log path `logs/jml-YYYY-MM-DD.csv`

**Full feed after the pilot:**
- 14 `[SKIPPED] ... already exists`, 195 `Create user`
- 21 privileged warnings (14 IT Administrators + 7 Systems Administrators). They repeat on every run, including for skipped users, because the check runs for everyone in the feed
- 136 people with a manager in total. The 42 IT staff have none, which is a known data gap (see the mapping doc §4)

**Verify UPNs against the expected list:**

```powershell
$expected = Import-Csv ../data/expected-upns.csv
$actual   = Get-MgUser -All -Property EmployeeId, UserPrincipalName |
    Where-Object EmployeeId | Group-Object EmployeeId -AsHashTable -AsString
$expected | Where-Object { $actual[$_.EmployeeId].UserPrincipalName -ne $_.ExpectedUpn } |
    Select-Object EmployeeId, DisplayName, ExpectedUpn
```

No output means every UPN matches.

## Verify in the portal

1. Entra admin center → **Users** → **All users** → **Manage view → Edit columns**, add Department, Job title, and Employee ID.
2. Open Kelechi Adeyemi → **Properties** → confirm Employee ID, hire date, and Manager = Sarah Allen.
3. Open Tanisha Carter → **Assigned roles** → confirm **no** roles.
4. **Audit logs** → filter Activity = `Add user` → entries are attributed to your admin account.

## Screenshots

| ID | File | Must show |
|---|---|---|
| P1-01 | `screenshots/jml/joiner-whatif-output.png` | `-WhatIf` run with cyan WHATIF lines and nothing created |
| P1-02 | `screenshots/jml/joiner-run-output.png` | Live run output. **Blur the temporary password column.** |
| P1-03 | `screenshots/jml/users-list-with-attributes.png` | All users with Department, Job title, and Employee ID columns, showing 209 workforce users |
| P1-04 | `screenshots/jml/user-properties-manager.png` | Kelechi Adeyemi's properties: Employee ID, hire date, manager |
| P1-05 | `screenshots/jml/joiner-invalid-role-rejected.png` | Red ERROR line for role `SalesDirector` |
| P1-06 | `screenshots/jml/itadmin-no-roles.png` | Tanisha Carter → Assigned roles: empty |
| P1-07 | `screenshots/jml/joiner-idempotent-rerun.png` | Re-run showing SKIPPED for existing users |
| P1-08 | `screenshots/jml/audit-log-add-user.png` | Audit log "Add user" entries with Initiated by visible |

## Limitations

- Users are created enabled on run day. A production version would create pre-hire accounts disabled and enable them on the start date (or use Lifecycle Workflows).
- The script doesn't send the temporary password. In production, use Temporary Access Pass with a secure delivery channel.
