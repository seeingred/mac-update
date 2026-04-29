# Migration Checklist

For each app: quit it first, run the command, launch the brew-installed version, verify it works. Check the box when done. Skip any you want to delete for good (use the "delete only" command at the bottom instead).

User data in `~/Library/Application Support/<App>/` and `~/Library/Preferences/` is preserved across the swap.

---

## One-liner helpers

**Migrate (remove old + install from brew):**
```bash
rm -rf "/Applications/APPNAME.app" && brew install --cask CASK_TOKEN
```

**Delete for good (no reinstall):**
```bash
rm -rf "/Applications/APPNAME.app"
# Optional — also wipe user data:
# rm -rf "$HOME/Library/Application Support/APPNAME" "$HOME/Library/Preferences/com.vendor.app.plist"
```

If an app won't delete (permission denied), prefix with `sudo` — Touch ID will prompt.

---

## Batch 1 — Browsers

- [x] **Firefox** → `rm -rf "/Applications/Firefox.app" && brew install --cask firefox`
- [x] **Google Chrome** → `rm -rf "/Applications/Google Chrome.app" && brew install --cask google-chrome`
- [x] **Arc** → `rm -rf "/Applications/Arc.app" && brew install --cask arc`
- [x] **Tor Browser** → `rm -rf "/Applications/Tor Browser.app" && brew install --cask tor-browser`
- [x] **Comet** → `rm -rf "/Applications/Comet.app" && brew install --cask comet`

## Batch 2 — Messaging

- [x] **Discord** → `rm -rf "/Applications/Discord.app" && brew install --cask discord`
- [x] **Telegram** → `rm -rf "/Applications/Telegram.app" && brew install --cask telegram`
- [x] **Signal** → `rm -rf "/Applications/Signal.app" && brew install --cask signal`
- [x] **Element** → `rm -rf "/Applications/Element.app" && brew install --cask element`
- [x] **Microsoft Teams** → `rm -rf "/Applications/Microsoft Teams.app" && brew install --cask microsoft-teams`

## Batch 3 — Dev tools

- [x] **Visual Studio Code** → `rm -rf "/Applications/Visual Studio Code.app" && brew install --cask visual-studio-code`
- [x] **Cursor** → `rm -rf "/Applications/Cursor.app" && brew install --cask cursor`
- [x] **Sublime Text** → `rm -rf "/Applications/Sublime Text.app" && brew install --cask sublime-text`
- [x] **Postman** → `rm -rf "/Applications/Postman.app" && brew install --cask postman`
- [x] **Docker** (quit first!) → `rm -rf "/Applications/Docker.app" && brew install --cask docker-desktop`
- [x] **Flipper** (Flipper Zero companion — qFlipper) → `rm -rf "/Applications/Flipper.app" && brew install --cask qflipper`
- [x] **Android Studio** → `rm -rf "/Applications/Android Studio.app" && brew install --cask android-studio`
- [x] **Claude** → `rm -rf "/Applications/Claude.app" && brew install --cask claude`
- [x] **Codex** → `rm -rf "/Applications/Codex.app" && brew install --cask codex`
- [x] **Figma** → `rm -rf "/Applications/Figma.app" && brew install --cask figma`
- [x] **Wireshark** → `rm -rf "/Applications/Wireshark.app" && brew install --cask wireshark-app`

## Batch 4 — Utilities & media tools

- [x] **Keka** → `rm -rf "/Applications/Keka.app" && brew install --cask keka`
- [x] **IINA** → `rm -rf "/Applications/IINA.app" && brew install --cask iina`
- [x] **OBS** → `rm -rf "/Applications/OBS.app" && brew install --cask obs`
- [x] **Transmission** → `rm -rf "/Applications/Transmission.app" && brew install --cask transmission`
- [x] **Raycast** → `rm -rf "/Applications/Raycast.app" && brew install --cask raycast`
- [x] **KeePassXC** (DB file stays put) → `rm -rf "/Applications/KeePassXC.app" && brew install --cask keepassxc`
- [x] **Android File Transfer → OpenMTP** (original is x86/Rosetta & deprecated upstream) → `brew uninstall --cask android-file-transfer 2>/dev/null; rm -rf "/Applications/Android File Transfer.app" && brew install --cask openmtp`
- [x] **balenaEtcher** → `rm -rf "/Applications/balenaEtcher.app" && brew install --cask balenaetcher`
- [x] **Raspberry Pi Imager** → `rm -rf "/Applications/Raspberry Pi Imager.app" && brew install --cask raspberry-pi-imager`
- [x] **AltServer** → `rm -rf "/Applications/AltServer.app" && brew install --cask altserver`
- [x] **Logseq** → `rm -rf "/Applications/Logseq.app" && brew install --cask logseq`
- [x] **Google Drive** → `rm -rf "/Applications/Google Drive.app" && brew install --cask google-drive`

## Batch 5 — Media / content creation

