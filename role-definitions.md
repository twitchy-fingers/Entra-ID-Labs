# Role Definitions — Sample Organization

## Organization Context
Simulated mid-size company (danotech.onmicrosoft.com) with 6 departments
and a mix of standard, elevated, and administrative access needs.

## Roles
| Role Name | Department | Access Level | Applications/Resources |
|---|---|---|---|
| Sales Rep | Sales | Standard | Salesforce CRM (read/write own records), Outlook, Teams |
| Sales Manager | Sales | Elevated | Salesforce CRM (read/write all records), Power BI Sales Dashboard |
| Finance Analyst | Finance | Standard | Quickbooks (read/write), Concur Expense |
| Finance Approver | Finance | Elevated | Quickbooks (approve transactions) |
| HR Generalist | HR | Standard | Workday (read/write employee records) |
| Junior Engineer | Engineering | Standard | GitHub (read/write own repos), Jira, Jenkins (trigger builds) |
| Senior Engineer | Engineering | Elevated | GitHub (admin on team repos), Jira (admin), Azure DevOps (release approvals) |
| IT Support | IT | Elevated | ServiceNow Helpdesk, password reset rights (limited) |
| IT Admin | IT | Privileged | Entra ID admin roles (PIM-eligible only) |
| Standard Employee | All | Baseline | Outlook, Teams, SharePoint (dept. site only) |

## Design Principles
- Every role maps to the minimum access required to perform that job function
- No role includes standing privileged access — privileged roles are
  PIM-eligible only (see Step 6)
- Roles are assigned via groups, never via direct resource assignment
  to individual users
