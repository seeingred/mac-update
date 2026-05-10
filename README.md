# mac-update

Personal script to keep a Mac up to date and cleaned up using only
Homebrew + App Store (+ macOS built-in updater) as sources of truth.

## Files

- [`update.sh`](update.sh) — the main update/cleanup runner
- [`.mac-update.skip`](.mac-update.skip) — casks/formulae to skip (blocked downloads, problematic upgrades)

## Usage

```bash
./update.sh
```

Runs, in order: self-update → `brew update` → formulae → casks (incl. self-updating,
per-cask timeout) → App Store (`mas`) → macOS updates (list only) → `brew cleanup -s` →
`brew autoremove` → `mo clean` (interactive mole).

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
| `MAC_UPDATE_NO_SELFUPDATE` | unset | Skip the self-update phase |
| `MAC_UPDATE_SELFUPDATE_URL` | GitHub raw `main` | Override the URL fetched for standalone self-update |

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
mas:310633997     # mas app by ADAM ID (e.g. WhatsApp)
mas:WhatsApp      # mas app by name (matches `mas outdated` second column)
```

## App Store apps & MDM (VPP)

`mas-cli` cannot update apps deployed via Apple Business Manager VPP (Hexnode,
Jamf, Kandji, etc.) — the private StoreKit endpoint it uses doesn't accept the
company VPP token, so each attempt fails with `No downloads initiated for ADAM
ID …` and pops a misleading "you don't own this product" sheet.

The script detects these dynamically by reading
`kMDItemAppStoreReceiptType` from each outdated app's bundle: `ProductionVPP`
means MDM-deployed (auto-skipped — your MDM ships updates), `Production` means
personal purchase (upgraded normally). No list to maintain.

## Self-update

On every run the script first updates itself:

- **Inside a git checkout:** `git pull --ff-only` on the current branch. Skipped if
  the working copy of `update.sh` has uncommitted changes, the branch is detached,
  or the pull isn't a fast-forward.
- **Standalone (single-file install):** downloads the raw script from GitHub,
  syntax-checks it with `bash -n`, atomic-replaces, and re-executes.

Disable with `MAC_UPDATE_NO_SELFUPDATE=1`. Re-exec is guarded by
`MAC_UPDATE_SELFUPDATE_RAN` so a freshly pulled script can't loop.

## Non-interactive / scheduled runs

For cron/launchd:

```bash
MAC_UPDATE_NO_MOLE=1 /path/to/mac-update/update.sh
```

mole's `mo clean` is interactive; skip it in non-interactive contexts and run manually.
