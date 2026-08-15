# ISO 27001:2022 Annex A Control Mapping — Entra ID JML Lab

**Document Owner:** Entra-ID Lab Administrator
**Last Reviewed:** 2026-08-15
**Environment:** danotech.onmicrosoft.com (standalone Entra ID, no on-prem/hybrid connection)
**Framework Reference:** ISO/IEC 27001:2022, Annex A

---

## 1. Purpose

Maps the controls implemented in this cloud-native Entra ID JML lab to ISO/IEC 27001:2022 Annex A, reflecting a SaaS-first identity model with no on-premises component.

---

## 2. Organizational Controls (Clause A.5)

### A.5.15: Access Control
**Implementation:** Role-based assigned and dynamic security groups govern access to tenant resources.
**Status:** Implemented.

### A.5.16: Identity Management
**Implementation:** Full identity lifecycle managed via `joiner.ps1`, `mover.ps1`, `leaver.ps1`.
**Test Case:** TC-01 through TC-10.
**Status:** Implemented.

### A.5.18: Access Rights
**Implementation:** Provisioning, modification, and removal of access rights governed by the JML scripts and Entitlement Management access packages; recurring Access Reviews provide recertification.
**Test Case:** TC-24 through TC-26.
**Status:** Implemented.

### A.5.36: Compliance with Policies, Rules, and Standards
**Implementation:** Control Traceability Matrix links each policy requirement to implementation evidence.
**Status:** Implemented.

---

## 3. People Controls (Clause A.6)

### A.6.5: Responsibilities After Termination or Change of Employment
**Implementation:** `leaver-sop.md` — account disablement, group removal, license removal, and session revocation upon termination.
**Test Case:** TC-06 through TC-09.
**Status:** Implemented.

---

## 4. Technological Controls (Clause A.8)

### A.8.2: Privileged Access Rights
**Implementation:** `SG-IT-Admins` structurally separated; entry gated by multi-stage-approval access package; activation gated by PIM.
**Evidence:** PIM configuration screenshot; multi-stage approval configuration screenshot.
**Test Case:** TC-22, TC-23, TC-27.
**Status:** Implemented.

### A.8.5: Secure Authentication
**Implementation:** MFA via Conditional Access; explicit session/token revocation on offboarding.
**Test Case:** TC-08, TC-09.
**Status:** Implemented.

### A.8.15: Logging
**Implementation:** Entra ID Audit Logs and Sign-in Logs.
**Status:** Implemented.

### A.8.16: Monitoring Activities
**Implementation:** Manual correlation of script execution against Audit/Sign-in Logs after each JML action.
**Status:** Implemented (manual); automated/continuous monitoring flagged as a future enhancement.

---

## 5. Known Gaps and Remediation

| Control | Gap | Remediation Plan |
|---|---|---|
| A.8.16 | Monitoring is manual rather than continuous | Forward logs to a SIEM with scheduled reporting |
| A.6.1 (Screening) | Out of scope — assumed precondition to joiner trigger | Documented, not a control failure |
| A.6.3 (Awareness Training) | Not modeled in this technical lab | Would accompany mover-sop.md in a production rollout |

## 6. Related Documents

- `../policies/access-control-policy.md`
- `nist-800-53-mapping.md`
- `control-traceability-matrix.md`
- `../test-cases/test-matrix.md`
