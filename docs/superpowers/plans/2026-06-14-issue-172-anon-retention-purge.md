# Implementation Plan: issue #172 — anonymous user retention policy (purge abandoned sessions)

**Branch:** `agent/issue-172-anon-retention-purge` (already created — execution starts at Task 1)
**Issue:** https://github.com/Maortz/allergy-detector/issues/172
**Area:** infra(db) — Supabase schema only. No Dart/Flutter code changes.

## Goal

Add a scheduled database job that purges abandoned anonymous `auth.users` rows so the
table does not grow unboundedly. An "abandoned anonymous user" is one that signed in
anonymously, never upgraded to a real (email/OAuth) account, and is older than a
configurable TTL (default 30 days).

## Critical context (read before editing)

- `supabase/schema.sql` (264 lines) is the canonical full-database script applied via the
  Supabase SQL Editor. `supabase/migrations/20260101000000_initial_schema.sql` (191 lines)
  mirrors the same DDL for `supabase start`. **Both must be updated identically**, the way
  PR #162 did (it touched both files).
- The auth section already defines:
  - `profiles.id uuid primary key references auth.users(id) on delete cascade`
  - A trigger `on_auth_user_created` running `public.handle_new_user()` that auto-inserts a
    `public.profiles` row for **every** new `auth.users` row, including anonymous sign-ins.
- **Design correction vs. the issue text:** the issue suggests purging anon users with "no
  corresponding row in `public.profiles`". That predicate is unreachable here — the
  auto-provision trigger guarantees every anon user already has a profile row. The real
  "never upgraded" signal is `auth.users.is_anonymous = true` (it flips to `false` when a
  guest upgrades to email/OTP in place, retaining the same id). So the purge predicate is
  `is_anonymous = true AND created_at < now() - <ttl>`. Deleting the auth user
  cascade-deletes its `profiles` (and `favorites`/`reviews`) rows via the existing FKs.
- There are **no SQL tests** in the repo; SQL is pure DDL with no Dart coverage. PR #162
  added no test for its schema. The `flutter analyze`/`flutter test` DoD items exist only to
  prove the Dart app still builds — we are not touching Dart, so they should pass unchanged.
- `pg_cron` schedules jobs in the `cron` schema. On Supabase it is enabled with
  `create extension if not exists pg_cron;`. The schema script already uses the
  `create extension if not exists "uuid-ossp";` idiom at the top.

## Design

1. **Function** `public.purge_abandoned_anonymous_users(retention interval default '30 days')`
   - `language sql`, `security definer`, `set search_path = ''` (matches existing
     `handle_new_user` hardening).
   - Deletes from `auth.users` where `is_anonymous = true` and
     `created_at < now() - retention`. Returns the count of deleted rows (`returns bigint`)
     so it can be invoked ad-hoc and inspected.
   - TTL is a function parameter → configurable per the DoD; the default value (`'30 days'`)
     is the single place to change the retention window.
2. **Schedule** via `pg_cron`: a daily job at 03:30 UTC named `purge-abandoned-anonymous-users`
   calling the function with its default TTL. Guard the `cron.schedule` call so re-running the
   script (or running where `pg_cron` is unavailable, e.g. a bare local Postgres) does not abort
   the whole script: wrap the extension + schedule in a `do $$ ... $$` block that no-ops with a
   notice if the `cron` schema is absent, and unschedule any prior job of the same name first to
   stay idempotent.
3. Place the new block at the **end** of both files, after the `profiles_guard_is_admin`
   trigger, under a clearly-commented section header referencing issue #172.

## Tasks

### Task 1 — Append the retention-purge block to `supabase/schema.sql`

Append the following block to the end of `supabase/schema.sql` (after the final
`profiles_guard_is_admin` trigger, line 264):

