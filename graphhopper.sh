#!/usr/bin/env bash
# Strict error handling and debugging
set -Eeuo pipefail
trap 'echo >&2 "Error - exited with status $? at line $LINENO:"; pr -tn $0 | tail -n+$((LINENO - 3)) | head -n7' ERR

# Configuration
readonly MIN_JAVA_VERSION=21
GH_HOME=$(dirname "$(realpath "$0")")

# Java detection with version check
detect_java() {
  local java_cmd="${JAVA_HOME}/bin/java"
  [ -x "$java_cmd" ] || java_cmd="java"
  
  if ! command -v "$java_cmd" >/dev/null 2>&1; then
    echo "Java not found. Please install Java $MIN_JAVA_VERSION or later." >&2
    exit 1
  fi

  local java_version
  java_version=$("$java_cmd" -version 2>&1 | awk -F '"' '/version/ {print $2}')
  if (( $(echo "$java_version" | cut -d. -f1) < MIN_JAVA_VERSION )); then
    echo "Java $MIN_JAVA_VERSION or later required. Found version $java_version" >&2
    exit 1
  fi

  echo "$java_cmd"
}

JAVA=$(detect_java)

print_usage() {
  cat <<EOF
$(basename "$0"): Start a GraphHopper server

Usage:
  $(basename "$0") [OPTIONS]

Options:
  -i, --input <file>       OSM input file location
  --url <url>              Download OSM data from URL (default: data.pbf)
  --import                 Create graph cache for faster starts
  -c, --config <file>      Configuration file (default: \$CONFIG_FILE)
  -o, --graph-cache <dir>  Graph cache directory (default: /data/default-gh)
  --port <port>            Web server port (default: 8989)
  --host <host>            Web server host (default: 0.0.0.0)
  -v, --verbose            Enable verbose output
  -h, --help               Show this help

Environment:
  CONFIG_FILE    Default configuration file path
  JAVA_OPTS      JVM options (default: -Xmx1g -Xms1g)
EOF
}

# Parse arguments
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --import) ACTION=import; shift ;;
    -c|--config) CONFIG="$2"; shift 2 ;;
    -i|--input) FILE="$2"; shift 2 ;;
    --url) URL="$2"; shift 2 ;;
    -o|--graph-cache) GRAPH="$2"; shift 2 ;;
    --port) GH_WEB_OPTS+=" -Ddw.server.application_connectors[0].port=$2"; shift 2 ;;
    --host) GH_WEB_OPTS+=" -Ddw.server.application_connectors[0].bind_host=$2"; shift 2 ;;
    -v|--verbose) VERBOSE=true; shift ;;
    -h|--help) print_usage; exit 0 ;;
    --) shift; break ;;
    -*|--*) echo "Unknown option: $1"; print_usage; exit 1 ;;
    *) break ;;
  esac
done

# Set defaults
: "${ACTION:=server}"
: "${GRAPH:=/data/default-gh}"
: "${CONFIG:=${CONFIG_FILE:-config-example.yml}}"
: "${JAVA_OPTS:=-Xmx1g -Xms1g}"
: "${JAR:=$(find "$GH_HOME" -maxdepth 1 -type f -name '*.jar' -print -quit)}"

# Validate requirements
[ -f "$JAR" ] || { echo "No JAR file found in $GH_HOME"; exit 1; }
[ -n "$JAR" ] || { echo "Multiple JAR files found - specify with JAR environment variable"; exit 1; }

# Download OSM data if URL provided
if [ -n "${URL:-}" ]; then
  echo "Downloading OSM data from $URL"
  wget ${VERBOSE:+--verbose} --progress=bar:force -O "${FILE:-data.pbf}" "$URL" || {
    echo "Failed to download OSM data"; exit 1
  }
fi

# Create directories with error checking
mkdir -p "$(dirname "$GRAPH")" || { echo "Failed to create graph directory"; exit 1; }

# Build command arguments
CMD_ARGS=(
  "$JAVA"
  $JAVA_OPTS
  ${FILE:+-Ddw.graphhopper.datareader.file="$FILE"}
  -Ddw.graphhopper.graph.location="$GRAPH"
  $GH_WEB_OPTS
  -jar "$JAR"
  "$ACTION"
  "$CONFIG"
)

# Execute with proper cleanup
if $VERBOSE; then
  echo "## Starting GraphHopper ${ACTION} ##"
  echo "Java: $(command -v "$JAVA")"
  echo "Version: $($JAVA -version 2>&1 | head -n1)"
  echo "JAR: $JAR"
  echo "Command:"
  printf '%s\n' "${CMD_ARGS[@]}"
fi

cleanup() {
  if [ -f "${FILE:-}" ]; then
    rm -f "$FILE"
  fi
}

trap cleanup EXIT
exec "${CMD_ARGS[@]}"
