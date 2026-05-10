#!/usr/bin/env bash
# mac-update — update + cleanup everything managed via brew / mas / macOS.
#
# Safe to re-run. Continues on error; prints a summary at the end.
#
# Environment knobs:
#   MAC_UPDATE_SKIP=/path/to/skiplist     Skip list file (default: ./.mac-update.skip next to this script,
#                                         falling back to ~/.mac-update.skip)
#   MAC_UPDATE_CASK_TIMEOUT=180           Per-cask upgrade timeout in seconds (default 180)
#   MAC_UPDATE_NO_MOLE=1                  Skip the mole deep-clean phase
#   MAC_UPDATE_NO_GREEDY=1                Skip upgrading self-updating casks (Chrome, Arc, Raycast, etc.)
#   MAC_UPDATE_NO_SKIP=1                  Ignore the skip list and upgrade everything (e.g. when on VPN)

set -uo pipefail

# ---------- colors ---------------------------------------------------------
if [[ -t 1 ]]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'
  BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; RESET=''
fi

log_info() { printf "%s[INFO]%s %s\n" "$BLUE"   "$RESET" "$*"; }
log_ok()   { printf "%s[ OK ]%s %s\n" "$GREEN"  "$RESET" "$*"; }
log_warn() { printf "%s[WARN]%s %s\n" "$YELLOW" "$RESET" "$*"; }
log_err()  { printf "%s[FAIL]%s %s\n" "$RED"    "$RESET" "$*"; }
log_hdr()  { printf "\n%s%s=== %s ===%s\n" "$BOLD" "$BLUE" "$*" "$RESET"; }

# ---------- skip list ------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKIP_FILE="${MAC_UPDATE_SKIP:-}"
if [[ -z "$SKIP_FILE" ]]; then
  if   [[ -f "$SCRIPT_DIR/.mac-update.skip" ]]; then SKIP_FILE="$SCRIPT_DIR/.mac-update.skip"
  elif [[ -f "$HOME/.mac-update.skip"       ]]; then SKIP_FILE="$HOME/.mac-update.skip"
  fi
fi

