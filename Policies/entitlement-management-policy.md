# Entitlement Management Policy (Access Packages)

**Document Owner:** IAM Lab Administrator
**Last Reviewed:** 2026-08-15
**Environment:** danotech.onmicrosoft.com
**Related Policy:** access-control-policy.md

---

## 1. Purpose

Defines how self-service access requests are structured, approved, and time-bound within Entra ID Entitlement Management, complementing the admin-driven joiner/mover/leaver scripts for any access change occurring outside the initial provisioning event.

## 2. Scope

Applies to all access packages within the `Department Access Catalog`, including standard department access and privileged IT admin access.

## 3. Catalog Structure

| Access Package | Target Group | Approval | Expiration |
|---|---|---|---|
| Finance Department Access | SG-Finance-Users | Single (department manager) | 90 days |
| Sales Department Access | SG-Sales-Users | Single (department manager) | 90 days |
| Engineering Department Access | SG-Engineering-Users | Single (department manager) | 90 days |
| IT Admin Access (Privileged) | SG-IT-Admins | Multi-stage (manager + security lead) | 30 days |

## 4. Approval Authority

Access to a department's resources is approved by that department's designated manager or resource owner — not by IT. IT's role in this model is limited to catalog and access package configuration, not individual access decisions. Privileged access additionally requires a second approval stage from a designated security/IT lead.

## 5. Request Requirements

- Requestor must provide a written justification for the access requested.
- Access packages require approval before any group membership is granted — no auto-approval is configured for any package in this catalog.

## 6. Expiration and Recertification

- Standard access packages expire after 90 days and require a recurring access review for renewal.
- Privileged access packages expire after 30 days, reflecting the higher risk of standing privileged access, and require a recurring access review at the same cadence.
- Expired assignments are automatically removed from the target group without requiring a manual deprovisioning step.

## 7. Relationship to Joiner/Mover/Leaver Scripts

- Initial joiner provisioning is handled by `joiner.ps1`, not by an access package request — a new hire's baseline department access is granted automatically as part of onboarding.
- Access changes after initial provisioning (e.g., a cross-department project need, a role transfer's new department access) are handled through access package requests rather than direct script-driven group changes, ensuring business-owner approval is captured for any access granted outside the initial joiner event.
- Full offboarding remains the responsibility of `leaver.ps1`, which removes all group memberships — including any granted via access packages — regardless of their configured expiration date.

## 8. Relationship to Privileged Identity Management (PIM)

Entitlement Management and PIM address different stages of privileged access and are used together, not interchangeably:

- **Entitlement Management** governs how a user becomes *eligible* for privileged group membership (the request/approval process).
- **PIM** governs *activation* of that already-assigned eligibility (just-in-time elevation, time-boxed, with its own approval and justification requirements).

A user approved for `SG-IT-Admins` via the IT Admin Access package is not granted standing privileged rights — that group membership is itself configured as PIM-eligible, requiring separate activation for each use.

## 9. Review and Maintenance

This policy is reviewed whenever the catalog structure, approval chain, or expiration windows change, and at minimum alongside each quarterly access review cycle.

## 10. Related Documents

- `access-control-policy.md`
- `mover-sop.md`
- `/compliance/control-traceability-matrix.md`
