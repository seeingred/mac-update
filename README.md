# mac-update

Personal script to keep a Mac up to date and cleaned up using only
Homebrew + App Store (+ macOS built-in updater) as sources of truth.

## Files

- [`update.sh`](update.sh) — the main update/cleanup runner
- [`.mac-update.skip`](.mac-update.skip) — casks/formulae to skip (blocked downloads, problematic upgrades)
- [`AUDIT.md`](AUDIT.md) — classification of every app in `/Applications` at migration time
- [`MIGRATION.md`](MIGRATION.md) — the one-off checklist used to move everything to brew

## Usage

```bash
./update.sh
```

Runs, in order: `brew update` → formulae → casks (incl. self-updating, per-cask timeout) →
App Store (`mas`) → macOS updates (list only) → `brew cleanup -s` → `brew autoremove` →
`mo clean` (interactive mole).

Continues on error. Prints an ✅ / ⏱ / ❌ summary at the end and exits non-zero if anything
failed or timed out.

## Environment knobs

| Variable | Default | Effect |
|---|---|---|
| `MAC_UPDATE_SKIP` | `./.mac-update.skip`, else `~/.mac-update.skip` | Path to skip list |
| `MAC_UPDATE_CASK_TIMEOUT` | `180` | Per-cask upgrade timeout in seconds |
| `MAC_UPDATE_NO_MOLE` | unset | Skip the `mo clean` step (for non-interactive runs) |
| `MAC_UPDATE_NO_GREEDY` | unset | Skip upgrading self-updating casks (Chrome, Raycast, etc.) |
| `MAC_UPDATE_NO_SKIP` | unset | Ignore the skip list and upgrade everything (e.g. when on VPN) |

## Prerequisites

- Homebrew
- `mas` (installed via `brew install mas`) — App Store upgrades
- `mole` (installed via `brew install mole`) — deep cleanup (optional, skip with `MAC_UPDATE_NO_MOLE=1`)
- Touch ID for `sudo` enabled — not required for `update.sh`, but handy if you run `sudo softwareupdate -i -a` afterwards

## Skip list format

```
# Comments start with #
tor-browser       # blocked without VPN
someflakycask     # takes forever to download
```

## Non-interactive / scheduled runs

For cron/launchd:

```bash
MAC_UPDATE_NO_MOLE=1 /path/to/mac-update/update.sh
```

mole's `mo clean` is interactive; skip it in non-interactive contexts and run manually.