```sql

-- ---------------------------------------------------------------------------
-- Anonymous user retention policy (issue #172).
--
-- Anonymous sign-ins (AuthService.ensureSession on cold start) accumulate in
-- auth.users. A guest that upgrades to email/OTP keeps the same id but flips
-- is_anonymous -> false, so `is_anonymous = true` is the durable "never
-- upgraded" signal. (The on_auth_user_created trigger gives every anon user a
-- profiles row, so "no profile row" can't identify abandonment.) Deleting the
-- auth user cascade-removes its profiles/favorites/reviews rows via their FKs.
--
-- Retention TTL is the function's `retention` argument (default 30 days) — the
-- single knob to change the window. The pg_cron job runs the purge daily.
-- ---------------------------------------------------------------------------
create or replace function public.purge_abandoned_anonymous_users(
  retention interval default '30 days'
)
returns bigint
language sql
security definer set search_path = ''
as $$
  with deleted as (
    delete from auth.users
    where is_anonymous = true
      and created_at < now() - retention
    returning 1
  )
  select count(*) from deleted;
$$;

-- Schedule the daily purge with pg_cron. Wrapped so the script still applies
-- on a Postgres without pg_cron (e.g. a bare local instance): it logs a notice
-- and skips scheduling instead of aborting. Idempotent — unschedules any prior
-- job of the same name before (re)creating it.
do $$
begin
  create extension if not exists pg_cron;

  if exists (
    select 1 from cron.job where jobname = 'purge-abandoned-anonymous-users'
  ) then
    perform cron.unschedule('purge-abandoned-anonymous-users');
  end if;

  perform cron.schedule(
    'purge-abandoned-anonymous-users',
    '30 3 * * *',
    $cron$ select public.purge_abandoned_anonymous_users(); $cron$
  );
exception
  when undefined_file or insufficient_privilege or feature_not_supported then
    raise notice 'pg_cron unavailable — skipping purge schedule; run public.purge_abandoned_anonymous_users() via an external scheduler';
  when invalid_schema_name or undefined_table then
    raise notice 'cron schema unavailable — skipping purge schedule';
end;
$$;
```

Verify the block was appended exactly once and the file still ends cleanly.

### Task 2 — Mirror the identical block into the migration

Append the **same** block (byte-for-byte identical to Task 1's SQL) to the end of
`supabase/migrations/20260101000000_initial_schema.sql`, after its final
`profiles_guard_is_admin` trigger (line 191). The migration must stay a faithful mirror of
`schema.sql`'s auth section, as PR #162 established.

### Task 3 — Verify Dart app is unaffected

Run from `app/`, one command at a time (no `&&` chaining), with flutter on PATH
(`export PATH="$PATH:/sdks/flutter/bin"`):

1. `flutter pub get` — succeeds.
2. `flutter analyze lib test` — 0 issues. (No Dart files changed; this is a regression guard.)
3. `flutter test` — all green.

If analyze or test regress, the cause is environmental, not this change (no Dart was
touched) — investigate before proceeding; do not edit Dart to chase a pre-existing failure.

### Task 4 — A6 spec-table update — N/A

`docs/superpowers/specs/2026-05-19-stitch-screens/index.md` tracks **screen** implementations.
This is a DB-only change touching no screen, so there is no row to update. Skip A6 explicitly.

### Task 5 — A7 drift check

```
git fetch origin
git log origin/master..HEAD --oneline
```

Only the commits from this branch should appear. Any foreign commit → STOP (`STOPPED drift`).

### Task 6 — A8 commit + PR

Stage the two SQL files plus this plan file. Commit:

```
git add supabase/schema.sql supabase/migrations/20260101000000_initial_schema.sql docs/superpowers/plans/2026-06-14-issue-172-anon-retention-purge.md
git commit -m "<message>"
```

Commit message:

```
infra(db): purge abandoned anonymous auth users on a TTL (#172)

Add public.purge_abandoned_anonymous_users(retention interval default
'30 days') and a daily pg_cron job that deletes anonymous auth.users
older than the TTL that never upgraded (is_anonymous = true). Cascade
FKs clean up their profiles/favorites/reviews rows. The schedule block
degrades gracefully where pg_cron is unavailable. Mirrored into both
schema.sql and the initial migration.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

Push and open the PR against master:

```
git push -u origin agent/issue-172-anon-retention-purge
gh pr create --repo Maortz/allergy-detector --base master --title "infra(db): anonymous user retention policy — purge abandoned sessions (#172)" --body "<body>"
```

PR body must include: `Closes #172`, a change summary, the design-correction note
(why `is_anonymous` not "no profile row"), TTL configurability, the graceful-degradation
note, and the `flutter analyze` / `flutter test` results.

### Task 7 — A9 comment on issue + release claim

```
gh issue comment 172 --repo Maortz/allergy-detector --body "Opened PR <url> — <one-line summary>."
gh issue edit 172 --repo Maortz/allergy-detector --remove-label agent-in-progress
```
