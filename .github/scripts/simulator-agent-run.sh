#!/bin/bash
#
# Launches the iOS sample app ("Integration Tests Runner.app") in a booted simulator, waits until
# the Atatus iOS agent has actually reported data, and captures a screenshot plus the agent's own
# debug log.
#
# Two modes:
#
#   --mode mock  (default)  The app reports to the repository's local `http-server-mock` intake.
#                           Delivery is proven by reading the recorded requests back.
#   --mode demo             The app reports to a real Atatus intake, configured through
#                           `ATATUS_SERVER_URL`. Delivery is proven from the intake response codes
#                           the agent logs, since the payloads cannot be read back from CI.
#
# Usage:
#   simulator-agent-run.sh --label <name> --scenario <TestScenario class> \
#                          [--mode mock|demo] --expect <product> [--expect <product> ...]
#
# <product> is one of: rum, logs, traces.
#
# Required environment:
#   SIMULATOR_UDID   UDID of the booted simulator
#   APP_BUNDLE_ID    bundle identifier of the sample app
#   ARTIFACTS_DIR    directory to write screenshots and logs into
#   MOCK_SERVER_URL  base URL of the running http-server-mock intake (mock mode only)
#
# Optional environment, forwarded to the app process in demo mode:
#   ATATUS_SERVER_URL, AT_TEST_LICENSE_KEY, AT_TEST_RUM_APPLICATION_ID,
#   AT_TEST_SERVICE, AT_TEST_ENV, AT_TEST_TRACED_REQUEST_URL

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPLOAD_TIMEOUT="${AGENT_UPLOAD_TIMEOUT:-180}"
DEMO_SETTLE_SECONDS="${AGENT_DEMO_SETTLE_SECONDS:-60}"

LABEL=""
SCENARIO=""
MODE="mock"
EXPECTED=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --label) LABEL="$2"; shift 2 ;;
        --scenario) SCENARIO="$2"; shift 2 ;;
        --mode) MODE="$2"; shift 2 ;;
        --expect) EXPECTED+=("$2"); shift 2 ;;
        *) echo "::error::Unknown argument: $1"; exit 1 ;;
    esac
done

if [[ -z "$LABEL" || -z "$SCENARIO" || ${#EXPECTED[@]} -eq 0 ]]; then
    echo "::error::--label, --scenario and at least one --expect are required."
    exit 1
fi
if [[ "$MODE" != "mock" && "$MODE" != "demo" ]]; then
    echo "::error::--mode must be 'mock' or 'demo', got '$MODE'."
    exit 1
fi

: "${SIMULATOR_UDID:?SIMULATOR_UDID must be set}"
: "${APP_BUNDLE_ID:?APP_BUNDLE_ID must be set}"
: "${ARTIFACTS_DIR:?ARTIFACTS_DIR must be set}"

mkdir -p "$ARTIFACTS_DIR/screenshots" "$ARTIFACTS_DIR/logs" "$ARTIFACTS_DIR/intake"

echo "::group::Run sample app scenario '$SCENARIO' ($LABEL, $MODE mode)"

# Environment handed to the app process. `simctl` forwards anything prefixed with SIMCTL_CHILD_.
declare -a CHILD_ENV=("SIMCTL_CHILD_AT_TEST_SCENARIO_CLASS_NAME=$SCENARIO")
declare -a SESSION_LABELS=()
declare -a SESSION_IDS=()

if [[ "$MODE" == "mock" ]]; then
    : "${MOCK_SERVER_URL:?MOCK_SERVER_URL must be set in mock mode}"

    # One recording session per product, so each product's uploads can be awaited independently.
    CONFIG_ARGS=()
    for product in "${EXPECTED[@]}"; do
        session_id="$(uuidgen)"
        case "$product" in
            rum)    CONFIG_ARGS+=(--rum "$session_id") ;;
            logs)   CONFIG_ARGS+=(--logs "$session_id") ;;
            traces) CONFIG_ARGS+=(--traces "$session_id") ;;
            *) echo "::error::Unknown product '$product' (expected one of: rum, logs, traces)"; exit 1 ;;
        esac
        SESSION_LABELS+=("$product")
        SESSION_IDS+=("$session_id")
        echo "  $product intake session: $MOCK_SERVER_URL/$session_id"
    done

    SERVER_MOCK_CONFIGURATION="$(
        python3 "$SCRIPT_DIR/mock_intake.py" --server "$MOCK_SERVER_URL" config "${CONFIG_ARGS[@]}"
    )"
    CHILD_ENV+=("SIMCTL_CHILD_AT_TEST_SERVER_MOCK_CONFIGURATION=$SERVER_MOCK_CONFIGURATION")
    # `customEndpoint` only redirects feature uploads. The logs heartbeat the agent polls on start
    # is built from `AtatusSite.serverUrl`, which the SDK reads from ATATUS_SERVER_URL — without
    # this it goes to the production intake, answers `allowAgent: false`, and no log is uploaded.
    CHILD_ENV+=("SIMCTL_CHILD_ATATUS_SERVER_URL=$MOCK_SERVER_URL")
