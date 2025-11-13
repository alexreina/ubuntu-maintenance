#!/usr/bin/env bash
#
# Bootstrap installer for system-maintenance.sh
# - Downloads the maintenance script to /usr/local/sbin
# - Makes it executable
# - Runs it once (non-interactive)
# - Installs a weekly cron job at Monday 03:00
#
# Fully non-interactive and cron-safe.

set -euo pipefail

TARGET_PATH="/usr/local/sbin/system-maintenance.sh"
LOG_FILE="/var/log/system-maintenance.log"

RAW_URL="https://raw.githubusercontent.com/alexreina/ubuntu-maintenance/main/system-maintenance.sh"

CRON_LINE="0 3 * * 1 ${TARGET_PATH} --purge-old-kernels --purge-disabled-snaps >> ${LOG_FILE} 2>&1"

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Please run this script as root (use sudo)."
    exit 1
  fi
}

log() {
  echo
  echo "==> $*"
}

install_maintenance_script() {
  log "Downloading system-maintenance.sh from GitHub..."
  curl -fsSL "${RAW_URL}" -o "${TARGET_PATH}"

  log "Setting execute permissions on ${TARGET_PATH}..."
  chmod +x "${TARGET_PATH}"
}

run_maintenance_now() {
  log "Running maintenance script once (full cleanup)..."
  "${TARGET_PATH}" --purge-old-kernels --purge-disabled-snaps || {
    echo "Warning: maintenance script returned a non-zero exit code."
  }
}

install_cron_job() {
  log "Ensuring weekly cron job is installed..."

  EXISTING_CRON="$(crontab -l 2>/dev/null || true)"

  if echo "${EXISTING_CRON}" | grep -Fq "${TARGET_PATH}"; then
    echo "Cron entry already exists. Skipping."
    return 0
  fi

  {
    echo "${EXISTING_CRON}"
    echo "${CRON_LINE}"
  } | crontab -

  echo "Cron entry added:"
  echo "  ${CRON_LINE}"
}

main() {
  require_root

  if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required. Install with: sudo apt-get install -y curl"
    exit 1
  fi

  install_maintenance_script
  run_maintenance_now
  install_cron_job

  echo
  echo "Installation complete:"
  echo " - Script installed at: ${TARGET_PATH}"
  echo " - Weekly cron job at Monday 03:00"
  echo " - Logs at: ${LOG_FILE}"
}

main "$@"

