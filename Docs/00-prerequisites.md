# Phase 00 — Tenant setup

**Goal:** a hardened, empty tenant with two emergency access accounts and working tooling, verified by a read-only script.

| | |
|---|---|
| Builds on | — |
| Feeds into | Every later phase |
| Time | About 1–2 hours |
| Changes made | Tenant settings, 2 emergency accounts, 4 outside accounts. No employees yet (that's Phase 01). |

> Portal menu names in the Entra admin center (https://entra.microsoft.com) shift over time. If a path below doesn't match, search the setting name in the portal's search bar.

---

## Before you start — the setup account

You are signed in as `daniel.opara@danotechinc.onmicrosoft.com`, the account that created the tenant. It is also the CEO (DNT10001) in the HR feed and holds Global Administrator.

That combination is a known anti-pattern, accepted for now and logged as finding **F-001**:

- Register a phishing-resistant method (passkey) on `daniel.opara` today; admin portals already require MFA.
- Create the emergency accounts (Step 2) **before** changing anything else, so a mistake on `daniel.opara` can't lock you out.
- Phase 06 creates `adm-daniel.opara` with PIM-eligible roles and removes standing Global Administrator from `daniel.opara`.

## Step 1 — Confirm the license

1. Open the Entra admin center and go to **Billing > Licenses > All products**.
2. Note the **Microsoft Entra ID P2** seat count and expiry date.
3. Record both in [Evidence](#evidence) below.

**Why it matters:** Microsoft's P1/P2 trials last 30 days. When a trial expires, PIM features stop working, so phases 05–11 need to land inside the license window or on paid seats. If seats are fewer than 200, Phase 01 licenses a subset through `GRP-LIC-EntraIDP2`.

📸 `screenshots/00-01-licenses.png` — license blade showing P2 seats and expiry.

## Step 2 — Create two emergency access accounts

Emergency (break-glass) accounts keep you from being locked out if Conditional Access or MFA breaks. Microsoft recommends two, cloud-only, and they are now subject to mandatory MFA for admin portals.

For each of `bg-emergency01` and `bg-emergency02`:

1. **Users > All users > New user > Create new user.**
2. UPN: `bg-emergency01@danotechinc.onmicrosoft.com`. Display name: `Emergency Access 01`.
3. Set a long random password (25+ characters). Store it **offline**, never in the repo.
4. **Assignments:** add the **Global Administrator** role (permanent, not PIM-eligible).
5. Register a **phishing-resistant method**:
   - Enable **Passkey (FIDO2)** under **Authentication methods > Policies**, targeted at these two accounts.
   - Sign in as each account and register a FIDO2 security key or a passkey in Microsoft Authenticator.
   - Use a different key/device for each account.
6. Create a group `GRP-CA-Excl-EmergencyAccess` (security, assigned) and add both accounts. Phase 05 excludes this group from every Conditional Access policy.

📸 `00-02-emergency-accounts.png` — both accounts, Global Administrator role.
📸 `00-03-emergency-auth-methods.png` — passkey registered (blur any serial numbers).

## Step 3 — Harden tenant defaults

| Setting | Where | Value | Why |
|---|---|---|---|
| Users can register applications | Users > User settings | **No** | Every app registration is owned and deliberate (Phase 08) |
| Restrict non-admin users from creating tenants | Users > User settings | **Yes** | Stops shadow tenants |
| Restrict access to Microsoft Entra admin center | Users > User settings | **Yes** | Least privilege for 200 standard users |
| User consent for applications | Enterprise apps > Consent and permissions | **Do not allow user consent** | Blocks consent phishing; admins approve apps |
| Guest invite restrictions | External Identities > External collaboration settings | **Only admins and users in the Guest Inviter role** | Controls B2B sprawl |

📸 `00-04-user-settings.png`, `00-05-consent-settings.png`

## Step 4 — Leave security defaults ON

**Overview > Properties > Manage security defaults** should show **Enabled**. They protect the tenant until Phase 05 replaces them with Conditional Access (you can't run both).

## Step 5 — Install tooling

```powershell
# PowerShell 7+ required: https://aka.ms/powershell
Install-Module Microsoft.Graph -Scope CurrentUser
# Git, VS Code, and Azure CLI (needed from Phase 07)
winget install Git.Git Microsoft.VisualStudioCode Microsoft.AzureCLI
```

On macOS use `brew install git azure-cli` and install VS Code from its website.

## Step 6 — Run the prerequisite check

```powershell
cd phases/00-tenant-setup
./Test-LabPrerequisites.ps1
```

The script signs in to Microsoft Graph with **read-only** scopes (`Organization.Read.All`, `User.Read.All`, `Policy.Read.All`, `RoleManagement.Read.Directory`), runs every check below, and exits non-zero if anything fails. It changes nothing.

| Check | Expected |
|---|---|
| PowerShell version | 7 or later |
| Graph modules installed | PASS |
| Git / Azure CLI on PATH | PASS (Azure CLI is WARN until Phase 07) |
| Tenant domain matches config | `danotechinc.onmicrosoft.com` |
| P2 SKU present | `AAD_PREMIUM_P2` with seats available |
| Emergency accounts | 2 found, both Global Administrator |
| User count | 3 (`daniel.opara` + 2 emergency accounts) |
| Security defaults | Enabled |
| Users can register apps | Disabled |
| User consent | Disabled |

📸 `00-06-prereq-script.png` — full script output, all PASS.


## Step 7 — Sign up for the outside accounts

Create these now so they're ready when later phases need them. Use a dedicated lab email, never a work account.

| Account | Sign up | Notes |
|---|---|---|
| Salesforce Developer Edition | developer.salesforce.com/signup | Free, includes System Administrator access and a handful of Salesforce licenses for test users. Record the My Domain URL (`https://<name>.develop.my.salesforce.com`). |
| Okta Integrator Free Plan | developer.okta.com/signup | Replaced Okta Developer Edition in 2025. Needs a unique business-style email per org, and the org deactivates after 180 days with no sign-ins, so sign in occasionally. Record the org URL. |
| Azure subscription | azure.microsoft.com/free | Sign up with an account in `danotechinc.onmicrosoft.com` so the subscription trusts this tenant. Set a budget alert. |
| GitHub | github.com/signup | Create the repo `danotechinc-entra-iam-lab` and push this skeleton. |

Record only the URLs in Evidence. **Never** commit passwords, API tokens, or certificates for these accounts.

📸 `00-07-salesforce-org.png`, `00-08-okta-org.png` — the admin home page of each, URL visible.

---

## Evidence

| Item | Value |
|---|---|
| Date completed | |
| P2 seats / expiry | |
| Emergency accounts created | ☐ bg-emergency01 ☐ bg-emergency02 |
| Phishing-resistant methods registered | ☐ ☐ |
| Prerequisite script all PASS | ☐ |
| Salesforce My Domain URL | |
| Okta org URL | |
| Azure subscription created | ☐ |
| GitHub repo URL | |

## Definition of done

- [ ] License seats and expiry recorded
- [ ] Two emergency accounts with Global Administrator and phishing-resistant MFA
- [ ] `GRP-CA-Excl-EmergencyAccess` created
- [ ] Tenant defaults hardened (table in Step 3)
- [ ] Tooling installed
- [ ] `Test-LabPrerequisites.ps1` passes
- [ ] Salesforce, Okta, Azure, and GitHub accounts created
- [ ] Eight screenshots saved in `screenshots/`
- [ ] Medium article for Phase 00 published and linked here

## Next

[Phase 01 — JML lifecycle automation](../01-jml-lifecycle/)
