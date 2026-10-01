# Account, backup & offline — test plan

Run on a real phone with debug logs on (`[Backend]` and `[Purchases]` lines).
Use two Google accounts: **A** and **B**. Tick each one.

## Sign in / sign out

| # | Steps | Expected |
|---|---|---|
| 1 | Fresh install → onboarding → "Not now" → log a dose | Guest data on phone. Me shows "Back up with Google". No upload. |
| 2 | From 1: Me → sign in with **A** (A has no backup) | Phone data becomes A's. Backup runs. Me shows A's email. |
| 3 | From 2: Me → Sign out (online) | Sheet "Everything is backed up to A". Sign out → phone cleared → Welcome. |
| 4 | Welcome → "I already have an account" → **A** | A's backup restored → Today shows the dose from 1. |
| 5 | From 4: sign out, then Welcome → sign in **B** (no backup) | "No backup yet" → onboarding. **None of A's data visible.** |
| 6 | Finish onboarding as B, log something, wait 20 s | B's backup created. Supabase `backups` has 2 rows (A and B), each with its own data. |
| 7 | Sign out B → sign in A | A's data only. |
| 8 | Guest phone with data → Me → sign in **A** (A has a backup) | "Backup found" sheet: Restore → A's data replaces phone. Keep this phone → phone data replaces A's backup. Close the sheet → signed out, nothing changed. |
| 9 | Onboarding Save step → sign in **A** (has backup) | Restore → home with A's data. Start fresh → new plan, replaces A's backup after 20 s. Close → stays on Save, signed out. |

## Offline

| # | Steps | Expected |
|---|---|---|
| 10 | Signed in, airplane mode → log dose, edit, delete things | Everything works instantly. Me shows "Changes waiting to back up". No popups. |
| 11 | From 10: turn internet back on | Backup runs by itself within seconds. Me shows "Backed up today, …". |
| 12 | From 10 (still offline): Me → Sign out | Red sheet "latest changes couldn't be backed up". Stay signed in keeps everything. Sign out anyway clears the phone. |
| 13 | Offline: Welcome → sign in, or Me → Restore, or Delete my account | "You're offline" sheet. Nothing changes. |
| 14 | Offline when signing in (Google works, Supabase check fails) | "You're offline" sheet, signed out again. **No new plan created over a real backup.** |
| 15 | Kill the app while offline with changes, reopen online | Backup runs at start ("pending" is remembered). |

## Delete

| # | Steps | Expected |
|---|---|---|
| 16 | Signed in A → Me → Delete my account | Sheet says account, backup and phone data are deleted. → Welcome. Supabase: A's user and backup row gone. |
| 17 | From 16: sign in with A again | New empty account → onboarding. |
| 18 | Signed in → Me → Delete all | Sheet says you'll be signed out and the cloud backup stays. → Welcome. Sign in again → backup restorable. |
| 19 | Guest → Delete all | Phone cleared → Welcome. |
| 20 | After any delete / sign out | Free week does **not** restart (dates kept). |

## Purchases (RevenueCat Test Store)

| # | Steps | Expected |
|---|---|---|
| 21 | Signed in A → buy Plus → sign out → sign in B | B is **not** Plus. |
| 22 | Sign out B → sign in A | A is Plus again. |
| 23 | Guest buys Plus, then signs in A | Plus moves to A (RevenueCat transfers the anonymous purchase). |
