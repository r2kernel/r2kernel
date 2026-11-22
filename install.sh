#!/usr/bin/env sh
# R2Kernel installer bootstrap: verify the pinned installer SHA256, then run it.
# The whole script is one function so a piped shell (`curl ... | sh`) has read
# every line before the installer starts.
set -eu

main() {
VERSION=1.0.1
TAG=v1.0.1
EXPECTED_MANIFEST_SHA256=3e195aaf707d39ec853dcd8b335b2dc495e5e65dc43bf6d1cf13419a6e6775f8
DEFAULT_REPO_SLUG=r2kernel/r2kernel
REPO_SLUG="${R2KERNEL_RELEASE_REPO_SLUG:-$DEFAULT_REPO_SLUG}"
if [ -n "${R2KERNEL_INSTALL_ID:-}" ]; then
  INSTALL_ID="$R2KERNEL_INSTALL_ID"
elif command -v uuidgen >/dev/null 2>&1; then
  INSTALL_ID="$(uuidgen | tr '[:upper:]' '[:lower:]')"
elif [ -r /proc/sys/kernel/random/uuid ]; then
  INSTALL_ID="$(cat /proc/sys/kernel/random/uuid)"
else
  INSTALL_ID="$(date +%s)-$$"
fi

if [ "$REPO_SLUG" = "OWNER/REPO" ]; then
  echo "Set R2KERNEL_RELEASE_REPO_SLUG or regenerate this script with --public-repo-slug." >&2
  exit 1
fi

case "$(uname -s)" in
  Linux) os_name="linux" ;;
  *) echo "This installer currently supports Linux only." >&2; exit 1 ;;
esac

case "$(uname -m)" in
  x86_64|amd64) arch_name="x86_64" ;;
  arm64|aarch64) arch_name="aarch64" ;;
  armv7l|armv7) arch_name="armv7" ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

# This script pins the SHA256 of the installer binary below and of the
# release-manifest.json above; the installer refuses a manifest whose raw bytes
# or release version differ, and the manifest pins every other artifact's
# SHA256. Download locations may be overridden; the pinned hashes cannot.
# This is integrity verification against this script, not a signature: anyone
# who can change this script can change the hashes, so obtain it over HTTPS.
case "$os_name-$arch_name" in
  linux-aarch64) EXPECTED_INSTALLER_SHA256="23d9c49e144745e610c5e2c2217c643e7e5e522cf53b6dd26676befeda5eabd7" ;;
  linux-x86_64) EXPECTED_INSTALLER_SHA256="f9741d256268558096d90d4c50f962324f957267cd95173ce00748ba98d42f22" ;;
  *) echo "No trusted installer SHA256 for $os_name-$arch_name in release $VERSION." >&2; exit 1 ;;
esac
if command -v sha256sum >/dev/null 2>&1; then
  installer_sha256() { sha256sum "$1"; }
elif command -v shasum >/dev/null 2>&1; then
  installer_sha256() { shasum -a 256 "$1"; }
else
  echo "Need sha256sum or shasum to verify the installer before execution." >&2
  exit 1
