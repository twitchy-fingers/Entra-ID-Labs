# HR feed mapping

`data/hr-feed.csv` holds 200 fictional employees of Danotech Inc. This document defines each column, where it lands in Entra ID, and which phase depends on it.

## Column → Entra ID property

| HR column | Entra ID (Graph) property | Example | Used by |
|---|---|---|---|
| EmployeeID | `employeeId` | DNT10042 | Joiner matching key, audit evidence |
| FirstName / LastName | `givenName` / `surname` | Emeka / Torres | Display |
| DisplayName | `displayName` | Emeka Torres | Display |
| UserPrincipalName | `userPrincipalName` | emeka.torres@danotechinc.onmicrosoft.com | Sign-in |
| MailNickname | `mailNickname` | emekatorres | Required by Graph on create |
| Department | `department` | IT | Dynamic groups (03), reviews (11) |
| JobTitle | `jobTitle` | IAM Engineer | Role groups (03), RBAC matrix (02) |
| JobLevel | `onPremisesExtensionAttributes.extensionAttribute1` | Manager | Manager/director groups (03) |
| ManagerEmployeeID / ManagerUPN | `manager` (reference) | DNT10125 | Approvals (10), reviewers (11) |
| OfficeLocation, City, State, Country, PostalCode | `officeLocation`, `city`, `state`, `country`, `postalCode` | London | Location-based Conditional Access (05) |
| UsageLocation | `usageLocation` | GB | Required before license assignment |
| CostCenter | `employeeOrgData.costCenter` | CC-500 | Finance-scoped access (02) |
| EmployeeType | `employeeType` | Contractor | Contractor policies (01, 10) |
| HireDate | `employeeHireDate` | 2023-04-17 | Joiner timing (01) |
| ContractEndDate | `employeeLeaveDateTime` | 2026-10-08 | Leaver automation (01) |
| CompanyName | `companyName` | Danotech Inc | Dynamic "all employees" group |
| EmploymentStatus | `accountEnabled` | Active → true | Leaver automation (01) |

Notes:

- `extensionAttribute1`–`15` are writable through Graph for cloud-only users and usable in dynamic membership rules.
- Writing `employeeLeaveDateTime` needs the `User-LifeCycleInfo.ReadWrite.All` permission in addition to `User.ReadWrite.All`.
- No password column exists. The joiner script generates temporary passwords at run time.

## Headcount

| Department | People | Cost center |
|---|---|---|
| Executive | 7 | CC-100 |
| Sales | 47 | CC-200 |
| HR | 39 | CC-300 |
| IT | 39 | CC-400 |
| Finance | 37 | CC-500 |
| Engineering | 31 | CC-600 |

Offices: Austin HQ (80), Atlanta (55), Seattle (34), London (31, usage location `GB`).

## Reporting chain

CEO → C-level leaders (Revenue, People, Information, Finance, Technology) → department heads → managers/leads → staff. Only the CEO has no manager.

## The CEO account

`DNT10001` Daniel Opara (`daniel.opara@…`) already exists: it is the tenant setup account and currently holds Global Administrator. The joiner script matches it by UPN instead of creating a duplicate, stamps its HR attributes, and treats it as a **protected account** (listed in `config/jml-config.json`) that leaver and mover logic never disables or strips.

Holding standing Global Administrator on a daily-use executive account is a real finding (**F-001**), tracked until Phase 06 fixes it.

## Planted findings

The feed contains deliberate problems for later phases to catch. As of 2026-10-22:

| EmployeeID | Name | Title | Contract end | Finding |
|---|---|---|---|---|
| DNT10040 | Hiroshi Thompson | Sales Development Associate | 2026-08-12 | Past end date, still Active |
| DNT10067 | Maria Thompson | Talent Acquisition Specialist | 2026-10-08 | Past end date, still Active |
| DNT10123 | Chen Moreau | Service Desk Analyst | 2026-10-18 | Past end date, still Active |
| DNT10175 | Priya Olsen | Backend Developer | 2026-10-09 | Past end date, still Active |
| DNT10041 | Jordan Lindqvist | Sales Development Associate | 2027-06-30 | Active contractor (control case) |
| DNT10122 | Reggie Fernandez | Service Desk Analyst | 2027-05-16 | Active contractor (control case) |

Expected outcome: the Phase 01 leaver run disables the four expired contractors, and the Phase 11 review report lists them as remediated.