- [x] **Ollama** → `rm -rf "/Applications/Ollama.app" && brew install --cask ollama-app`
- [x] **RODE Central** → `rm -rf "/Applications/RODE Central.app" && brew install --cask rode-central`
- [x] **Insta360 Link Controller** → `rm -rf "/Applications/Insta360 Link Controller.app" && brew install --cask insta360-link-controller`
- [x] **NVIDIA Sync** → `rm -rf "/Applications/NVIDIA Sync.app" && brew install --cask nvidia-sync`
- [x] **BlueJ** → `rm -rf "/Applications/BlueJ.app" && brew install --cask bluej`
- [x] **Beamer** (licensed) → `rm -rf "/Applications/Beamer.app" && brew install --cask beamer`

## Batch 6 — Games

- [x] **Steam** (saves in `~/Library/Application Support/Steam`) → `rm -rf "/Applications/Steam.app" && brew install --cask steam`
- [x] **Spotify** → `rm -rf "/Applications/Spotify.app" && brew install --cask spotify`
- [x] **Heroic** → `rm -rf "/Applications/Heroic.app" && brew install --cask heroic`
- [x] **VCMI** → `rm -rf "/Applications/VCMI.app" && brew install --cask vcmi`

## Batch 7 — Remote access / VPN

- [x] **NoMachine** → `rm -rf "/Applications/NoMachine.app" && brew install --cask nomachine`
- [x] **TeamViewer** → `rm -rf "/Applications/TeamViewer.app" && brew install --cask teamviewer`
- [x] **VNC Viewer** → `rm -rf "/Applications/VNC Viewer.app" && brew install --cask vnc-viewer`
- [x] **AmneziaVPN** → `rm -rf "/Applications/AmneziaVPN.app" && brew install --cask amneziavpn`

## Batch 8 — Paid / licensed / system-extension apps (careful, verify one at a time)

> These may prompt for macOS extension approval or require license re-entry on first launch.

- [x] **1Password** (verify vault & license after) → `rm -rf "/Applications/1Password.app" && brew install --cask 1password`
- [x] **Little Snitch** (kernel ext — needs Privacy & Security approval) → `sudo rm -rf "/Applications/Little Snitch.app" && brew install --cask little-snitch`
- [x] **Parallels Desktop** (VMs & license preserved in `~/Parallels/`) → `rm -rf "/Applications/Parallels Desktop.app" && brew install --cask parallels`
- [x] **VirtualBox** (kernel ext) → `rm -rf "/Applications/VirtualBox.app" && brew install --cask virtualbox`
- [x] **LibreOffice** → `rm -rf "/Applications/LibreOffice.app" && brew install --cask libreoffice`
- [x] **Trezor Suite** → `rm -rf "/Applications/Trezor Suite.app" && brew install --cask trezor-suite`
- [x] **Bitcoin-Qt** (blockchain data stays in `~/Library/Application Support/Bitcoin/`) → `rm -rf "/Applications/Bitcoin-Qt.app" && brew install --cask bitcoin-core`
- [ ] **Outline Manager** → `rm -rf "/Applications/Outline Manager.app" && brew install --cask outline-manager`
- [ ] **Adobe AIR Installer** (if you even want it) → `rm -rf "/Applications/Adobe AIR Installer.app" && brew install --cask adobe-air`

## Cleanup — delete for good

These are safe to remove entirely. If you want to also wipe their user data, uncomment the second line.

- [x] **OUBuild** — `rm -rf "/Applications/OUBuild.app"`
- [x] **OUBuild2** — `rm -rf "/Applications/OUBuild2.app"`
- [x] **FortiClientUninstaller** (leftover) — `rm -rf "/Applications/FortiClientUninstaller.app"`

## Decide individually (candidates for deletion or manual keep)

These don't have brew casks. Keep or delete per your judgement.

- [x] AI Sub Translator — personal app, keep
- [x] DIT — personal app, keep
- [x] GymNation — personal app, keep
- [x] **FineTune** → `rm -rf "/Applications/FineTune.app" && brew install --cask finetune`
- [x] **FileZilla → Cyberduck** (adware on Mac, removed from brew) → `rm -rf "/Applications/FileZilla.app" && brew install --cask cyberduck`
- [x] **FortiClient → openfortivpn** (SSL VPN only) — install: `brew install openfortivpn` · config: `~/.openfortivpn.conf` · uninstall FortiClient by running `/Applications/FortiClientUninstaller.app`
- [x] NVIDIA AI Workbench — decide, removed
- [x] Red Shield VPN — decide, keep
- [x] Upwork — decide, keep
- [x] WiFiMonitor — decide, keep
- [x] jExifToolGUI — decide, leep, exiftool itself moved to brew

## Adobe folder / TeX folder / Cisco Packet Tracer / Utilities

In `/Applications` there are also non-`.app` folders we haven't touched:
- `Adobe/` — Adobe apps (not brew-managed, decide per-app)
- `Adobe Connect/`
- `Cisco Packet Tracer 8.2.2/`
- `TeX/` — covered by `mactex` cask, folder is fine
- `Utilities/` — system, leave alone

---

## After migration

When the list is done:
1. Run `brew list --cask` — should include everything you migrated.
2. Run `mas list` — should show your 17 App Store apps.
3. Tell me and I'll write the `update.sh` + `cleanup.sh` scripts.
