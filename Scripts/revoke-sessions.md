# revoke-sessions.ps1 — Session Revocation

**Policy:** [SOP-JML-03 Leaver §6](../policies/sop-jml-03-leaver.md) · **Test:** JML-17 in [test-matrix.md](../test-cases/test-matrix.md)

## Purpose

Invalidates a user's refresh tokens and browser session cookies so they must authenticate again. Used on its own for security incidents (suspected compromise, lost device) and after access changes. The leaver and mover scripts call the same Graph action internally.

## What revocation does and doesn't do

| Does | Doesn't |
|---|---|
| Invalidates refresh tokens, so no new access tokens without re-authentication | Kill access tokens already issued. They stay valid until expiry, typically 60–90 minutes |
| Clears browser session cookies for Entra sign-in | Disable the account. A user with valid credentials can sign in again |
| Forces the next token to reflect current group/app role state | Apply instantly to apps without Continuous Access Evaluation (CAE) |

So for a leaver, **disable first, then revoke**. Revocation alone isn't offboarding.

## Prerequisites

- Graph scopes (requested automatically): `User.Read.All`, `User.RevokeSessions.All`

## Usage

```powershell
./revoke-sessions.ps1 -UserPrincipalName jcruz@danotech.onmicrosoft.com -Reason "Lost laptop, ticket SEC-118"

# Multiple users from the pipeline
'kadeyemi@danotech.onmicrosoft.com','tbanks@danotech.onmicrosoft.com' |
    ./revoke-sessions.ps1 -Reason "Test JML-17"
```

## Verify

1. Sign in as the user in a browser before running the script, and leave the session open.
2. Run the script.
3. Refresh or open a new Microsoft app in the same session. Within the token lifetime you'll be asked to sign in again (immediately for CAE-aware apps such as Exchange Online and SharePoint).
4. **Audit logs** → Activity = `Invalidate all refresh tokens for user`.

## Screenshots

| ID | File | Must show |
|---|---|---|
| P1-17 | `screenshots/jml/revoke-sessions-output.png` | Script output with the reason |
| P1-18 | `screenshots/jml/audit-log-invalidate-tokens.png` | Audit log entry "Invalidate all refresh tokens for user" |
