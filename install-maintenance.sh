#!/usr/bin/env bash
#
# Bootstrap installer for system-maintenance.sh
# - Downloads the maintenance script to /usr/local/sbin
# - Makes it executable
# - Runs it once with full cleanup
# - Installs a weekly cron job (root) if not already present

set -euo pipefail

TARGET_PATH="/usr/local/sbin/system-maintenance.sh"
LOG_FILE="/var/log/system-maintenance.log"

# TODO: replace this with your actual raw GitHub URL
RAW_URL="https://raw.githubusercontent.com/alexreina/<REPO>/<BRANCH>/system-maintenance.sh"

CRON_LINE="0 3 * * 1 ${TARGET_PATH} --purge-old-kernels --purge-disabled-snaps >> ${LOG_FILE} 2>&1"

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

install_maintenance_script() {
  log "Downloading maintenance script from GitHub..."
  curl -fsSL "${RAW_URL}" -o "${TARGET_PATH}"

  log "Setting execute permissions on ${TARGET_PATH}..."
  chmod +x "${TARGET_PATH}"
}

run_maintenance_now() {
  log "Running maintenance script once (with kernel + snap cleanup)..."
  "${TARGET_PATH}" --purge-old-kernels --purge-disabled-snaps || {
    echo "Warning: maintenance script exited with a non-zero status."
  }
}

install_cron_job() {
  log "Ensuring weekly cron job is installed..."

  # Get existing crontab (if any)
  EXISTING_CRON="$(crontab -l 2>/dev/null || true)"

  # If the line is already present, do nothing
  if echo "${EXISTING_CRON}" | grep -Fq "${TARGET_PATH}"; then
    echo "Cron entry already present. Skipping cron install."
    return 0
  fi

  # Append our cron line
  {
    echo "${EXISTING_CRON}"
    echo "${CRON_LINE}"
  } | crontab -

  echo "Cron entry installed:"
  echo "  ${CRON_LINE}"
}

main() {
  require_root

  if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required but not installed. Install it with: sudo apt-get install -y curl"
    exit 1
  fi

  install_maintenance_script
  run_maintenance_now
  install_cron_job

  echo
  echo "All done."
  echo " - Script installed at: ${TARGET_PATH}"
  echo " - Log file (cron runs): ${LOG_FILE}"
  echo " - Weekly cron at: 03:00 every Monday"
}

main "$@"

