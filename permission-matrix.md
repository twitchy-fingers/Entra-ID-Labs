# Permission Matrix

| Role | App/Resource | Permission | Justification |
|---|---|---|---|
| Sales Rep | CRM App | App Role: Sales.ReadWrite.Own | Needs own pipeline access only |
| Sales Manager | CRM App | App Role: Sales.ReadWrite.All | Needs team visibility |
| Finance Analyst | Finance App | App Role: Finance.ReadWrite | Data entry, no approval rights |
| Finance Manager | Finance App | App Role: Finance.Approve | Approval workflow only |
| HR Generalist | HRIS App | App Role: HR.ReadWrite | Employee record management |
| IT Support | Helpdesk App | App Role: Helpdesk.ReadWrite | Ticket management |
| IT Admin | Entra ID | Eligible: User Administrator (PIM) | No standing access |
| Standard Employee | SharePoint | Site-level Read/Write (own dept site only) | Baseline collaboration access |