fi
NL='
'
# Succeeds when curl is at least MAJOR.MINOR.
curl_at_least() {
  command -v curl >/dev/null 2>&1 || return 1
  curl_version="$(curl --version 2>/dev/null)" || return 1
  curl_version="${curl_version%%"$NL"*}"
  case "$curl_version" in
    "curl "*) curl_version="${curl_version#curl }" ;;
    *) return 1 ;;
  esac
  curl_version="${curl_version%% *}"
  curl_major="${curl_version%%.*}"
  curl_minor="${curl_version#*.}"
  curl_minor="${curl_minor%%.*}"
  case "$curl_major:$curl_minor" in
    *[!0-9:]*|:*|*:) return 1 ;;
  esac
  [ "$curl_major" -gt "$1" ] || { [ "$curl_major" -eq "$1" ] && [ "$curl_minor" -ge "$2" ]; }
}
# Reads an install token file with the installer's rules into INSTALL_TOKEN.
# Only the path is on a command line, never the token.
read_install_token_file() {
  if [ -L "$1" ] || [ ! -f "$1" ]; then
    echo "install token file must be a regular file, not a symbolic link or directory: $1" >&2
    return 1
  fi
  case "$(ls -ln -- "$1")" in
    -???------*) ;;
    *) echo "install token file must be private (mode 0600 or stricter): $1" >&2; return 1 ;;
  esac
  if [ "$(( $(wc -c < "$1") ))" -gt 4096 ]; then
    echo "install token file is too large: $1" >&2
    return 1
  fi
  INSTALL_TOKEN="$(cat -- "$1")" || return 1
  INSTALL_TOKEN="${INSTALL_TOKEN#"${INSTALL_TOKEN%%[![:space:]]*}"}"
  INSTALL_TOKEN="${INSTALL_TOKEN%"${INSTALL_TOKEN##*[![:space:]]}"}"
  case "$INSTALL_TOKEN" in
    "") echo "install token file is empty: $1" >&2; return 1 ;;
    *[[:space:]]*) echo "install token file must contain one token without spaces or line breaks: $1" >&2; return 1 ;;
  esac
}
# The install token is the one the installer will use: the last
# --install-token-file of the caller's arguments, else R2KERNEL_INSTALL_TOKEN.
# install.sh downloads the installer with it too. The removed --install-token
# option is refused before any download, as the installer refuses it.
INSTALL_TOKEN="${R2KERNEL_INSTALL_TOKEN:-}"
TOKEN_OPTION=""
TOKEN_VALUE=""
expect_token=""
for arg in "$@"; do
  if [ -n "$expect_token" ]; then
    case "$arg" in
      -?*) ;;
      *) TOKEN_OPTION="$expect_token"; TOKEN_VALUE="$arg"; expect_token=""; continue ;;
    esac
    expect_token=""
  fi
  case "$arg" in
    --install-token-file=*) TOKEN_OPTION="${arg%%=*}"; TOKEN_VALUE="${arg#*=}" ;;
    --install-token-file) expect_token="$arg" ;;
    --install-token|--install-token=*)
      echo "unknown argument: --install-token (see --help). Pass --install-token-file PATH (a private 0600 file) or set R2KERNEL_INSTALL_TOKEN." >&2
      exit 1
      ;;
  esac
done
if [ -n "$TOKEN_OPTION" ]; then
  read_install_token_file "$TOKEN_VALUE" || exit 1
fi

# Keep the established curl 7.58 minimum for configured tokens. The first
# control request reads its header from a private file. The fetch routine below
# follows redirects manually and removes credentials and the custom session ID.
# Wget is never used with a token. Check this before any request; never
# download without the configured token.
if [ -n "$INSTALL_TOKEN" ]; then
  if curl_at_least 7 58; then
    FETCH_TOOL=curl
  else
    echo "An install token is configured, but sending it safely requires curl 7.58 or later (private header file and separate credential-free redirect requests). Wget is not used with a token. Install or upgrade curl. No download is attempted without the token." >&2
    exit 1
  fi
elif command -v curl >/dev/null 2>&1; then
  FETCH_TOOL=curl
elif command -v wget >/dev/null 2>&1; then
  # The fetch routine applies the same manual redirect and hash policy to
  # Wget. It never lets Wget forward the session header automatically.
  FETCH_TOOL=wget
else
  echo "Need curl or wget for installation." >&2
  exit 1
fi

DEFAULT_BASE_URL=https://download.r2kernel.org/r2kernel/releases/1.0.1
DEFAULT_DISTRIBUTION_URL=https://download.r2kernel.org
BASE_URL="${R2KERNEL_RELEASE_BASE_URL:-$DEFAULT_BASE_URL}"
# A given distribution URL wins. A given release base URL alone names a static
# mirror, so it replaces the default distribution service instead of being
# ignored. An empty value means unset.
if [ -n "${R2KERNEL_DISTRIBUTION_URL:-}" ]; then
  DISTRIBUTION_URL="$R2KERNEL_DISTRIBUTION_URL"
elif [ -n "${R2KERNEL_RELEASE_BASE_URL:-}" ]; then
  DISTRIBUTION_URL=""
else
  DISTRIBUTION_URL="$DEFAULT_DISTRIBUTION_URL"
fi
if [ -n "$DISTRIBUTION_URL" ]; then
  RELEASE_URL="$DISTRIBUTION_URL"
else
  RELEASE_URL="$BASE_URL"
