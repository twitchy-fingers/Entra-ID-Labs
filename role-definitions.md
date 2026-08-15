# Role Definitions — Sample Organization

## Organization Context
Simulated mid-size company (danotech.onmicrosoft.com) with 5 departments
and a mix of standard, elevated, and administrative access needs.

## Roles

| Role Name | Department | Access Level | Applications/Resources |
|---|---|---|---|
| Sales Rep | Sales | Standard | CRM (read/write own records), Email, Teams |
| Sales Manager | Sales | Elevated | CRM (read/write all records), Sales reporting app |
| Finance Analyst | Finance | Standard | Finance app (read/write), Expense system |
| Finance Manager | Finance | Elevated | Finance app (approve/manage transactions) |
| HR Generalist | HR | Standard | HRIS (read/write employee records) |
| IT Support | IT | Elevated | Helpdesk app, password reset rights (limited) |
| IT Admin | IT | Privileged | Entra ID admin roles (PIM-eligible only) |
| Standard Employee | All | Baseline | Email, Teams, SharePoint (dept. site only) |

## Design Principles
- Every role maps to the minimum access required to perform that job function
- No role includes standing privileged access — privileged roles are
  PIM-eligible only (see Step 6)
- Roles are assigned via groups, never via direct resource assignment
  to individual users
