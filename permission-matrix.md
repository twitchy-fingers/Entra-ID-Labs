# Permission Matrix

| Role | App/Resource | Permission | Justification |
|---|---|---|---|
| Sales Rep | Salesforce CRM | App Role: Sales.ReadWrite.Own | Needs own pipeline access only |
| Sales Manager | Salesforce CRM | App Role: Sales.ReadWrite.All | Needs team visibility |
| Finance Analyst | NetSuite | App Role: Finance.ReadWrite | Data entry, no approval rights |
| Finance Approver | NetSuite | App Role: Finance.Approve | Approval workflow only |
| HR Generalist | Workday | App Role: HR.ReadWrite | Employee record management |
| Junior Engineer | GitHub | App Role: Repo.ReadWrite.Own | Contributes to owned repos, no release control |
| Senior Engineer | Azure DevOps | App Role: Release.Approve | Gatekeeps production releases |
| IT Support | ServiceNow | App Role: Helpdesk.ReadWrite | Ticket management |
| IT Admin | Entra ID | Eligible: User Administrator (PIM) | No standing access |
| Standard Employee | SharePoint | Site-level Read/Write (own dept site only) | Baseline collaboration access |
