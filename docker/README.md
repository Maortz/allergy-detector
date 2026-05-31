# Dockerized Claude Code (dangerous mode)

Run Claude Code inside a container so `--dangerously-skip-permissions` only has
access to this repo + the container — not your whole machine.

## Build (once)

```powershell
cd docker
docker compose build
```

## Run Claude in dangerous mode

```powershell
cd docker
docker compose run --rm claude claude --dangerously-skip-permissions
```

First run: log in (browser OAuth, or set `ANTHROPIC_API_KEY` to skip).
The login persists in the `claude-config` volume across runs.

## Just get a shell

```powershell
docker compose run --rm claude
```

Then inside: `cd app && flutter pub get && flutter test`.

## GitHub auth (git push/pull inside container)

The container reads `GH_TOKEN` from `docker/.env` (gitignored) and injects a git
credential helper at runtime, so HTTPS `git push`/`pull` to github.com just works.

Create / refresh the token from your host's `gh` login (no manual paste):

```powershell
# from repo root; requires `gh auth login` done on the host
"GH_TOKEN=$(gh auth token)" | Set-Content -NoNewline -Encoding ascii docker/.env
```

Re-run that whenever the PAT rotates or expires. Copy `.env.example` → `.env` if
you prefer to fill it in by hand. Never commit `.env`.

## Bundled tools

Baked into the image: `git`, `gh`, `ripgrep` (rg), `fd`, `jq`, `yq`, `rtk`, plus
Flutter/Dart/Node. Claude plugins (caveman, token-optimizer, superpowers) and the
`rtk` PreToolUse hook are seeded into `~/.claude/settings.json` by the entrypoint
on first start, then auto-install on the first `claude` launch. To change the set,
edit `claude-settings.seed.json` and rebuild.

## Notes

- Repo is mounted at `/workspace` read-write — edits inside the container appear
  on your host immediately (same files).
- Claude login persists in the `claude-config` volume — no re-login per run.
- Runs as non-root user `dev` (Claude refuses dangerous mode as root).
- `pub-cache` / `gradle-cache` volumes survive rebuilds, so deps don't re-download.
- No Android emulator / device — this image builds APKs and runs tests/analyze.
  Web run: `flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0`
  (add `ports: ["8080:8080"]` to the compose service to reach it from host).
