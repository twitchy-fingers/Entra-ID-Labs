# Standard Operating Procedure: Mover (Role/Department Change)

**Document Owner:** Entra-ID Lab Administrator
**Last Reviewed:** 2026-08-15
**Environment:** danotech.onmicrosoft.com
**Related Policy:** access-control-policy.md

---

## 1. Purpose

Defines the standard process for updating a user's access in Entra ID when they change department or role, with the specific objective of preventing privilege creep.

## 2. Trigger

Initiated when an existing user's department is updated in the HR data feed, or upon confirmed notification from HR/the employee's manager of an internal transfer.

## 3. Pre-Requisites

- Confirmed new department and effective date of transfer.
- Target department's assigned role group already exists.
- If a dynamic group exists for the new department, its membership rule is confirmed correct (e.g., `user.department -eq "NewDept"`).

## 4. Procedure

| Step | Action | Owner |
|---|---|---|
| 1 | Transfer confirmed via HR feed update or manager notification | HR/Manager |
| 2 | IAM administrator runs `mover.ps1` with old and new department parameters | IT/IAM |
| 3 | Script removes user from the **old** department's `SG-<Dept>-Users` group (`Remove-MgGroupMemberByRef`) | Automated |
| 4 | Script adds user to the **new** department's `SG-<Dept>-Users` group (`New-MgGroupMember`) | Automated |
| 5 | Script updates the `Department` attribute on the user object (`Update-MgUser`) | Automated |
| 6 | Verify old assigned-group membership has been removed | IT/IAM |
| 7 | Verify new assigned-group membership has been added | IT/IAM |
| 8 | Wait for dynamic group processing cycle, then verify dynamic group membership updated automatically | IT/IAM |
| 9 | If moving into or out of a privileged role, process any `SG-*-Admins` change as a separate, explicitly approved step (see Section 6) | IT/IAM |
| 10 | If prior access was granted via an access package, allow it to lapse at its scheduled expiration rather than manually revoking, unless immediate removal is required | IT/IAM |

## 5. Order of Operations (Critical)

Old access removal and new access grant are treated as a single atomic transfer. Access is never left in place "temporarily" pending a later cleanup step. This ordering — enforced by the script itself — is the primary control this SOP exists to validate.

## 6. Privileged Role Changes

Any transfer into or out of a privileged group (`SG-IT-Admins`) is not automated by the standard mover script and requires:
- Written approval from the receiving department's manager, routed through the multi-stage approval access package (`entitlement-management-policy.md`) for a transfer **into** a privileged role
- Immediate removal, processed with the same urgency as a leaver event for that specific group, for a transfer **out of** a privileged role

## 7. Validation Checklist

- [ ] User is no longer a member of the prior department's assigned role group
- [ ] User is a member of exactly the new department's assigned role group
- [ ] `Department` attribute matches the new assignment
- [ ] Any dynamic group tied to the department attribute has updated membership automatically (no manual intervention)
- [ ] Entra ID Audit Log shows "Remove member from group," "Add member to group," and "Update user" entries with correct timestamps
- [ ] No unintended change to license assignment occurred as a side effect

## 8. Exceptions

If a user legitimately requires continued access to their prior department's resources following a transfer, this must be requested as a time-boxed access package with an explicit expiration date, not left as standing assigned-group membership.

## 9. Related Test Cases

TC-03, TC-04, TC-05 (see `/test-cases/test-matrix.md`)
