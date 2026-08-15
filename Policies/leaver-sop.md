# Standard Operating Procedure: Leaver (Offboarding)

**Document Owner:** IAM Lab Administrator
**Last Reviewed:** 2026-08-15
**Environment:** danotech.onmicrosoft.com
**Related Policy:** access-control-policy.md

---

## 1. Purpose

Defines the standard process for revoking access in Entra ID when an employee leaves the organization, ensuring access is removed completely — including active sessions, not just future sign-in capability.

## 2. Trigger

Initiated upon:
- A termination record appearing in the HR data feed with `Status` changed to "Inactive"/"Terminated," or
- Direct notification from HR or the employee's manager of a departure date

For involuntary terminations, this procedure must be initiated **immediately**, not deferred to the standard HR feed processing cycle.

## 3. Pre-Requisites

- Confirmed last working day / effective termination date.
- Confirmation of whether the departure is voluntary or involuntary (affects urgency).

## 4. Procedure

| Step | Action | Owner |
|---|---|---|
| 1 | Termination confirmed via HR feed or direct notification | HR/Manager |
| 2 | IAM administrator runs `leaver.ps1` against the departing user's account | IT/IAM |
| 3 | Script disables future sign-in (`Update-MgUser -AccountEnabled:$false`) | Automated |
| 4 | Script retrieves and removes all group memberships (`Get-MgUserMemberOf` / `Remove-MgGroupMemberByRef`) | Automated |
| 5 | Script revokes all active sessions and tokens (`Revoke-MgUserSignInSession`) | Automated |
| 6 | Script removes all assigned licenses (`Set-MgUserLicense -RemoveLicenses`) | Automated |
| 7 | Verify `AccountEnabled = false` on the user profile | IT/IAM |
| 8 | Verify zero remaining group memberships | IT/IAM |
| 9 | Verify zero remaining assigned licenses | IT/IAM |
| 10 | Confirm a sign-in attempt using the account's credentials fails, with reason "account disabled" | IT/IAM |
| 11 | Confirm any previously active session is no longer functional following session revocation | IT/IAM |
| 12 | Retain the disabled account object for the defined retention period before deletion | IT/IAM |

## 5. Critical Distinction: Disablement vs. Session Revocation

`AccountEnabled = $false` blocks **future** sign-in attempts only. It does **not** invalidate a session or access/refresh token already issued before disablement. Step 5 (`Revoke-MgUserSignInSession`) is a mandatory, separate action — offboarding is not considered complete until it has been executed and verified independently of the disablement step.

## 6. Retention and Deletion

- Disabled accounts are retained (not deleted) for a minimum of 90 days to preserve an audit trail and allow correction of an erroneous termination record.
- After the retention period, deletion is a separate, explicitly approved action outside the scope of the standard leaver script.

## 7. Validation Checklist

- [ ] `AccountEnabled = false`
- [ ] Zero group memberships remain (`Get-MgUserMemberOf` returns empty)
- [ ] Zero licenses remain assigned (`Get-MgUserLicenseDetail` returns empty)
- [ ] Sign-in attempt with prior credentials fails; Sign-in Log shows failure reason "account disabled"
- [ ] Session revocation confirmed — a previously active session tested and found terminated
- [ ] Entra ID Audit Log shows "Update user" (disable), "Remove member from group" (for each group), and license removal entries

## 8. Exceptions

Any request to delay deprovisioning (e.g., pending legal hold, ongoing investigation) must be documented with the requesting authority and an explicit review date. Account disablement and session revocation (Steps 3 and 5) are never delayed regardless of exception status — only license removal or deletion timing may be adjusted.

## 9. Related Test Cases

TC-06, TC-07, TC-08, TC-09, TC-10 (see `/test-cases/test-matrix.md`)
