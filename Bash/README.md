# Warvdoh's Utility Scripts (Warv-X Suite)

A set of Linux shell scripts, used Linux system administration, and optimized for debian and bash, but with a degree of redundancy and distro ambiguity.

---

**Installation of Warv-X Suite:**

To install/update all scripts with aliases, simply run:


```bash
curl -sLo ~/update-x.sh https://raw.githubusercontent.com/Warvdoh/Scripts/main/Bash/update-x.sh && chmod +x ~/update-x.sh && ~/update-x.sh --install && source ~/.bashrc
```


---

## dscan-x.sh (v1.1)

Drive scan and copy utility with safe read-only mounting and optional badblocks check.

**Usage:**
Run anywhere with no options or arguments:

```bash
./dscan-x.sh
```

**Self-installation:**

* On first run outside `~/dscan-x.sh`, it copies itself to `~/dscan-x.sh`
* Adds alias `dscan` to `~/.bashrc` automatically
* Exits after installation prompt; reload shell or `source ~/.bashrc` to use alias

**Workflow:**

1. Lists all available block devices (disks), showing size and mount status
2. Prompts user to select a drive number
3. Asks for confirmation before proceeding
4. Prompts for operation mode:

   * `S` for scan only (runs `badblocks` read-only scan on device)
   * `C` for copy only (copies files from mounted device to temp backup using `rsync`)
   * `SC` for both scan and copy concurrently
5. Attempts to mount the selected device read-only; if fails, lists partitions for user to choose and mount
6. Runs chosen operation(s) in background, showing progress logs
7. On completion, shows logs location and prompts for optional unmount of device

**Technical details:**

* Uses `sudo mount -o ro` to mount device or partition safely
* Uses `ionice` and `nice` to minimize impact during `badblocks` scan
* Copies files with `rsync -a --ignore-existing` preserving metadata, showing progress
* Temporary working directory: `/tmp/safe_recovery` for mounts, logs, and backups
* Interrupt trap cleans up by unmounting device before exit

---

## ntest-x.sh (v1.1.9)

Self-installing network connectivity tester with simple ping diagnostics and local LAN IP listing.

**Usage:**
Run anywhere or via alias after install:

```bash
./ntest-x.sh
# or
ntest
```

**Self-installation:**

* On first run outside `~/ntest-x.sh`, it copies itself to `~/ntest-x.sh`
* Makes the copy executable
* Adds alias `ntest` to `~/.bashrc` automatically
* Exits after installation prompt; reload shell or `source ~/.bashrc` to use alias

**Workflow:**

1. Pings these targets with 4 ICMP echo requests each:

   * Cloudflare DNS (1.1.1.1)
   * Google DNS (8.8.8.8)
   * Default gateway (auto-detected via `ip route`)

2. For each target, reports success `[OK]` on zero packet loss or failure with loss percentage

3. Cleans up ping output by clearing intermediate lines on success

4. Lists local LAN IP addresses (IPv4 and IPv6) with interface names

5. Ends with completion message

**Technical details:**

* Uses standard Bash and common Linux commands: `ping`, `ip`, `awk`, `grep`, `stdbuf`
* Temporary files cleaned up after each ping test
* Colors output with ANSI escape sequences for info, OK, and fail statuses
* Licensed under Warvdoh’s Personal Use License (WPUL) v1.2

---

## update-x.sh (v1.0)

Utility to update your local `*-x.sh` scripts from the GitHub repository [Warvdoh/Scripts](https://github.com/Warvdoh/Scripts).

---

### Usage

Run anywhere without arguments for normal update:

```bash
./update-x.sh
```

On first run outside `~/update-x.sh`, it will:

* Copy itself to `~/update-x.sh`
* Add alias `update-x` to `~/.bashrc`
* Exit with instructions to reload shell or `source ~/.bashrc`

---

### Features

* **Updates all local `*-x.sh` scripts** found in home directory by comparing embedded `VERSION="vX.Y"` tags with repo versions
* Prints a formatted table of:
  `[Local file] [Local ver] [Git file] [Git ver] [URL]`
* Smart version comparison supporting arbitrary dot-separated numeric versions
* Skips updates if local version is newer than repo
* Supports forced overwrite (`-o` flag) to replace all scripts unconditionally
* Supports dry-run mode (`-d` flag) to only show what would be changed without writing files
* Supports install mode (`--install` flag) to copy new scripts from repo that don’t exist locally and add aliases (except for update-x itself)
* Uses shallow clone (`--depth=1`) for performance
* Adds executable permissions after copying scripts

---

### Command-line flags

| Flag        | Description                                |
| ----------- | ------------------------------------------ |
| `-d`        | Dry run — no file changes performed        |
| `-o`        | Force overwrite all local scripts          |
| `--install` | Install new scripts from repo (no updates) |

---

### Notes

* Script works only on scripts named `*-x.sh` in the user’s home directory
* Aliases added during `--install` correspond to the base name without `-x.sh` suffix
* `update-x` script itself does not get an alias added on install
* Temporary repo clone happens in a secure temporary directory, cleaned automatically
* Errors on missing or unknown version tags gracefully handled with warnings

---

## Requirements

* Bash shell on Linux
* `sudo` access (for dscan-x.sh operations)
* Utilities Include: `lsblk`, `mount`, `rsync`, `badblocks`, `ping`, `awk`, `ionice`, `nice`, `numfmt`
* Bash will automatically detect unmet dependencies when script is triggered

---

## License

© 2025 Warvdoh Mróz
Licensed under Warvdoh's Personal Use License (WPUL) v1.2
See [LICENSE.md](https://warvdoh.github.io/Assets/LICENSE.md)
