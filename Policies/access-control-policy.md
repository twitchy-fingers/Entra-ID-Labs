# Access Control Policy

**Document Owner:** Entra-ID Lab Administrator
**Last Reviewed:** 2026-08-15
**Environment:** Microsoft Entra ID tenant — danotech.onmicrosoft.com
**Applies To:** This is a standalone, cloud-native environment with no connection to any on-premises Active Directory domain or hybrid identity sync.

---

## 1. Purpose

This policy defines how access to Entra ID-managed resources is granted, structured, and maintained, in order to enforce least privilege and prevent unauthorized or excessive access accumulation ("privilege creep") in a cloud-only identity environment.

## 2. Scope

Applies to all user accounts, security groups, access packages, and Conditional Access policies within the danotech.onmicrosoft.com tenant.

## 3. Access Control Model

Access is granted through role-based security groups rather than assigned directly to individual users. Two group types are used, each suited to a different access scenario:

| Group Type | Membership | Used For |
|---|---|---|
| Assigned (Security) | Manually/script-managed, static | Baseline role access set at initial provisioning |
| Dynamic User (Security) | Rule-based on user attributes, self-maintaining | Structural mover enforcement — membership updates automatically when a user's department attribute changes |

### 3.1 Group Naming Convention

| Pattern | Purpose | Example |
|---|---|---|
| `SG-<Department>-Users` | Assigned, role-based access group | `SG-Finance-Users` |
| `SG-<Department>-Dynamic` | Dynamic, attribute-based access group | `SG-Finance-Dynamic` |
| `SG-<Department>-Admins` | Privileged role-based group | `SG-IT-Admins` |

All security groups are prefixed `SG-`.

## 4. Self-Service Access (Entitlement Management)

Beyond initial provisioning, standard access changes are made available through self-service **access packages** rather than admin-provisioned group membership:

- Access is requested by the user and approved by the relevant business owner (department manager), not by IT.
- Standard access packages expire after 90 days and require a recurring access review for renewal.
- Privileged access (`SG-IT-Admins`) requires multi-stage approval and a shorter 30-day expiration window.

## 5. Least Privilege Principles

- Users are granted access only to the resources required for their current role.
- Privileged accounts (`SG-IT-Admins`) are kept structurally separate from standard role groups (`SG-IT-Users`).
- Access changes triggered by role transfers must remove prior access before or simultaneously with granting new access.
- Standing privileged role assignments are avoided in favor of PIM-eligible, time-bound activation wherever P2 licensing permits.

## 6. Session and Token Management

Disabling a user's account (`AccountEnabled = $false`) blocks future sign-ins only. It does not invalidate an already-active session or token. Explicit session revocation (`Revoke-MgUserSignInSession`) is a required, separate step in the leaver process — see `leaver-sop.md`.

## 7. Licensing Considerations

Certain access control capabilities referenced in this policy — dynamic groups, Access Reviews, PIM, and Entitlement Management multi-stage approval — require Entra ID P1/P2 licensing. This tenant is provisioned with Microsoft 365 Developer Program licensing (E5/P2), which includes these capabilities. Any deployment on Entra ID Free tier would need to document this as a limitation rather than assume equivalent capability.

## 8. Review and Maintenance

- Group membership is reviewed as part of each joiner, mover, and leaver event per the associated SOPs.
- Access package assignments are reviewed automatically via recurring Access Reviews.
- This policy is reviewed whenever the group model, naming convention, or licensing tier changes.

## 9. Related Documents

- `joiner-sop.md`
- `mover-sop.md`
- `leaver-sop.md`
- `entitlement-management-policy.md`
- `/compliance/control-traceability-matrix.md`
