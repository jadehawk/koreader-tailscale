# Tailscale Plugin for KOReader

Run Tailscale on your e-reader. Tested on Kindle PW5/PW6, Kobo, and PocketBook. Should work on any KOReader device with ARMv7 or ARM64.

Pairs well with [koreader-syncthing](https://github.com/jasonchoimtt/koreader-syncthing) for file sync over your tailnet.

## Prerequisites

1. **Tailscale Account**: Sign up at [tailscale.com](https://tailscale.com).
2. **Auth Key**: Create a reusable auth key at [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys).
3. **E-reader with file and/or SSH access**: With KOReader installed. Tested on Kindle PW6 and PW5, and PocketBook devices. Should work on any device running ARMv7 or ARM64 binaries.

## Installation

1. Copy `tailscale.koplugin` to your KOReader plugins directory:
   - **Kindle**: `/mnt/us/koreader/plugins/`
   - **Kobo**: `/mnt/onboard/.adds/koreader/plugins/`
   - **PocketBook**: `/mnt/ext1/koreader/plugins/`
2. Restart KOReader.
3. In KOReader: Menu → Tools → Tailscale VPN → Setup → Install / Update Tailscale.

**Note**: Installation downloads ~57 MB. You can pre-download binaries and transfer via SCP/SSH to the plugin's `bin/` directory (default location depends on device).

## Build a Plugin ZIP on Windows

Run `build_plugin.bat` from the repository root. It calls `build_plugin.ps1`, reads the version from `_meta.lua`, validates that all required runtime files exist, refuses to package shell scripts with CR/CRLF line endings, and creates a versioned ZIP in `Builds/`.

The generated archive contains a top-level `tailscale.koplugin/` folder with only the runtime files required by KOReader:

- `_meta.lua`
- `main.lua`
- `bin/install-tailscale.sh`
- `bin/start_tailscale.sh`
- `bin/stop_tailscale.sh`
- `bin/uninstall-tailscale.sh`

The builder verifies the final ZIP manifest before reporting success. Generated ZIP files are ignored by Git.

## Setup

1. **Set the Auth Key in KOReader**:
   Open **Tailscale VPN → Setup → Set Auth Key**, paste a Tailscale (`tskey-`) or Headscale (`hskey-auth-`) auth key, and tap **Save**. The plugin stores it in `auth.key` in the managed Tailscale `bin/` directory.

   Existing `auth.key` files are still supported. Advanced users can continue to copy or edit the file manually if preferred.

2. **(Optional) Set a self-hosted Headscale server in KOReader**:
   Open **Tailscale VPN → Setup → Set Headscale URL**, enter the full `http://` or `https://` login-server URL, and tap **Save**. Leave the field blank and save to return to the default Tailscale login server.

   Existing `headscale.url` files are still supported and can also be managed manually if needed.

3. Open **Tailscale VPN → Enable Tailscale** to connect. The menu item is checked while the daemon is running.

## Proxy

The plugin runs SOCKS5 on `127.0.0.1:1055` and HTTP CONNECT on `127.0.0.1:1056` so KOReader can reach tailnet services (OPDS, sync, etc.).

### Chmod Note

To make the scripts executable on the device, navigate to the Tailscale `bin/` directory and run `chmod +x`:

```sh
# Default Kindle location
cd /mnt/us/koreader/plugins/tailscale.koplugin/bin
chmod +x start_tailscale.sh

# Kobo plugin directory (typical location)
cd /mnt/onboard/.adds/koreader/plugins/tailscale.koplugin/bin
chmod +x start_tailscale.sh

# PocketBook plugin directory
cd /mnt/ext1/koreader/plugins/tailscale.koplugin/bin
chmod +x start_tailscale.sh
```

## Installation Location

Tailscale binaries are installed in the plugin's `bin/` directory for Kindle and Kobo devices. For PocketBook devices, binaries are installed in external storage (`/mnt/ext1/tailscale/bin`) to avoid read-only filesystem limitations.

### Troubleshooting Space Issues

If installation fails due to insufficient space:

1. **Check available space** on the partition containing KOReader:
   ```bash
   df -h /mnt/us /mnt/onboard /mnt
   ```

2. Ensure at least 100MB free space is available.

3. If space is limited, consider moving KOReader to a different partition or using manual installation (see Manual Installation section).

## Usage with Syncthing

1. Note your Kindle's Tailscale IP from the status menu.
2. Install Tailscale and Syncthing on other devices.
3. Configure Syncthing to use the Tailscale IP by adding the address:
   ```
   tcp://<tailscale-ip or magic dns>:22000
   ```
4. Enjoy secure, remote file synchronization without having to be on the same network.

## Plugin Menu Commands

- **Enable Tailscale**: Toggle the Tailscale connection; the item is checked while the daemon is running.
- **Status**: Show daemon state, Tailscale IPs, and device name.
- **Setup → Install / Update Tailscale**: Download and install or update the binaries.
- **Setup → Set Auth Key**: Enter, replace, or clear the Tailscale/Headscale auth key directly in KOReader.
- **Setup → Set Headscale URL**: Enter, replace, or clear the Headscale login-server URL directly in KOReader.
- **Setup → Uninstall Tailscale**: Stop and remove Tailscale files (including the auth key).
- **Advanced → Start / Stop Daemon**: Control `tailscaled` independently for troubleshooting.

## Files Location

Files are located in the Tailscale `bin/` directory, which depends on the device:

- **Kindle**: `/mnt/us/koreader/plugins/tailscale.koplugin/bin/`
- **Kobo**: `/mnt/onboard/.adds/koreader/plugins/tailscale.koplugin/bin/`
- **PocketBook**: `/mnt/ext1/tailscale/bin/` (external storage)

Logs (`tailscale.log`, `tailscaled.log`) and configuration files (`auth.key`, `headscale.url`) are stored in the same directory.

## Uninstall / Reinstall

1. **Uninstall**: Menu → Tools → Tailscale VPN → Setup → Uninstall Tailscale.
2. **Reinstall**: Menu → Tools → Tailscale VPN → Setup → Install / Update Tailscale.

You may want to backup your auth.key file (located in the plugin's `bin/` directory) by moving it to `auth.key.backup` or similar before uninstalling, and restore its name after reinstalling.

## Manual Installation

If the automatic installation fails, you can install Tailscale manually:

**Note**: Binaries are installed in the plugin's `bin/` directory. Replace `/mnt/us/koreader/plugins/tailscale.koplugin/bin/` with your actual plugin path if different.

**Migration**: If you previously used an external directory (e.g., `/mnt/us/tailscale`), move your existing binaries to the plugin's `bin/` directory.

### 1. Download Tailscale Binaries

Download the appropriate binaries for your device architecture (ARMv7/ARMv8/ARM64):

```bash
# On your computer
wget https://pkgs.tailscale.com/stable/tailscale_1.94.2_arm.tgz
# or
curl -O https://pkgs.tailscale.com/stable/tailscale_1.94.2_arm.tgz
```

### 2. Transfer to Your Device

Copy the archive to your e-reader:

```bash
# For Kindle (SSH on port 2222)
scp -P 2222 tailscale_1.94.2_arm.tgz root@<device-ip>:/mnt/us/koreader/plugins/tailscale.koplugin/bin/

# For Kobo (plugin directory)
scp tailscale_1.94.2_arm.tgz root@<device-ip>:/mnt/onboard/.adds/koreader/plugins/tailscale.koplugin/bin/
```

### 3. Extract and Install

SSH into your device and run:

```bash
# Navigate to the bin directory
cd /mnt/us/koreader/plugins/tailscale.koplugin/bin  # or /mnt/onboard/.adds/koreader/plugins/tailscale.koplugin/bin for Kobo

# Extract
tar xzf tailscale_1.94.2_arm.tgz

# Move binaries
mv tailscale_*/tailscale tailscale_*/tailscaled ./
rm -rf tailscale_* tailscale_1.94.2_arm.tgz

# Make executable
chmod +x tailscale tailscaled

# Create empty auth.key file if it doesn't exist
touch auth.key
```

### 4. Configure Auth Key

Create `auth.key` with your Tailscale auth key:

```bash
echo "tskey-..." > /mnt/us/koreader/plugins/tailscale.koplugin/bin/auth.key  # or /mnt/onboard/.adds/koreader/plugins/tailscale.koplugin/bin/auth.key
```

### 5. Start Tailscale

Return to KOReader and use the plugin menu to start Tailscale.

## Troubleshooting

Check `bin/tailscaled.log` and `bin/tailscale.log` in the plugin directory. See [NOTES.md](NOTES.md) for internals and manual installation.

## Credits

Based on [mitanshu7/tailscale_kual](https://github.com/mitanshu7/tailscale_kual). MIT License.
