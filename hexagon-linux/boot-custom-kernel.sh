#!/usr/bin/env sh

set -eu

readonly GRUB_CFG="/boot/grub/grub.cfg"

print_help() {
    cat <<'EOF'
Usage: boot-custom-kernel.sh [-k VERSION] [-y] [-h]

Set a ONE-SHOT GRUB boot into the given kernel version, then reboot.
The default GRUB entry is left unchanged, so the boot AFTER this one
reverts to it automatically (your safety net stays intact).

Options:
  -k VERSION  kernel version to boot next (default: 6.8.0-1077-qcom)
  -y          skip the confirmation prompt and reboot immediately
  -h          show this help
EOF
    exit 0
}

# Re-exec as root so grub-reboot / reboot work without a manual sudo.
if [ "$(id -u)" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

while getopts ":k:yh" option; do
    case "${option}" in
        "k") readonly KERNEL_VERSION="${OPTARG}";;
        "y") readonly ASSUME_YES=1;;
        "h") print_help;;
        ":") echo "error: option -${OPTARG} requires an argument" >&2; exit 1;;
        "?") echo "error: invalid option -${OPTARG}" >&2; exit 1;;
    esac
done
shift $((OPTIND - 1))

if [ -z "${KERNEL_VERSION:-}" ]; then
    readonly KERNEL_VERSION="6.8.0-1077-qcom"
fi

if [ -z "${ASSUME_YES:-}" ]; then
    readonly ASSUME_YES=0
fi

if [ ! -r "${GRUB_CFG}" ]; then
    echo "error: cannot read ${GRUB_CFG}" >&2
    exit 1
fi

grub_reboot_cmd="grub-reboot"
if ! command -v "${grub_reboot_cmd}" >/dev/null 2>&1; then
    grub_reboot_cmd="grub2-reboot"
fi
if ! command -v "${grub_reboot_cmd}" >/dev/null 2>&1; then
    echo "error: grub-reboot not found" >&2
    exit 1
fi

# Match the first menuentry whose title ends exactly with the version, so
# "6.6.97.old" and "(recovery mode)" entries are not selected. Exact suffix
# comparison avoids regex-escaping pitfalls with the dots in the version.
submenu_title="$(awk -F"'" '/^submenu /{print $2; exit}' "${GRUB_CFG}")"
entry_title="$(awk -F"'" -v v="${KERNEL_VERSION}" '
    $0 ~ /menuentry / {
        t = $2
        if (length(t) >= length(v) && substr(t, length(t) - length(v) + 1) == v) {
            print t
            exit
        }
    }' "${GRUB_CFG}")"

if [ -z "${entry_title}" ]; then
    echo "error: no GRUB entry found for kernel ${KERNEL_VERSION}" >&2
    exit 1
fi

if [ -n "${submenu_title}" ]; then
    target="${submenu_title}>${entry_title}"
else
    target="${entry_title}"
fi

echo "One-shot boot target: ${target}"
"${grub_reboot_cmd}" "${target}"
echo "GRUB will boot ${KERNEL_VERSION} on the next reboot (once)."

if [ "${ASSUME_YES}" -ne 1 ]; then
    printf 'Reboot now? [y/N] '
    read -r answer
    case "${answer}" in
        [Yy]*) ;;
        *) echo "Reboot skipped. The one-shot flag is set and applies on your next reboot."; exit 0;;
    esac
fi

echo "Rebooting..."
reboot
