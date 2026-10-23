# Naming conventions

Every object gets a prefix so anyone reviewing the tenant can tell what it is and why it exists from the name alone.

| Object | Pattern | Example | Phase |
|---|---|---|---|
| Emergency access account | `bg-emergency0N` | bg-emergency01 | 00 |
| Standard user | `first.last` | maria.lopez | 01 |
| Admin account | `adm-first.last` | adm-maria.lopez | 06 |
| License group | `GRP-LIC-<sku>` | GRP-LIC-EntraIDP2 | 01 |
| Dynamic baseline group | `GRP-DYN-<scope>` | GRP-DYN-Dept-Finance | 03 |
| Role group | `GRP-ROLE-<dept>-<role>` | GRP-ROLE-IT-IAMEngineer | 03 |
| App access group | `GRP-APP-<app>-<role>` | GRP-APP-Salesforce-Users | 03, 04 |
| Salesforce access group | `GRP-APP-Salesforce-<tier>` | GRP-APP-Salesforce-Managers | 04 |
| Okta access group | `GRP-APP-Okta-<tier>` | GRP-APP-Okta-Users | 04 |
| Conditional Access exclusion group | `GRP-CA-Excl-<reason>` | GRP-CA-Excl-EmergencyAccess | 05 |
| Conditional Access policy | `CA<nnn>-<users>-<control>` | CA001-AllUsers-RequireMFA | 05 |
| PIM-eligible group | `GRP-PIM-<role>` | GRP-PIM-UserAdministrator | 06 |
| Azure custom role | `DNT-<scope>-<purpose>` | DNT-RG-VMOperator | 07 |
| App registration | `APP-<purpose>` | APP-JML-Automation | 08 |
| Workload identity (federated) | `WID-<platform>-<purpose>` | WID-GitHub-JML | 08 |
| Managed identity | `MI-<resource>-<purpose>` | MI-Func-Reports | 08 |
| Agent identity | `AGT-<purpose>` | AGT-Helpdesk | 09 |
| Lifecycle workflow | `LCW-<event>-<stage>` | LCW-Leaver-LastDay | 01 |
| Web filtering policy | `GSA-<action>-<scope>` | GSA-Block-HighRisk | 05a |
| Access package | `AP-<dept>-<purpose>` | AP-Finance-Payroll | 10 |
| Access review | `AR-<scope>-<cadence>` | AR-PrivRoles-Quarterly | 11 |

Rules: no spaces, PascalCase after prefixes, no personal names in group or policy names.
