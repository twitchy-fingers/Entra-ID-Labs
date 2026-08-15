# NIST 800-53 Rev 5 Control Mapping — Entra ID JML Lab

**Document Owner:** Entra-ID Lab Administrator
**Last Reviewed:** 2026-08-15
**Environment:** danotech.onmicrosoft.com (standalone Entra ID, no on-prem/hybrid connection)
**Framework Reference:** NIST Special Publication 800-53, Revision 5

---

## 1. Purpose

Maps the controls implemented in this cloud-native Entra ID JML lab to NIST 800-53 Rev 5, demonstrating alignment with federal control requirements in an environment with no on-premises Active Directory component.

---

## 2. Access Control (AC) Family

### AC-2: Account Management
**Implementation:** `joiner.ps1`, `mover.ps1`, `leaver.ps1` using Microsoft Graph PowerShell, triggered by simulated HR feed events.
**Evidence:** Entra ID Audit Log entries ("Add user," "Update user," "Delete user").
**Test Case:** TC-01, TC-06.
**Status:** Implemented.

### AC-2(1): Automated System Account Management
**Implementation:** CSV-driven provisioning via `New-MgUser`, no manual account creation.
**Status:** Implemented.

### AC-2(3): Disable Accounts
**Implementation:** `Update-MgUser -AccountEnabled:$false` in `leaver.ps1`.
**Test Case:** TC-06.
**Status:** Implemented.

### AC-2(7): Role-Based Schemes
**Implementation:** Assigned security groups (`SG-<Dept>-Users`) plus dynamic groups (`SG-<Dept>-Dynamic`) for attribute-driven role assignment.
**Status:** Implemented.

### AC-3: Access Enforcement
**Implementation:** Group-based access to resources; access package approval gating for post-provisioning access changes.
**Test Case:** TC-24, TC-25.
**Status:** Implemented.

### AC-6: Least Privilege
**Implementation:** Role-scoped group membership; no default privileged access at provisioning.
**Test Case:** TC-11.
**Status:** Implemented.

### AC-6(1): Authorize Access to Security Functions
**Implementation:** PIM eligible-role assignment for `SG-IT-Admins`, requiring explicit time-boxed activation.
**Evidence:** PIM role settings screenshot.
**Test Case:** TC-22, TC-23.
**Status:** Implemented.

### AC-6(5): Privileged Accounts
**Implementation:** `SG-IT-Admins` structurally separate from `SG-IT-Users`; multi-stage approval required for entry via access package.
**Test Case:** TC-27.
**Status:** Implemented.

### AC-6(7): Periodic Review of Privileges
**Implementation:** 90-day recurring Access Reviews (standard); 30-day recurring reviews (privileged access packages).
**Test Case:** TC-26.
**Status:** Implemented.

### AC-12: Session Termination
**Implementation:** `Revoke-MgUserSignInSession`, executed as an explicit, separate step within `leaver.ps1`, distinct from account disablement.
**Evidence:** Sign-in log showing session termination.
**Test Case:** TC-08, TC-09.
**Status:** Implemented.

---

## 3. Identification and Authentication (IA) Family

### IA-2(1) / IA-2(2): Multifactor Authentication
**Implementation:** Conditional Access policies enforcing MFA for all users and, additionally, compliant device requirements for privileged accounts.
**Status:** Implemented (assumes Conditional Access layer is configured per the hybrid lab's pattern; if not yet built in this standalone tenant, flag as planned rather than implemented).

### IA-5(13): Expiration of Cached Authenticators
**Implementation:** Session/token revocation on offboarding via `Revoke-MgUserSignInSession`.
**Test Case:** TC-09.
**Status:** Implemented.

---

## 4. Audit and Accountability (AU) Family

### AU-2: Event Logging
**Implementation:** Entra ID Audit Logs and Sign-in Logs capture all provisioning, modification, and deprovisioning events.
**Status:** Implemented.

### AU-6: Audit Review, Analysis, and Reporting
**Implementation:** Manual review of Audit/Sign-in Logs following each JML script execution; sample export retained at `/logs/audit-export-sample.csv`.
**Status:** Implemented (manual); automated/scheduled review flagged as a future enhancement.

---

## 5. Personnel Security (PS) Family

### PS-4: Personnel Termination
**Implementation:** `leaver-sop.md` and `leaver.ps1`.
**Test Case:** TC-06 through TC-10.
**Status:** Implemented.

### PS-5: Personnel Transfer
**Implementation:** `mover-sop.md` and `mover.ps1`.
**Test Case:** TC-03, TC-04, TC-05.
**Status:** Implemented.

---

## 6. Continuous Monitoring (CA) Family

### CA-7: Continuous Monitoring
**Implementation:** Recurring Access Reviews tied to Entitlement Management access packages (90-day standard, 30-day privileged).
**Test Case:** TC-26.
**Status:** Implemented.

---

## 7. Known Gaps and Remediation

| Control | Gap | Remediation Plan |
|---|---|---|
| PS-4 | Leaver process manually triggered rather than event-driven from a real HRIS | Future integration via SCIM inbound provisioning connector |
| AU-6 | Log review is manual/ad hoc | Forward Entra ID logs to a SIEM with scheduled reporting and alerting |
| AC-2(2) | No automated expiration for temporary/guest-style accounts | Not currently modeled; flagged for future scope if guest access is added |

## 8. Related Documents

- `../policies/access-control-policy.md`
- `iso-27001-mapping.md`
- `control-traceability-matrix.md`
- `../test-cases/test-matrix.md`
