# Control Traceability Matrix — Entra ID JML Lab

**Document Owner:** Entra-ID Lab Administrator
**Last Reviewed:** 2026-08-15
**Environment:** danotech.onmicrosoft.com

---

## 1. Account Lifecycle Controls

| Control ID | Control Name | NIST 800-53 | ISO 27001 | Implementation | Evidence | Test Case | Status |
|---|---|---|---|---|---|---|---|
| CTRL-01 | Account Provisioning | AC-2, AC-2(1) | A.5.16 | `joiner.ps1` (`New-MgUser`) | Entra admin center screenshot; Audit Log "Add user" | TC-01 | Implemented |
| CTRL-02 | Role-Based Group Assignment | AC-2(7) | A.5.15, A.5.16 | Assigned group add in `joiner.ps1` | Group membership screenshot | TC-01, TC-02 | Implemented |
| CTRL-03 | License Assignment on Provisioning | AC-2 | A.5.16 | `Set-MgUserLicense` in `joiner.ps1` | License tab screenshot | TC-02 | Implemented |
| CTRL-04 | Access Modification on Transfer | PS-5 | A.5.18 | `mover.ps1` | Before/after group membership screenshot | TC-03, TC-04 | Implemented |
| CTRL-05 | Dynamic Group Auto-Update | AC-2(7) | A.5.18 | Dynamic group rule on `Department` attribute | Group Members list before/after | TC-05 | Implemented |
| CTRL-06 | Account Disablement on Termination | AC-2(3), PS-4 | A.5.18, A.6.5 | `Update-MgUser -AccountEnabled:$false` | Audit Log "Update user" | TC-06 | Implemented |
| CTRL-07 | Group Membership Removal on Termination | AC-2 | A.5.18 | `leaver.ps1` | `Get-MgUserMemberOf` output | TC-06 | Implemented |
| CTRL-08 | Session/Token Revocation on Termination | AC-12, IA-5(13) | A.8.5 | `Revoke-MgUserSignInSession` | Sign-in log entry post-revocation | TC-08, TC-09 | Implemented |
| CTRL-09 | License Removal on Termination | AC-2 | A.5.18 | `Set-MgUserLicense -RemoveLicenses` in `leaver.ps1` | License tab showing none assigned | TC-10 | Implemented |

## 2. Access Enforcement Controls

| Control ID | Control Name | NIST 800-53 | ISO 27001 | Implementation | Evidence | Test Case | Status |
|---|---|---|---|---|---|---|---|
| CTRL-10 | Least Privilege Enforcement | AC-6 | A.5.18 | Role-based group assignment scoped to department | Group audit; test case result | TC-11 | Implemented |
| CTRL-11 | Privileged Access Structural Separation | AC-6(2), AC-6(5) | A.8.2 | Separate `SG-IT-Admins` group | Group list screenshot | N/A | Implemented |

## 3. Just-In-Time and Self-Service Access Controls

| Control ID | Control Name | NIST 800-53 | ISO 27001 | Implementation | Evidence | Test Case | Status |
|---|---|---|---|---|---|---|---|
| CTRL-12 | Just-In-Time Privileged Access | AC-6(1) | A.8.2 | PIM eligible role assignment | PIM role settings screenshot | TC-22, TC-23 | Implemented |
| CTRL-13 | Self-Service Access with Business-Owner Approval | AC-3 | A.5.15 | Entitlement Management access packages | Approval queue screenshot | TC-24, TC-25 | Implemented |
| CTRL-14 | Automatic Access Expiration | AC-6(7) | A.5.18 | Access package lifecycle expiration settings | Assignments tab screenshot | TC-26 | Implemented |
| CTRL-15 | Multi-Stage Approval for Privileged Access | AC-6(1), AC-6(5) | A.8.2 | Multi-stage approval on IT Admin access package | Multi-stage config screenshot | TC-27 | Implemented |

## 4. Governance and Recertification Controls

| Control ID | Control Name | NIST 800-53 | ISO 27001 | Implementation | Evidence | Test Case | Status |
|---|---|---|---|---|---|---|---|
| CTRL-16 | Periodic Access Review — Standard | AC-6(7), CA-7 | A.5.18, A.5.36 | 90-day recurring Access Review | Access Review results export | TC-26 | Implemented |
| CTRL-17 | Periodic Access Review — Privileged | AC-6(7), CA-7 | A.5.18, A.5.36 | 30-day recurring Access Review | Access Review results export | TC-26 | Implemented |

## 5. Audit and Monitoring Controls

| Control ID | Control Name | NIST 800-53 | ISO 27001 | Implementation | Evidence | Test Case | Status |
|---|---|---|---|---|---|---|---|
| CTRL-18 | Directory Audit Logging | AU-2 | A.8.15 | Entra ID Audit Logs | Audit log export CSV | TC-11, TC-12 | Implemented |
| CTRL-19 | Sign-In Monitoring | AU-6 | A.8.16 | Entra ID Sign-in Logs | Sign-in log screenshot | TC-06 | Implemented |
| CTRL-20 | Automation-to-Log Correlation | AU-6 | A.8.16 | Manual review of script output against Audit/Sign-in Logs | Comparison notes in test matrix | All | Implemented |

---

## 6. Summary Status

| Status | Count |
|---|---|
| Implemented | 20 |
| Partially Implemented | 0 |
| Out of Scope | 0 |

## 7. Related Documents

- `nist-800-53-mapping.md`
- `iso-27001-mapping.md`
- `../policies/access-control-policy.md`
- `../test-cases/test-matrix.md`