else
    # No server-mock configuration: with no `customEndpoint`, every feature falls back to
    # `AtatusSite.serverUrl`, which the agent reads from `ATATUS_SERVER_URL`.
    : "${ATATUS_SERVER_URL:?ATATUS_SERVER_URL must be set in demo mode}"
    : "${AT_TEST_LICENSE_KEY:?AT_TEST_LICENSE_KEY must be set in demo mode}"

    echo "  Reporting to $ATATUS_SERVER_URL"
    # Referenced by name rather than indirectly: `${!var:-}` is not portable to the bash 3.2 that
    # ships with macOS.
    add_child_env() {
        if [[ -n "$2" ]]; then
            CHILD_ENV+=("SIMCTL_CHILD_$1=$2")
        fi
    }
    add_child_env ATATUS_SERVER_URL "${ATATUS_SERVER_URL:-}"
    add_child_env AT_TEST_LICENSE_KEY "${AT_TEST_LICENSE_KEY:-}"
    add_child_env AT_TEST_RUM_APPLICATION_ID "${AT_TEST_RUM_APPLICATION_ID:-}"
    add_child_env AT_TEST_SERVICE "${AT_TEST_SERVICE:-}"
    add_child_env AT_TEST_ENV "${AT_TEST_ENV:-}"
    add_child_env AT_TEST_TRACED_REQUEST_URL "${AT_TEST_TRACED_REQUEST_URL:-}"
fi

# Capture the agent's own diagnostics. `consolePrint` logs to the `atatus-sdk-ios` subsystem with
# `.private` redaction, so private data logging is enabled first — otherwise every message is
# recorded as `<private>`, including the intake response codes checked below.
xcrun simctl spawn "$SIMULATOR_UDID" log config --mode "private_data:on" >/dev/null 2>&1 || \
    echo "  (could not enable private_data logging; agent messages may be redacted)"

LOG_FILE="$ARTIFACTS_DIR/logs/agent-oslog-$LABEL.log"
xcrun simctl spawn "$SIMULATOR_UDID" log stream \
    --level debug --style syslog \
    --predicate 'subsystem == "atatus-sdk-ios" OR processImagePath CONTAINS "Integration Tests Runner"' \
    > "$LOG_FILE" 2>&1 &
LOG_STREAM_PID=$!

cleanup() {
    kill "$LOG_STREAM_PID" 2>/dev/null || true
    xcrun simctl terminate "$SIMULATOR_UDID" "$APP_BUNDLE_ID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

xcrun simctl terminate "$SIMULATOR_UDID" "$APP_BUNDLE_ID" >/dev/null 2>&1 || true

echo "▸ xcrun simctl launch $SIMULATOR_UDID $APP_BUNDLE_ID"
set +e
LAUNCH_OUTPUT="$(env "${CHILD_ENV[@]}" \
    xcrun simctl launch "$SIMULATOR_UDID" "$APP_BUNDLE_ID" IS_RUNNING_UI_TESTS 2>&1)"
LAUNCH_STATUS=$?
set -e
echo "$LAUNCH_OUTPUT"

if [[ $LAUNCH_STATUS -ne 0 ]]; then
    echo "::error::The sample app failed to launch in the simulator."
    exit 1
fi

APP_PID="${LAUNCH_OUTPUT##*: }"
if [[ "$APP_PID" =~ ^[0-9]+$ ]]; then
    sleep 3
    if ! ps -p "$APP_PID" >/dev/null 2>&1; then
        echo "::error::The sample app exited immediately after launch (pid $APP_PID). \
Agent initialization most likely crashed — see $LOG_FILE."
        exit 1
    fi
    echo "  App is running (pid $APP_PID)."
fi

if [[ "$MODE" == "mock" ]]; then
    # Prove the agent initialized: nothing reaches the intake unless `Atatus.initialize` succeeded
    # and the product was enabled. This is also where batching/upload is waited out.
    for index in "${!SESSION_IDS[@]}"; do
        python3 "$SCRIPT_DIR/mock_intake.py" --server "$MOCK_SERVER_URL" wait \
            --session "${SESSION_IDS[$index]}" \
            --label "${SESSION_LABELS[$index]} ($LABEL)" \
            --min-requests 1 \
            --timeout "$UPLOAD_TIMEOUT"
    done
else
    echo "  Letting the agent generate and flush data for ${DEMO_SETTLE_SECONDS}s..."
    sleep "$DEMO_SETTLE_SECONDS"
fi

SCREENSHOT="$ARTIFACTS_DIR/screenshots/$LABEL.png"
xcrun simctl io "$SIMULATOR_UDID" screenshot --type=png "$SCREENSHOT"
echo "  Screenshot: $SCREENSHOT"

if [[ "$MODE" == "mock" ]]; then
    python3 "$SCRIPT_DIR/mock_intake.py" --server "$MOCK_SERVER_URL" dump \
        --output "$ARTIFACTS_DIR/intake/recorded-requests-$LABEL.json"
else
    # Flush the log stream before reading it.
    kill "$LOG_STREAM_PID" 2>/dev/null || true
    sleep 2
    REQUIRE_ARGS=()
    for product in "${EXPECTED[@]}"; do
        REQUIRE_ARGS+=(--require "$product")
    done
    python3 "$SCRIPT_DIR/check_upload_status.py" --log "$LOG_FILE" "${REQUIRE_ARGS[@]}"
fi

echo "::endgroup::"
