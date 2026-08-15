# Standard Operating Procedure: Joiner (Onboarding)

**Document Owner:** Entra-ID Lab Administrator
**Last Reviewed:** 2026-08-15
**Environment:** danotech.onmicrosoft.com
**Related Policy:** access-control-policy.md

---

## 1. Purpose

Defines the standard process for provisioning a new user account in Entra ID when an employee joins the organization, ensuring access is granted correctly, consistently, and only to what the role requires.

## 2. Trigger

Initiated when a new hire record appears in the simulated HR data feed (`/data/sample-hr-feed.csv`) with `Status = Active` and a start date on or before the current processing date.

## 3. Pre-Requisites

- New hire record includes: First Name, Last Name, Username, Department, Job Title, Manager, Start Date, Status.
- Corresponding assigned role group (`SG-<Department>-Users`) already exists in the tenant.
- Microsoft Graph PowerShell session authenticated with `User.ReadWrite.All` and `Group.ReadWrite.All` scopes.
- An available license SKU is confirmed if the new hire requires one.

## 4. Procedure

| Step | Action | Owner |
|---|---|---|
| 1 | HR system exports new hire record to the HR feed | HR (simulated) |
| 2 | IAM administrator imports the feed and filters for `Status = Active` | IT/IAM |
| 3 | Run `joiner.ps1` against the new hire record(s) | IT/IAM |
| 4 | Script creates the user object via `New-MgUser`, setting UPN as `<username>@danotech.onmicrosoft.com` | Automated |
| 5 | Script sets `ForceChangePasswordNextSignIn = $true` on the password profile | Automated |
| 6 | Script sets `Department`, `JobTitle`, and `UsageLocation` attributes | Automated |
| 7 | Script adds the user to the corresponding `SG-<Department>-Users` group | Automated |
| 8 | Script assigns the appropriate license SKU, if applicable | Automated |
| 9 | Verify user creation in the Entra admin center | IT/IAM |
| 10 | Verify group membership matches the employee's department | IT/IAM |
| 11 | Confirm baseline Conditional Access policies (e.g., MFA) apply to the new account | IT/IAM |
| 12 | Provide credentials to the new hire through an approved secure channel | IT/IAM |

## 5. Access Granted by Default

- Membership in the department's assigned role group (`SG-<Department>-Users`)
- Applicable license SKU, if the role requires one
- Baseline Conditional Access policies (MFA enforcement) — applied automatically since these target "All users"
- No privileged group membership is granted at onboarding under any circumstances

## 6. Note on Dynamic Groups

If a corresponding dynamic group exists for the department (e.g., `SG-Finance-Dynamic`), the user's membership in it is automatic once the `Department` attribute is set in Step 6 — no separate script action is required. This should be verified, not assumed (see Validation Checklist).

## 7. Validation Checklist

- [ ] User object exists with correct UPN (`<username>@danotech.onmicrosoft.com`)
- [ ] `AccountEnabled = true`
- [ ] `ForceChangePasswordNextSignIn = true`
- [ ] `Department`, `JobTitle`, `UsageLocation` correctly set
- [ ] User is a member of exactly one assigned role group matching their department
- [ ] If a corresponding dynamic group exists, user membership confirmed within the processing window
- [ ] User is **not** a member of any privileged group (`SG-*-Admins`)
- [ ] License, if applicable, shows as assigned on the user's profile
- [ ] Entra ID Audit Log shows "Add user" and "Add member to group" entries with correct timestamp

## 8. Exceptions

Any deviation from standard provisioning (e.g., a new hire requiring cross-department access on day one) must be requested via the appropriate access package per `entitlement-management-policy.md`, not granted directly during the joiner script run.

## 9. Related Test Cases

TC-01, TC-02 (see `/test-cases/test-matrix.md`)