fi
# Release locations use HTTPS; curl may follow redirects only to HTTPS.
# R2KERNEL_ALLOW_PLAIN_HTTP=1 is the explicit opt-in for a trusted local
# http:// mirror (the installer reads the same value).
CURL_PROTOCOLS="=https"
case "$RELEASE_URL" in
  https://*) ;;
  http://*)
    case "${R2KERNEL_ALLOW_PLAIN_HTTP:-}" in
      1|true|TRUE|yes|YES|y|Y) ;;
      *)
        echo "Release location $RELEASE_URL uses plain HTTP. Use an https:// location, or set R2KERNEL_ALLOW_PLAIN_HTTP=1 only for a trusted local mirror." >&2
        exit 1
        ;;
    esac
    echo "WARNING: R2KERNEL_ALLOW_PLAIN_HTTP is set: downloading from plain HTTP $RELEASE_URL. The install token and install ID are sent unencrypted; artifact hashes are still verified." >&2
    CURL_PROTOCOLS="=http,https"
    ;;
  *)
    echo "Release location must be an https:// URL: $RELEASE_URL" >&2
    exit 1
    ;;
esac
if [ -n "$DISTRIBUTION_URL" ]; then
  echo "R2Kernel download notice: official distribution requests may log install ID, client IP, user agent, artifact, response status, and requested artifact size (the stored size, not bytes received) for delivery, security, license compliance, and release diagnostics." >&2
fi

