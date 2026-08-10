# Changelog

This changelog documents the changes made in the `jadehawk/koreader-tailscale` fork relative to Victoria Riley-Barnett's upstream `v1.2.0` implementation.

## 1.3.0 - 2026-08-10

### User interface and menu organization

- Reorganized the Tailscale menu into a clearer task-oriented layout:
  - `Enable Tailscale` as the main checked toggle.
  - `Status` kept at the top level.
  - Added a `Setup` submenu containing:
    - `Install / Update Tailscale`
    - `Set Auth Key`
    - `Set Headscale URL`
    - `Uninstall Tailscale`
  - Added an `Advanced` submenu containing `Start / Stop Daemon`.
- Renamed the original generic `Tailscale VPN` toggle to `Enable Tailscale` so its purpose is explicit.
- Moved low-level daemon control out of the normal workflow and into `Advanced`.
- Temporarily moved the plugin to KOReader's `Tools` menu while evaluating placement, then moved it to its final location under `Settings -> Network -> Tailscale VPN` to match the plugin's networking purpose.
- Updated README menu paths to match the final Network placement.

### Auth key configuration

- Ported TimmyKug-style auth-key editing into Victoria's plugin using KOReader's `InputDialog`.
- `Set Auth Key` now opens an editable on-device text field instead of only reporting where the file is located.
- Existing auth keys are pre-filled in the dialog.
- Added validation for supported auth-key formats:
  - Tailscale keys beginning with `tskey-`.
  - Headscale auth keys beginning with `hskey-auth-`.
- Saving an empty field clears the configured auth key.
- Added user-facing success and error messages for saving, clearing, and invalid auth keys.
- Added a secondary manual-file configuration workflow for users who do not want to type a long key on an e-ink keyboard.
- Added `ensureAuthKeyFile()` so the plugin creates `auth.key` automatically if it is missing.
- The automatically created `auth.key` is made writable and the plugin attempts to apply mode `0600` where the filesystem supports Unix permissions.
- The install script also ensures `auth.key` exists after installing binaries and attempts to set mode `0600`.
- Auth-key preflight validates the file contents, not merely the existence of the file. Empty, whitespace-only, comment-only, or malformed files are treated as no key configured.
- Expanded the missing-auth-key message to explain both supported configuration methods:
  - `Settings -> Network -> Tailscale VPN -> Setup -> Set Auth Key`.
  - Directly editing the existing `auth.key` file.
- Added instructions showing where to generate a Tailscale auth key in the Tailscale Admin Console:
  - `Keys -> Auth keys -> Generate auth key`.
- Added the Tailscale Admin Console keys URL to the on-device warning and README.
- Documented typical `auth.key` locations for Kindle, Kobo, and PocketBook.
- Added a blank `bin/auth.key` file to the distributed plugin package so users can paste their key immediately after copying the plugin to the device, before starting KOReader or downloading Tailscale binaries.
- Updated installation instructions to recommend optionally pre-configuring the packaged blank `auth.key` while the e-reader is still connected to the computer.
- Added release/build safeguards which refuse to package or publish `bin/auth.key` if it contains any non-whitespace content, preventing accidental publication of a real auth key.

### Headscale configuration

- Replaced the original informational Headscale configuration screen with an editable KOReader `InputDialog`.
- `Set Headscale URL` now pre-fills the current configured URL.
- Added URL validation requiring `http://` or `https://`.
- Saving a blank value removes the Headscale override and restores the default Tailscale login server.
- Added success and error messages for saving and clearing the Headscale URL.
- Retained support for the existing `headscale.url` file format and storage location.

### Startup safety and preflight checks

- Hardened the normal `Enable Tailscale` flow so it will not attempt to launch Tailscale until required prerequisites are satisfied.
- Added/retained preflight checks in this order:
  - Tailscale binaries are installed.
  - A valid Tailscale or Headscale auth key is configured.
  - Network connectivity is available.
- If binaries are missing, the user is directed to `Setup -> Install / Update Tailscale` instead of attempting to start a missing program.
- If the auth key is missing or invalid, no daemon is launched and the user is shown configuration instructions.
- Kept `Advanced -> Start / Stop Daemon` available for troubleshooting without imposing the normal auth-key requirement on low-level daemon control.

### Tailscale installation and version detection

- Updated the pinned Tailscale fallback version from `1.96.2` to `1.102.2`.
- Fixed the automatic latest-version parser.
- The upstream installer expected a lowercase compact JSON field such as `"version":"..."`, but Tailscale's current package endpoint returns fields such as `"TarballsVersion": "1.102.2"` and `"Version": "1.102.2"`.
- The installer now reads `TarballsVersion` first and falls back to `Version` if necessary.
- The parser tolerates whitespace in the JSON formatting.
- Dynamic version detection remains the preferred installation path; the pinned version is used only when detection fails.
- Added installer reporting markers:
  - `TS_LATEST_DETECTED=<version>` when automatic detection succeeds.
  - `TS_FALLBACK_USED=<version>` when the fallback is used.
