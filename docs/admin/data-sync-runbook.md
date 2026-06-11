# Admin data sync — runbook

The catalog/data scripts under `scripts/` are run automatically by the
**Admin data sync** GitHub Actions workflow (`.github/workflows/admin-sync.yml`),
so routine upkeep no longer needs a maintainer to run them by hand (issue #82).

## What it does

| Step | Script | When |
|---|---|---|
| Admin sync | `scripts/admin-sync.dart` | Every run (scheduled + manual) |
| OpenFoodFacts import | `scripts/import-openfoodfacts.dart` | Manual runs only, when a `barcode` input is given |

The workflow wraps the **existing** scripts unchanged — it only materialises the
credential files they expect (`scripts/.env` for `admin-sync.dart`,
`scripts/env.local.json` for `import-openfoodfacts.dart`) from repo secrets at
runtime, then scrubs them afterwards.

## Schedule

- **Cron:** daily at `04:17 UTC` (runs `admin-sync.dart` only).
- **On demand:** Actions → *Admin data sync* → **Run workflow**.

## How to trigger a manual run

1. GitHub → **Actions** → **Admin data sync** → **Run workflow**.
2. Optional inputs:
   - `barcode` — an OpenFoodFacts barcode to import. Leave blank to run the
     sync only.
   - `dry_run` — defaults to **true** (no DB writes). Untick to actually write
     the imported product.

From the CLI:

```bash
# sync only
gh workflow run admin-sync.yml

# dry-run import of a barcode
gh workflow run admin-sync.yml -f barcode=7290000000001

# real import (writes to Supabase)
gh workflow run admin-sync.yml -f barcode=7290000000001 -f dry_run=false
```

## Required repo secrets

Configure under **Settings → Secrets and variables → Actions**:

| Secret | Used by | Notes |
|---|---|---|
| `SUPABASE_URL` | both scripts | Project REST URL |
| `SUPABASE_PUBLIC_API_KEY` | `admin-sync.dart` | anon/public key |
| `SUPABASE_KEY` | `import-openfoodfacts.dart` | falls back to `SUPABASE_PUBLIC_API_KEY` if unset |

The workflow fails fast with a clear error if `SUPABASE_URL` is missing.

## Failure handling

The workflow is intentionally **separate from `ci.yml` and not a required
check** — a sync failure (transient Supabase / OpenFoodFacts outage, bad
barcode) surfaces as a failed *Admin data sync* run but **does not block PR
merges**. Re-run it from the Actions tab once the underlying issue clears.
