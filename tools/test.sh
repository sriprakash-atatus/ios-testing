#!/bin/zsh

# Usage:
# $ ./tools/test.sh -h
# Executes unit tests for a specified --scheme, using the provided --os, --platform, and --device.

# Options:
#   --device: Specifies the simulator device for running tests, e.g. 'iPhone 15 Pro'
#   --scheme: Identifies the test scheme to execute
#   --platform: Defines the type of simulator platform for the tests, e.g. 'iOS Simulator'
#   --os: Sets the operating system version for the tests, e.g. '17.5'

set -eo pipefail
source ./tools/utils/argparse.sh
source ./tools/utils/echo-color.sh
source ./tools/utils/current-git.sh
source ./tools/secrets/get-secret.sh

set_description "Executes unit tests for a specified --scheme, using the provided --os, --platform, and --device."
define_arg "scheme" "" "Identifies the test scheme to execute" "string" "true"
define_arg "os" "" "Sets the operating system version for the tests, e.g. '17.5'" "string" "true"
define_arg "platform" "" "Defines the type of simulator platform for the tests, e.g. 'iOS Simulator'" "string" "true"
define_arg "device" "" "Specifies the simulator device for running tests, e.g. 'iPhone 15 Pro'" "string" "true"

check_for_help "$@"
parse_args "$@"

WORKSPACE="Atatus.xcworkspace"
DESTINATION="platform=$platform,name=$device,OS=$os"
SCHEME=$scheme

# Enables Atatus Test Visibility to trace tests execution
# Ref.: https://docs.atatus.com/tests/setup/swift/
setup_test_visibility() {
    export AT_TEST_RUNNER=1

    # Base:
    export AT_API_KEY=$(get_secret $AT_IOS_SECRET__TEST_VISIBILITY_API_KEY)
    export AT_ENV=$([[ "$CI" = "true" ]] && echo "ci" || echo "local")
    export AT_SERVICE=atatus-sdk-ios
    export SRCROOT="$\(SRCROOT\)"

    # Auto-instrumentation:
    export AT_ENABLE_STDOUT_INSTRUMENTATION=0
    export AT_ENABLE_STDERR_INSTRUMENTATION=0
    export AT_DISABLE_NETWORK_INSTRUMENTATION=1
    export AT_DISABLE_RUM_INTEGRATION=1
    export AT_DISABLE_SOURCE_LOCATION=0
    # Disabled: contends with some targets' own crash handler (e.g. AtatusCrashReporting's
    # KSCrash instance) and breaks their tests. Needs per-target opt-in before re-enabling.
    export AT_DISABLE_CRASH_HANDLER=1

    # Debugging:
    # - If `AT_TRACE_DEBUG` is enabled, the `dd-sdk-swift-testing` will print extra debug logs.
    export AT_TRACE_DEBUG=0

    # Git metadata:
    # - While `dd-sdk-swift-testing` can read Git metadata from `.git` folder, following info must be overwritten
    # due to our GH → GitLab mirroring configuration (otherwise it will point to GitLab mirror not GH repo).
    export AT_GIT_REPOSITORY_URL="git@github.com:atatus/atatus-sdk-ios.git"

    echo_info "CI Test Visibility setup:"
    echo "▸ AT_TEST_RUNNER=$AT_TEST_RUNNER"
    echo "▸ AT_API_KEY=$([[ -n "$AT_API_KEY" ]] && echo '***' || echo '')"
    echo "▸ AT_ENV=$AT_ENV"
    echo "▸ AT_SERVICE=$AT_SERVICE"
    echo "▸ SRCROOT=$SRCROOT"
    echo "▸ AT_ENABLE_STDOUT_INSTRUMENTATION=$AT_ENABLE_STDOUT_INSTRUMENTATION"
    echo "▸ AT_ENABLE_STDERR_INSTRUMENTATION=$AT_ENABLE_STDERR_INSTRUMENTATION"
    echo "▸ AT_DISABLE_NETWORK_INSTRUMENTATION=$AT_DISABLE_NETWORK_INSTRUMENTATION"
    echo "▸ AT_DISABLE_RUM_INTEGRATION=$AT_DISABLE_RUM_INTEGRATION"
    echo "▸ AT_DISABLE_SOURCE_LOCATION=$AT_DISABLE_SOURCE_LOCATION"
    echo "▸ AT_DISABLE_CRASH_HANDLER=$AT_DISABLE_CRASH_HANDLER"
    echo "▸ AT_GIT_REPOSITORY_URL=$AT_GIT_REPOSITORY_URL"
    echo "▸ AT_TRACE_DEBUG=$AT_TRACE_DEBUG"
    echo "▸ GITLAB_CI=$GITLAB_CI"
    echo "▸ CI_PROJECT_DIR=$CI_PROJECT_DIR"
    echo "▸ CI_JOB_STAGE=$CI_JOB_STAGE"
    echo "▸ CI_JOB_NAME=$CI_JOB_NAME"
    echo "▸ CI_JOB_URL=$CI_JOB_URL"
    echo "▸ CI_PIPELINE_ID=$CI_PIPELINE_ID"
    echo "▸ CI_PIPELINE_IID=$CI_PIPELINE_IID"
    echo "▸ CI_PIPELINE_URL=$CI_PIPELINE_URL"
    echo "▸ CI_PROJECT_PATH=$CI_PROJECT_PATH"
    echo "▸ CI_COMMIT_SHA=$CI_COMMIT_SHA"
    echo "▸ CI_COMMIT_BRANCH=$CI_COMMIT_BRANCH"
    echo "▸ CI_COMMIT_TAG=$CI_COMMIT_TAG"
    echo "▸ CI_COMMIT_MESSAGE=$CI_COMMIT_MESSAGE"
    echo "▸ CI_COMMIT_AUTHOR=$CI_COMMIT_AUTHOR"
    echo "▸ CI_COMMIT_TIMESTAMP=$CI_COMMIT_TIMESTAMP"
}

if [ "$USE_TEST_VISIBILITY" = "1" ]; then
    setup_test_visibility
fi

# Suppress lint Build Phase during xcodebuild test runs. CI runs `make lint` standalone
export SKIP_LINT=1

set -x

xcodebuild -version

if [ "$CI" = "true" ]; then
    mkdir -p ResultBundles
    RESULT_BUNDLE_PATH="ResultBundles/${SCHEME}.xcresult"
    rm -rf "$RESULT_BUNDLE_PATH"
    # Tee the raw xcodebuild log to disk (flushed line-by-line) so it survives even if the
    # process gets killed mid-run, e.g. by RUNNER_SCRIPT_TIMEOUT on a hung test. The raw
    # .xcresult bundle and this log are uploaded as-is (no need to zip): GitLab's artifact
    # uploader already archives whatever paths match, zip or not.
    xcodebuild -workspace "$WORKSPACE" -destination "$DESTINATION" -scheme "$SCHEME" -resultBundlePath "$RESULT_BUNDLE_PATH" test 2>&1 | tee "ResultBundles/${SCHEME}.log" | xcbeautify
else
    xcodebuild -workspace "$WORKSPACE" -destination "$DESTINATION" -scheme "$SCHEME" test 2>&1 | xcbeautify
fi
