# Ubuntu Maintenance Automation

This repository provides two Bash scripts that fully automate routine system maintenance on Ubuntu:

- **system-maintenance.sh** — The main non-interactive maintenance script  
- **install.sh** — A bootstrap installer that downloads, installs, and schedules the maintenance script automatically

The scripts are designed to be **safe**, **fully unattended**, and suitable for **cron-based automation** on both desktop and server Ubuntu installations.

---

## 🚀 Features

### APT maintenance
- Update package lists (`apt-get update`)
- Fix broken dependencies
- Purge residual (rc) packages
- Autoremove unused packages
- Clean & autoclean package caches
- APT consistency check (`apt-get check`)

### Kernel housekeeping
- Optional: purge old kernels  
- Keeps:
  - the *running* kernel  
  - the *newest installed* kernel  
- Safely removes everything older

### Snap maintenance
- Optional: `snap refresh`
- Optional: remove unused disabled snap revisions  
- Skipped automatically if snap isn’t installed

### Cron automation
- Weekly maintenance at **03:00 every Monday**
- Logged to `/var/log/system-maintenance.log`
- Fully non-interactive

---

## 📦 Repository contents

### `system-maintenance.sh`
The actual maintenance logic:

- APT cleanup  
- Kernel cleanup (optional)  
- Snap cleanup (optional)  
- Fully non-interactive when called with flags  
- Safe for cron execution  

Supported flags:

```
--purge-old-kernels
--purge-disabled-snaps
```

### `install.sh`
A bootstrap installer that:

1. Downloads `system-maintenance.sh` from this GitHub repo  
2. Installs it to `/usr/local/sbin/system-maintenance.sh`  
3. Makes it executable  
4. Runs it once immediately with full cleanup  
5. Adds a cron job for weekly automated maintenance  
6. Logs all activity to `/var/log/system-maintenance.log`

---

## 🔧 One-liner installation (recommended)

Run the following command on **any Ubuntu machine**:

```
curl -fsSL https://raw.githubusercontent.com/alexreina/ubuntu-maintenance/main/install.sh | sudo bash
```

This will:

- Download and install the maintenance script  
- Run it once  
- Install the weekly cron job  
- Configure logging  

No interaction required.

---

## 🛠 Manual usage

Run the script manually at any time:

```
sudo /usr/local/sbin/system-maintenance.sh --purge-old-kernels --purge-disabled-snaps
```

Or run a lighter version (no kernel/snap cleanup):

```
sudo /usr/local/sbin/system-maintenance.sh
```

---

## ⏱ Cron job installed by default

The installer sets up this cron entry:

```
0 3 * * 1 /usr/local/sbin/system-maintenance.sh --purge-old-kernels --purge-disabled-snaps >> /var/log/system-maintenance.log 2>&1
```

Meaning:

- Runs every **Monday at 03:00**
- Performs full system maintenance
- Writes output to `/var/log/system-maintenance.log`

View or modify the cron job:

```
sudo crontab -e
```

---

## 📁 Log files

The scripts log to:

```
/var/log/system-maintenance.log
```

View logs with:

```
sudo less /var/log/system-maintenance.log
sudo tail -f /var/log/system-maintenance.log
```

---

## 🔍 CI (GitHub Actions)

This repository includes `.github/workflows/ci.yml` that:

- Validates Bash syntax (`bash -n`)
- Runs ShellCheck on all `.sh` files

Triggered on every push or pull request to `main`.

---

## 🧪 Testing locally

You can test the maintenance script without installing it:

```
bash system-maintenance.sh --purge-old-kernels --purge-disabled-snaps
```

Syntax + lint:

```
bash -n system-maintenance.sh
shellcheck system-maintenance.sh
```

---

## 📝 Requirements

- Ubuntu or Debian-family OS  
- `bash`  
- `curl` (required for installer)  
- `snapd` (optional; script auto-detects if missing)  
- `cron` (standard on Ubuntu)

---

## 📄 License

MIT License.  
You are free to use, modify, and redistribute these scripts.

---

## 👤 Author

**Alex Reina**  
GitHub: [@alexreina](https://github.com/alexreina)