- Added a visible warning when latest-version detection fails and the fallback version is installed.
- The final installation report now shows the version that was detected or explicitly reports that fallback `1.102.2` was used.
- Increased the fallback-warning display time so the user has time to read it on an e-ink screen.
- Updated stale manual-install examples in `README.md` and `NOTES.md` from older Tailscale versions to `1.102.2`.

### Local release packaging

- Added `build_plugin.bat` as a double-click-friendly Windows build launcher.
- Added `build_plugin.ps1` as the release packaging implementation.
- The local builder reads the plugin version directly from `_meta.lua` and creates a versioned ZIP in `Builds/`.
- The generated ZIP has the correct top-level `tailscale.koplugin/` directory for drag-and-drop KOReader installation.
- Packaging uses an explicit runtime-file allowlist rather than copying the whole repository and excluding development files afterward.
- The runtime ZIP currently contains only:
  - `_meta.lua`
  - `main.lua`
  - `bin/auth.key`
  - `bin/install-tailscale.sh`
  - `bin/start_tailscale.sh`
  - `bin/stop-tailscale.sh`
  - `bin/uninstall-tailscale.sh`
- The builder validates every required runtime file before creating the archive.
- The builder verifies the final ZIP manifest and fails if an unexpected or missing runtime file is present.
- The builder refuses to package a nonblank `bin/auth.key`.
- The builder supports `-Force` for non-interactive replacement of an existing versioned ZIP while otherwise prompting before overwrite.
- Generated ZIP files remain ignored by Git.

### GitHub release workflow

- Tightened `.github/workflows/release.yml` to use the same explicit runtime-file set as the local Windows builder.
- Prevented build scripts, tests, documentation, `.codegraph`, and other development files from accidentally entering tagged release packages.
- Added `bin/auth.key` to tagged release ZIPs as a blank configuration template.
- Added a GitHub Actions safety check which aborts release creation if `bin/auth.key` contains non-whitespace content.
- Retained tag-to-`_meta.lua` version validation before publishing releases.

### Line-ending and shell-script reliability

- Normalized all shell scripts to Unix LF line endings.
- Added `.gitattributes` with `*.sh text eol=lf` so Git preserves LF endings for shell scripts on Windows development machines.
- Added test coverage which fails if any packaged shell script contains carriage-return/CRLF bytes.
- The Windows builder independently checks shell-script bytes and refuses to build if CR/CRLF is present.
- Continued validating the shell scripts as POSIX `/bin/sh` scripts.

### Tests and verification

- Expanded `test.sh` coverage for the fork-specific functionality, including:
  - Network menu placement.
  - Missing-auth-key startup protection.
  - Automatic/manual `auth.key` support.
  - Presence of the packaged blank `bin/auth.key`.
  - Current Tailscale version detection and `1.102.2` fallback.
  - User-visible fallback-version reporting.
  - LF-only shell-script enforcement.
- Updated the integration test-suite version banner and JSON report from `1.2.0` to `1.3.0`.
- Preserved the existing userspace-networking, SOCKS5, HTTP CONNECT, shell syntax, POSIX, and runtime-structure checks.
- Final v1.3.0 local verification completed with `32 passed, 0 failed` under `/usr/bin/lua5.1`.
- Rebuilt and verified `Builds/tailscale.koplugin-v1.3.0.zip` after the v1.3.0 changes.

### Documentation

- Reworked README setup instructions around the new menu organization.
- Documented both on-device and direct-file auth-key configuration.
- Added auth-key generation instructions and typical platform paths.
- Documented editable Headscale configuration.
- Documented the Windows build workflow and exact runtime ZIP contents.
- Updated manual Tailscale download, transfer, extraction, and cleanup examples to version `1.102.2`.
- Updated `NOTES.md` manual-install examples to `1.102.2`.

### Version

- Bumped the fork from Victoria's upstream `1.2.0` to `1.3.0` after the accumulated UI, configuration, safety, packaging, installer, and release changes.

### Fork commits included

- `85d1774` - Improve Tailscale plugin setup UI
- `82ebab1` - Move Tailscale menu under Tools
- `7f5f525` - Add local plugin release builder
- `12ada95` - Move Tailscale under Network and guard startup
- `b0fca7a` - Support manual auth key configuration
- `e86d76c` - Fix Tailscale version detection and fallback reporting
- `e2a7b3a` - Release v1.3.0 with blank auth key template
