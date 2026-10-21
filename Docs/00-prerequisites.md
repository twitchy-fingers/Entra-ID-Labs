# Phase 0 — Prerequisites and Tenant Setup

Complete every step here before running any script. Each step ends with a check so you know it worked.

## 1. Lab tenant

Use a dedicated lab tenant (`danotech.onmicrosoft.com`), never a production tenant. Sign in to the [Microsoft Entra admin center](https://entra.microsoft.com) with an account that holds **Global Administrator** for initial setup.

**Check:** Entra admin center → **Overview** shows the tenant name and primary domain `danotech.onmicrosoft.com`.

## 2. Activate Entra ID P2 (or Entra ID Governance)

PIM, access reviews, and entitlement management require P2 or Governance licensing. Group assignment to enterprise apps requires at least P1.

1. Entra admin center → **Billing** → **Licenses** → **All products** (if you have no trial yet, use **Try / Buy** to start a Microsoft Entra ID P2 trial).
2. Confirm the product shows available licenses.

> Portal navigation labels change periodically. If a path below doesn't match, search the admin center for the blade name.

**Check:** run this after step 4 and note the exact `SkuPartNumber` — you'll put it in the config file:

```powershell
Get-MgSubscribedSku | Select-Object SkuPartNumber, ConsumedUnits, @{N='Enabled';E={$_.PrepaidUnits.Enabled}}
```

The standalone P2 SKU is usually `AAD_PREMIUM_P2`. Trials and bundles use different values, so always use what your tenant reports.

📸 **Screenshot P0-01** → `screenshots/setup/p2-license-active.png`
Licenses → All products, showing the P2 / Governance product with its license count.

## 3. Emergency access (break-glass) account

Before you build any access policies, create one cloud-only emergency access account (in this tenant: `breakglass@DanoTech.onmicrosoft.com`) with Global Administrator, a long random password stored offline, and exclusion from any Conditional Access policies you create later. This is standard practice and prevents locking yourself out of the lab.

**Check:** the account exists and you've stored its credentials outside the repo.

## 4. Admin workstation

| Tool | Version | Install |
|---|---|---|
| PowerShell | 7.4+ | <https://aka.ms/powershell> |
| Microsoft Graph PowerShell SDK | 2.x | `Install-Module Microsoft.Graph -Scope CurrentUser` |
| Az PowerShell (Phase 8) | latest | `Install-Module Az -Scope CurrentUser` |
| Git | any | <https://git-scm.com> |
| VS Code (recommended) | any | <https://code.visualstudio.com> |

Tooling and accounts for later phases (test app, Salesforce, Okta, Azure subscription) are listed in section 7 below.

**Check:**

```powershell
$PSVersionTable.PSVersion          # 7.4 or later
Get-Module Microsoft.Graph -ListAvailable | Select-Object Name, Version
```

## 5. First Graph connection and consent

```powershell
Connect-MgGraph -TenantId danotech.onmicrosoft.com -Scopes "User.ReadWrite.All","Group.ReadWrite.All","Organization.Read.All"
Get-MgContext | Select-Object Account, TenantId, Scopes
```

The first connection prompts you to consent for **Microsoft Graph Command Line Tools**. Consent on behalf of the organization so later scripts don't prompt each time. Each script requests only the scopes it needs.

📸 **Screenshot P0-02** → `screenshots/setup/graph-connect-context.png`
Terminal output of `Get-MgContext` showing the account and granted scopes. Blur the TenantId if you prefer.

## 6. Configure the repo

1. Clone or create the repo and copy these files in.
2. Edit `config/jml-config.json`:
   - `tenantDomain` → your tenant's domain
   - `licenseSkuPartNumber` → the value from step 2 (or `""` to skip license assignment)
   - `upnFormat` → `firstInitialLastName` (Danotech's convention, e.g. `acoleman`) or `firstDotLast`
3. Commit:
   ```bash
   git add .
   git commit -m "Phase 0: repo scaffold, config, prerequisites"
   ```

**Check:** `Get-Content config/jml-config.json | ConvertFrom-Json` parses without errors.

## 7. Accounts and tools for later phases

You don't need these yet, but sign-ups can take a day to activate, so it's worth starting early. All are free.

| Needed in | What | Notes |
|---|---|---|
| Phase 4 | Test app runtime (language confirmed in Phase 4) | A small web app that signs users in and reads their role claim |
| Phase 5 | Salesforce Developer Edition org | SAML service provider; Entra ID is the identity provider |
| Phase 5 | Okta developer / free integrator org | Second federation partner; trusts Entra ID as its identity provider |
| Phase 5 | SAML-tracer browser extension | Captures and decodes SAML assertions for troubleshooting |
| Phase 6 | Microsoft Authenticator app; optional FIDO2 security key | MFA enrollment and phishing-resistant methods |
| Phase 7 | Azure subscription (free account) with Key Vault | Privileged credential vault |
| Phase 8 | Same Azure subscription | Custom Azure RBAC roles and policy testing |
| Phase 9 | GitHub (this repo) with Actions enabled | Workload identity federation: the JML scripts run from GitHub Actions with no stored secret |
| Phase 9 (optional) | Workload Identities Premium trial | Only needed for Conditional Access on service principals |
| Phase 10 | Python 3.11+ | Runs the sample AI agent and the protected tool API |

Use a separate email address or alias for each external sign-up so nothing is tied to a personal or work account.

## 8. Already have users in the tenant? Reset before Phase 1

The lab assumes Phase 1 starts with an empty directory, so the joiner creates every person from the HR feed. If you created test users earlier, remove them first. Otherwise the joiner can't match them (they have no `employeeId`) and will create second copies with a `2` in the UPN.

**Never delete:** your own admin account, the break-glass account, or any account you didn't create for the lab.

1. Preview the accounts that would be removed. Edit `$protect` to list every account you're keeping:
   ```powershell
   Connect-MgGraph -Scopes "User.ReadWrite.All"
   $protect = @(
       'dopara@DanoTech.onmicrosoft.com',      # lab administrator
       'breakglass@DanoTech.onmicrosoft.com'   # emergency access
   )
   $toRemove = Get-MgUser -All -Property Id,UserPrincipalName,UserType |
       Where-Object { $_.UserType -eq 'Member' -and $_.UserPrincipalName -notin $protect }
   $toRemove | Select-Object UserPrincipalName
   ```
2. Read the list carefully. Only continue if every account on it is a lab test user.
3. Delete them, then purge them from the recycle bin so their UPNs can be reused:
   ```powershell
   $toRemove | ForEach-Object { Remove-MgUser -UserId $_.Id }
   Get-MgDirectoryDeletedItemAsUser -All | ForEach-Object { Remove-MgDirectoryDeletedItem -DirectoryObjectId $_.Id }
   ```
   Deleted users keep their UPN reserved for 30 days unless purged, which would make the joiner fall back to `kadeyemi2@...`.

For the Danotech tenant, step 1 should list **209** accounts (the export's 211 minus the two protected ones). If the number is different, stop and find out why before deleting anything.

> Deleting and recreating gives every user a new object ID. Anything you configured against the old accounts (group memberships, app assignments, role assignments) is lost. That's intended here: the lab rebuilds all of it, phase by phase.

**Check:** `Get-MgUser -All | Select-Object UserPrincipalName` lists only your protected accounts.

## Next

Phase 1: run the joiner — see [scripts/joiner.md](../scripts/joiner.md).