declare -a SKIP=()
if [[ -n "$SKIP_FILE" && -f "$SKIP_FILE" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"           # strip comments
    line="${line//[[:space:]]/}" # strip whitespace
    [[ -n "$line" ]] && SKIP+=("$line")
  done < "$SKIP_FILE"
  if [[ -n "${MAC_UPDATE_NO_SKIP:-}" ]]; then
    log_info "skip list: $SKIP_FILE (${#SKIP[@]} entries) — IGNORED (MAC_UPDATE_NO_SKIP set)"
  else
    log_info "skip list: $SKIP_FILE (${#SKIP[@]} entries)"
  fi
fi

is_skipped() {
  [[ -n "${MAC_UPDATE_NO_SKIP:-}" ]] && return 1
  local item="$1" s
  for s in "${SKIP[@]}"; do [[ "$s" == "$item" ]] && return 0; done
  return 1
}

CASK_TIMEOUT="${MAC_UPDATE_CASK_TIMEOUT:-180}"

# ---------- result tracking ------------------------------------------------
declare -a FAILED=() TIMEDOUT=() SKIPPED=() UPGRADED=()

# ---------- phase 1: metadata ---------------------------------------------
log_hdr "brew update (refresh metadata)"
if brew update; then
  log_ok "metadata refreshed"
else
  log_err "brew update returned non-zero"
fi

# ---------- phase 2: preflight — dangling symlinks -------------------------
log_hdr "preflight — dangling symlinks in bin dirs"
dangling=$(find -L /usr/local/bin /opt/homebrew/bin -maxdepth 1 -type l 2>/dev/null || true)
if [[ -z "$dangling" ]]; then
  log_ok "no dangling symlinks"
else
  log_warn "dangling symlinks found (may cause 'already a Binary at ...' errors on install):"
  printf '%s\n' "$dangling" | sed 's/^/    /'
  log_warn "remove with: sudo rm <path>"
fi

# ---------- phase 3: formulae ----------------------------------------------
log_hdr "brew formulae"
outdated_f=()
while IFS= read -r line; do
  [[ -n "$line" ]] && outdated_f+=("$line")
done < <(brew outdated --formula --quiet 2>/dev/null || true)
if [[ ${#outdated_f[@]} -eq 0 ]]; then
  log_ok "formulae up to date"
else
  for f in "${outdated_f[@]}"; do
    if is_skipped "$f"; then
      log_warn "skip formula: $f"
      SKIPPED+=("formula:$f")
      continue
    fi
    log_info "upgrade formula: $f"
    if brew upgrade --formula "$f"; then
      UPGRADED+=("formula:$f")
    else
      log_err "failed formula: $f"
      FAILED+=("formula:$f")
    fi
  done
fi

# ---------- phase 4: casks (with timeout, greedy for auto-updating) --------
log_hdr "brew casks"
greedy_flag=()
if [[ -z "${MAC_UPDATE_NO_GREEDY:-}" ]]; then
  greedy_flag=(--greedy-auto-updates)
  log_info "including self-updating casks (--greedy-auto-updates)"
fi

outdated_c=()
while IFS= read -r line; do
  [[ -n "$line" ]] && outdated_c+=("$line")
done < <(brew outdated --cask --quiet "${greedy_flag[@]}" 2>/dev/null || true)
if [[ ${#outdated_c[@]} -eq 0 ]]; then
  log_ok "casks up to date"
else
  for c in "${outdated_c[@]}"; do
    if is_skipped "$c"; then
      log_warn "skip cask: $c"
      SKIPPED+=("cask:$c")
      continue
    fi
    log_info "upgrade cask: $c (timeout ${CASK_TIMEOUT}s)"
    # run in background + kill on timeout so `timeout` isn't required (BSD /usr/bin/timeout doesn't exist on stock macOS)
    if command -v timeout >/dev/null 2>&1; then
      timeout "$CASK_TIMEOUT" brew upgrade --cask "$c"
      rc=$?
    else
      ( brew upgrade --cask "$c" ) & pid=$!
      ( sleep "$CASK_TIMEOUT"; kill -TERM "$pid" 2>/dev/null ) & watcher=$!
      wait "$pid" 2>/dev/null; rc=$?
      kill "$watcher" 2>/dev/null || true
      # rc will be 143 (128+SIGTERM) if we timed out
      [[ $rc -eq 143 ]] && rc=124
    fi
    case "$rc" in
      0)   log_ok "upgraded cask: $c"; UPGRADED+=("cask:$c") ;;
      124) log_warn "timeout: $c (consider adding to skip list)"; TIMEDOUT+=("cask:$c") ;;
      *)   log_err "failed cask: $c (exit $rc)"; FAILED+=("cask:$c") ;;
    esac
  done
fi

# ---------- phase 5: App Store --------------------------------------------
# mas-cli cannot update VPP/MDM-deployed apps (Hexnode etc.) — Apple's private
# StoreKit path doesn't accept the company VPP token, so each attempt fails with
# "No downloads initiated" and triggers a "you don't own this product" sheet.
# We detect them dynamically via Spotlight metadata: kMDItemAppStoreReceiptType
# is "ProductionVPP" for managed installs, "Production" for personal purchases.
log_hdr "App Store (mas)"
if command -v mas >/dev/null 2>&1; then
  # stdout = list of outdated apps (one per line); stderr = warnings/deprecations.
  # Only treat stdout as the source of truth — stderr noise must not trigger an upgrade.
  mas_err=$(mktemp)
  mas_out=$(mas outdated 2>"$mas_err") || true
  [[ -s "$mas_err" ]] && sed 's/^/    /' "$mas_err" >&2
  rm -f "$mas_err"
  if [[ -z "$mas_out" ]]; then
    log_ok "App Store apps up to date"
  else
    printf '%s\n' "$mas_out"
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      # mas outdated format:  "<id>  <name>  (<old> -> <new>)"
      id="${line%%[[:space:]]*}"
      [[ -z "$id" || ! "$id" =~ ^[0-9]+$ ]] && continue
      name=$(printf '%s' "$line" | sed -E "s/^${id}[[:space:]]+//; s/[[:space:]]+\([^)]+\)[[:space:]]*$//")

      bundle=$(mdfind "kMDItemAppStoreAdamID == $id" 2>/dev/null | head -n1)
      receipt_type=""
      if [[ -n "$bundle" && -d "$bundle" ]]; then
        receipt_type=$(mdls -raw -name kMDItemAppStoreReceiptType "$bundle" 2>/dev/null)
        [[ "$receipt_type" == "(null)" ]] && receipt_type=""
      fi

      if [[ "$receipt_type" == "ProductionVPP" ]]; then
        log_warn "skip mas (VPP/MDM-managed): $name [$id] — updated via MDM, not mas"
        SKIPPED+=("mas:$name")
        continue
      fi

      if is_skipped "mas:$id" || is_skipped "mas:$name"; then
        log_warn "skip mas: $name [$id]"
        SKIPPED+=("mas:$name")
        continue
      fi

      log_info "upgrade mas: $name [$id]"
      if mas upgrade "$id"; then
        log_ok "upgraded mas: $name"
        UPGRADED+=("mas:$name")
      else
        log_err "failed mas: $name [$id] — try updating via App Store.app"
        FAILED+=("mas:$name")
      fi
    done <<<"$mas_out"
  fi
else
  log_warn "mas not installed (brew install mas)"
fi

# ---------- phase 6: macOS system updates (list only) ---------------------
log_hdr "macOS system updates (list only)"
sw_out=$(softwareupdate -l 2>&1 || true)
if printf '%s' "$sw_out" | grep -q 'No new software available'; then
  log_ok "no macOS updates"
else
  # show the titles
  printf '%s\n' "$sw_out" | grep -E '^\s*(Title|Label|\*)' | sed 's/^/    /'
  log_warn "macOS updates available — run manually when ready:"
  log_warn "    sudo softwareupdate -i -a -R     # -R auto-reboots if required"
fi

# ---------- phase 7: cleanup ----------------------------------------------
log_hdr "cleanup"
log_info "brew cleanup -s (removes old versions + clears download cache)"
brew cleanup -s 2>&1 | tail -n 5 || true

log_info "brew autoremove (removes orphan dependencies)"
brew autoremove 2>&1 | tail -n 5 || true

if [[ -z "${MAC_UPDATE_NO_MOLE:-}" ]] && command -v mo >/dev/null 2>&1; then
  log_info "mo clean (interactive)"
  mo clean || log_warn "mo clean exited non-zero"
else
  if [[ -n "${MAC_UPDATE_NO_MOLE:-}" ]]; then
    log_info "mole skipped (MAC_UPDATE_NO_MOLE set)"
  else
    log_warn "mo (mole) not installed — brew install mole"
  fi
fi

# ---------- summary -------------------------------------------------------
log_hdr "summary"
[[ ${#UPGRADED[@]}  -gt 0 ]] && printf "%sUpgraded%s (%d): %s\n" "$GREEN"  "$RESET" "${#UPGRADED[@]}"  "${UPGRADED[*]}"
[[ ${#SKIPPED[@]}   -gt 0 ]] && printf "%sSkipped%s  (%d): %s\n" "$BLUE"   "$RESET" "${#SKIPPED[@]}"   "${SKIPPED[*]}"
[[ ${#TIMEDOUT[@]}  -gt 0 ]] && printf "%sTimeout%s  (%d): %s\n" "$YELLOW" "$RESET" "${#TIMEDOUT[@]}"  "${TIMEDOUT[*]}"
[[ ${#FAILED[@]}    -gt 0 ]] && printf "%sFailed%s   (%d): %s\n" "$RED"    "$RESET" "${#FAILED[@]}"    "${FAILED[*]}"

if [[ ${#FAILED[@]} -eq 0 && ${#TIMEDOUT[@]} -eq 0 ]]; then
  log_ok "all clean"
  exit 0
else
  exit 1
fi
