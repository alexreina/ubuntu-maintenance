#!/usr/bin/env bash
#
# Non-interactive maintenance script for Ubuntu
# - APT cleanup (update, fix, purge rc, autoremove, clean)
# - Optional: purge old kernels (--purge-old-kernels)
# - Optional: Snap refresh + purge disabled revisions (--purge-disabled-snaps)
#
# Designed to be safe for cron execution (no prompts).

set -euo pipefail

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Please run this script as root (or via sudo)."
    exit 1
  fi
}

log() {
  echo
  echo "==> $*"
}

update_and_fix() {
  log "Updating APT package lists..."
  DEBIAN_FRONTEND=noninteractive apt-get update -y

  log "Fixing broken APT dependencies (if any)..."
  DEBIAN_FRONTEND=noninteractive apt-get -f install -y || true
}

purge_residual_configs() {
  log "Purging residual config packages (state 'rc')..."
  mapfile -t rc_pkgs < <(dpkg -l | awk '/^rc/ {print $2}')

  if (( ${#rc_pkgs[@]} > 0 )); then
    echo "Packages to purge: ${rc_pkgs[*]}"
    DEBIAN_FRONTEND=noninteractive dpkg -P "${rc_pkgs[@]}"
  else
    echo "No residual config packages found."
  fi
}

autoremove_and_clean() {
  log "Autoremoving unused APT dependencies..."
  DEBIAN_FRONTEND=noninteractive apt-get autoremove --purge -y || true

  log "Cleaning APT caches..."
  apt-get clean
  apt-get autoclean
}

apt_sanity_check() {
  log "Running apt-get check..."
  apt-get check
}

purge_old_kernels() {
  log "Purging old kernels (non-interactive mode)..."

  current_kernel="$(uname -r)"
  current_pkg="linux-image-${current_kernel}"

  # List installed kernel image packages (not meta-packages)
  mapfile -t kernel_pkgs < <(
    dpkg -l | awk '/^ii\s+linux-image-[0-9]/ {print $2}' | sort -V
  )

  if (( ${#kernel_pkgs[@]} <= 2 )); then
    echo "Two or fewer kernel images installed; nothing to purge."
    return 0
  fi

  # Determine which to keep:
  # - currently running kernel
  # - newest kernel (last in sorted list)
  newest_pkg="${kernel_pkgs[-1]}"
  to_keep=("$current_pkg" "$newest_pkg")

  purge_list=()
  for pkg in "${kernel_pkgs[@]}"; do
    skip=false
    for keep in "${to_keep[@]}"; do
      if [[ "$pkg" == "$keep" ]]; then
        skip=true
        break
      fi
    done
    if ! $skip; then
      purge_list+=("$pkg")
    fi
  done

  if (( ${#purge_list[@]} == 0 ]]; then
    echo "No old kernels to purge."
    return 0
  fi

  echo "Current running kernel : ${current_pkg}"
  echo "Newest installed kernel: ${newest_pkg}"
  echo "Kernels to be purged   : ${purge_list[*]}"

  DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y "${purge_list[@]}"
}

snap_maintenance() {
  log "Snap refresh and disabled revision cleanup (non-interactive)..."

  if ! command -v snap >/dev/null 2>&1; then
    echo "snap command not found; skipping Snap maintenance."
    return 0
  fi

  log "Refreshing Snap packages..."
  snap refresh || echo "Snap refresh failed (network or server issue?), continuing..."

  log "Removing disabled Snap revisions..."
  # Each line: "<name> <revision>"
  mapfile -t disabled_lines < <(snap list --all | awk '/disabled/ {print $1, $3}')

  if (( ${#disabled_lines[@]} == 0 )); then
    echo "No disabled Snap revisions to remove."
    return 0
  fi

  for line in "${disabled_lines[@]}"; do
    read -r snapname revision <<< "$line"
    echo "Removing ${snapname} revision ${revision}..."
    snap remove "${snapname}" --revision="${revision}" || \
      echo "Failed to remove ${snapname} rev ${revision}, continuing..."
  done
}

main() {
  require_root

  PURGE_KERNELS=false
  SNAP_MAINT=false

  for arg in "$@"; do
    case "$arg" in
      --purge-old-kernels)
        PURGE_KERNELS=true
        ;;
      --purge-disabled-snaps)
        SNAP_MAINT=true
        ;;
      *)
        ;;
    esac
  done

  update_and_fix
  purge_residual_configs
  autoremove_and_clean

  if $PURGE_KERNELS; then
    purge_old_kernels
  else
    echo "Kernel purge disabled (run with --purge-old-kernels to enable)."
  fi

  if $SNAP_MAINT; then
    snap_maintenance
  else
    echo "Snap maintenance disabled (run with --purge-disabled-snaps to enable)."
  fi

  apt_sanity_check

  echo
  echo "Maintenance complete."
}

main "$@"