# The installer runs as a child process, so this cleanup runs on every exit.
INSTALL_TMP_DIR=""
# shellcheck disable=SC2329 # invoked by the EXIT trap
cleanup() {
  if [ -n "$INSTALL_TMP_DIR" ]; then
    rm -rf "$INSTALL_TMP_DIR"
  fi
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
INSTALL_TMP_DIR="$(mktemp -d)"

# The install token never appears on a command line: the shell's printf builtin
# writes it to private files that curl and the installer read. A token file
# given as an argument reaches the installer through the caller's arguments.
CURL_AUTH_HEADER=""
TOKEN_FILE=""
if [ -n "$INSTALL_TOKEN" ]; then
  CURL_AUTH_HEADER="$INSTALL_TMP_DIR/curl-auth-header"
  if [ -z "$TOKEN_OPTION" ]; then
    TOKEN_FILE="$INSTALL_TMP_DIR/install-token"
  fi
  (
    umask 077
    printf 'Authorization: Bearer %s\n' "$INSTALL_TOKEN" > "$CURL_AUTH_HEADER"
    if [ -n "$TOKEN_FILE" ]; then
      printf '%s\n' "$INSTALL_TOKEN" > "$TOKEN_FILE"
    fi
  )
fi
fetch() {
  FETCH_URL="$1"
  FETCH_OUTPUT="$2"
  FETCH_PRIVATE=1
  FETCH_HOPS=0
  FETCH_HEADERS="$INSTALL_TMP_DIR/fetch-headers"
  FETCH_ERRORS="$INSTALL_TMP_DIR/fetch-errors"
  FETCH_URL_FILE="$INSTALL_TMP_DIR/fetch-url"
  FETCH_CURL_CONFIG="$INSTALL_TMP_DIR/fetch-curl-config"
  CR="$(printf '\r')"
  # Every redirect is handled here. curl's cross-origin Authorization removal
  # does not remove our custom installation-session header. Only the first
  # control request carries either header; subsequent hops are credential-free.
  while [ "$FETCH_HOPS" -le 10 ]; do
    FETCH_OK=0
    if [ "$FETCH_TOOL" = "curl" ]; then
      set -- -q -fsS --proto "$CURL_PROTOCOLS" --proto-redir "$CURL_PROTOCOLS" --dump-header "$FETCH_HEADERS" -o "$FETCH_OUTPUT"
      if [ "$FETCH_PRIVATE" = 1 ]; then
        if [ -n "$CURL_AUTH_HEADER" ]; then set -- "$@" -H @"$CURL_AUTH_HEADER"; fi
        set -- "$@" -H "X-R2Kernel-Install-Id: $INSTALL_ID" "$FETCH_URL"
      else
        # A private CDN URL is a bearer capability: keep it off argv as well as
        # diagnostics. Redirect validation below refuses config metacharacters.
        (umask 077; printf 'url = "%s"\n' "$FETCH_URL" > "$FETCH_CURL_CONFIG")
        set -- "$@" --config "$FETCH_CURL_CONFIG"
      fi
      if [ "$FETCH_PRIVATE" = 1 ]; then
        curl "$@" 2> "$FETCH_ERRORS" && FETCH_OK=1
      else
        (unset R2KERNEL_INSTALL_TOKEN R2KERNEL_INSTALL_ID; curl "$@") 2> "$FETCH_ERRORS" && FETCH_OK=1
      fi
    else
      set -- --no-config -qO "$FETCH_OUTPUT" --server-response --max-redirect=0
      if [ "$FETCH_PRIVATE" = 1 ]; then
        set -- "$@" --header="X-R2Kernel-Install-Id: $INSTALL_ID" "$FETCH_URL"
      else
        (umask 077; printf '%s\n' "$FETCH_URL" > "$FETCH_URL_FILE")
        set -- "$@" --input-file="$FETCH_URL_FILE"
      fi
      # Wget returns failure for a refused redirect. Its response header block
      # still identifies that redirect, and stays in the private temp directory.
      if [ "$FETCH_PRIVATE" = 1 ]; then
        wget "$@" 2> "$FETCH_HEADERS" && FETCH_OK=1
      else
        (unset R2KERNEL_INSTALL_TOKEN R2KERNEL_INSTALL_ID; wget "$@") 2> "$FETCH_HEADERS" && FETCH_OK=1
      fi
    fi
    FETCH_STATUS=""
    FETCH_LOCATION=""
    FETCH_LOCATION_COUNT=0
    while IFS= read -r line || [ -n "$line" ]; do
      line="${line%"$CR"}"
      # Wget indents server-response headers; curl does not.
      line="${line#"${line%%[![:space:]]*}"}"
      case "$line" in
        HTTP/*' '*)
          FETCH_STATUS="${line#* }"; FETCH_STATUS="${FETCH_STATUS%% *}"
          FETCH_LOCATION=""; FETCH_LOCATION_COUNT=0 ;;
        [Ll][Oo][Cc][Aa][Tt][Ii][Oo][Nn]:*)
          FETCH_LOCATION_COUNT=$((FETCH_LOCATION_COUNT + 1))
          FETCH_LOCATION="${line#*:}"
          FETCH_LOCATION="${FETCH_LOCATION#"${FETCH_LOCATION%%[![:space:]]*}"}"
          ;;
      esac
    done < "$FETCH_HEADERS"
    if [ "$FETCH_STATUS" = 200 ] && [ "$FETCH_OK" = 1 ]; then return 0; fi
    case "$FETCH_STATUS" in
      301|302|303|307|308) ;;
      *) echo "Installer download request failed; no content is executed." >&2; return 1 ;;
    esac
    [ "$FETCH_LOCATION_COUNT" = 1 ] || { echo "Installer redirect has missing or duplicate locations." >&2; return 1; }
    case "$FETCH_LOCATION" in
      *[[:space:]]*|*'"'*|*'\'*) echo "Installer redirect URL is invalid." >&2; return 1 ;;
    esac
    case "$FETCH_LOCATION" in
      https://*) ;;
      http://*)
        case "$FETCH_URL" in https://*) echo "Installer redirect must not downgrade HTTPS." >&2; return 1 ;; esac
        [ "$CURL_PROTOCOLS" = "=http,https" ] || { echo "Installer redirect must use HTTPS." >&2; return 1; } ;;
      *) echo "Installer redirect must be an absolute HTTPS URL." >&2; return 1 ;;
    esac
    FETCH_AUTHORITY="${FETCH_LOCATION#*://}"
    FETCH_AUTHORITY="${FETCH_AUTHORITY%%/*}"
    FETCH_AUTHORITY="${FETCH_AUTHORITY%%\?*}"
    FETCH_AUTHORITY="${FETCH_AUTHORITY%%\#*}"
    case "$FETCH_AUTHORITY" in ""|*@*) echo "Installer redirect must not contain credentials." >&2; return 1 ;; esac
    FETCH_URL="$FETCH_LOCATION"
    FETCH_PRIVATE=0
    FETCH_HOPS=$((FETCH_HOPS + 1))
  done
  echo "Installer download exceeded its redirect limit." >&2
  return 1
}

INSTALLER_ASSET="r2kernel-installer-$VERSION-$os_name-$arch_name.bin"
INSTALLER_BIN="$INSTALL_TMP_DIR/r2kernel-installer"
if [ -n "$DISTRIBUTION_URL" ]; then
  fetch "$DISTRIBUTION_URL/v1/artifact?version=$VERSION&file=$INSTALLER_ASSET" "$INSTALLER_BIN"
else
  fetch "$BASE_URL/$INSTALLER_ASSET" "$INSTALLER_BIN"
fi
INSTALLER_SHA256_OUTPUT="$(installer_sha256 "$INSTALLER_BIN")"
ACTUAL_INSTALLER_SHA256="${INSTALLER_SHA256_OUTPUT%% *}"
if [ "$ACTUAL_INSTALLER_SHA256" != "$EXPECTED_INSTALLER_SHA256" ]; then
  echo "Installer SHA256 mismatch; refusing to execute downloaded content." >&2
  exit 1
fi
chmod +x "$INSTALLER_BIN"

# Installer arguments: release location, then the caller's arguments
# unchanged, then the release pins, which the caller cannot override.
if [ -n "$TOKEN_FILE" ]; then
  set -- --install-token-file "$TOKEN_FILE" "$@"
fi
set -- --release-tag "$TAG" "$@"
if [ -n "$DISTRIBUTION_URL" ]; then
  set -- --distribution-url "$DISTRIBUTION_URL" --install-id "$INSTALL_ID" "$@"
else
  set -- --base-url "$BASE_URL" "$@"
fi
set -- "$@" --release-manifest-sha256 "$EXPECTED_MANIFEST_SHA256" --release-version "$VERSION"

# The verified installer parses every argument and checks the prefix location
# as the invoking user before any elevation, and reports the effective prefix
# and service choice. Checks that need the release or root run after elevation,
# before anything is downloaded or installed.
CHECK_OUTPUT="$("$INSTALLER_BIN" --internal-check-arguments "$@")" || exit $?
HELP=0
NON_INTERACTIVE=0
PREFIX=""
SYSTEM_SERVICES=""
PREFIX_ROOT_OWNED=0
FORWARD_ENV=""
while IFS= read -r line; do
  case "$line" in
    help=*) HELP="${line#help=}" ;;
    non_interactive=*) NON_INTERACTIVE="${line#non_interactive=}" ;;
    prefix=*) PREFIX="${line#prefix=}" ;;
    system_services=*) SYSTEM_SERVICES="${line#system_services=}" ;;
    prefix_root_owned=*) PREFIX_ROOT_OWNED="${line#prefix_root_owned=}" ;;
    forward_env=*)
      name="${line#forward_env=}"
      case "$name" in
        R2KERNEL_*) ;;
        *) echo "Installer reported an unexpected environment name: $name" >&2; exit 1 ;;
      esac
      case "$name" in
        *[!A-Z0-9_]*) echo "Installer reported an unexpected environment name: $name" >&2; exit 1 ;;
      esac
      FORWARD_ENV="$FORWARD_ENV $name"
      ;;
  esac
done <<CHECK_EOF
$CHECK_OUTPUT
CHECK_EOF
if [ "$HELP" = "1" ]; then
  "$INSTALLER_BIN" --help
  exit 0
fi

prefix_needs_sudo() {
  if [ -e "$PREFIX" ]; then
    [ -w "$PREFIX" ] && return 1
    return 0
  fi
  parent="$(dirname "$PREFIX")"
  while [ ! -e "$parent" ]; do
    parent="$(dirname "$parent")"
  done
  [ -d "$parent" ] && [ -w "$parent" ] && return 1
  return 0
}

needs_root=0
if [ "$SYSTEM_SERVICES" = "install" ]; then
  needs_root=1
elif prefix_needs_sudo; then
  needs_root=1
fi

status=0
if [ "$needs_root" = "1" ] && [ "$(id -u)" != "0" ]; then
  if [ "$PREFIX_ROOT_OWNED" != "1" ]; then
    echo "R2Kernel needs root privileges here (system service registration or an unwritable path), but prefix '$PREFIX' is not entirely root-owned." >&2
    echo "Run without sudo for user prefixes and pass --system-services skip, or choose a root-owned prefix such as the default prefix." >&2
    exit 1
  fi
  if ! command -v sudo >/dev/null 2>&1; then
    echo "R2Kernel install target requires root privileges but sudo was not found." >&2
    echo "Re-run with sudo, choose a writable --prefix, or pass --system-services skip." >&2
    exit 1
  fi
  echo "R2Kernel install requires elevated privileges for prefix '$PREFIX' or system service registration." >&2
  # sudo resets the environment; forward exactly the installer's documented
  # environment values that are set (never the install token).
  set -- "$INSTALLER_BIN" "$@"
  value=""
  for name in $FORWARD_ENV; do
    # Assignment needs no quotes: the value is not split or expanded again.
    eval "value=\${$name}"
    set -- "$name=$value" "$@"
  done
  if [ "$NON_INTERACTIVE" = "1" ]; then
    echo "--non-interactive: using sudo -n, which fails instead of prompting for a password." >&2
    sudo -n env "$@" || status=$?
  else
    echo "Requesting sudo once to continue installation." >&2
    sudo env "$@" || status=$?
  fi
else
  "$INSTALLER_BIN" "$@" || status=$?
fi
exit "$status"
}

main "$@"
