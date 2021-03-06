#! /bin/zsh

set -euo pipefail

logInfo () {
    echo "\033[32m$1\033[0m" >&2
}

logWarning () {
    echo "\033[33m$1\033[0m" >&2
}

logError () {
    echo "\033[31m$1\033[0m" >&2
}

# Make sure all parameters are set correctly.
logInfo "RFCI_PRODUCT_NAME = $RFCI_PRODUCT_NAME"

readonly RFCI_TASK="${RFCI_TASK:? is not set.}"
logInfo "RFCI_TASK = $RFCI_TASK"

readonly RFCI_STAGE="${1:?STAGE is not set.}"
logInfo "RFCI_STAGE = $RFCI_STAGE"

readonly RFWorkspace=${RFWorkspace:="$RFCI_PRODUCT_NAME.xcworkspace"}
logInfo "RFWorkspace = $RFWorkspace"

TRAVIS_COMMIT_MESSAGE=${TRAVIS_COMMIT_MESSAGE:="$(logWarning 'TRAVIS_COMMIT_MESSAGE is not set, leave it blank.')"}
TRAVIS_BRANCH=${TRAVIS_BRANCH:="$(logWarning 'TRAVIS_BRANCH is not set, leave it blank.')"}

echo ""

# Run test
# $1 scheme
# $2 destination
XC_Test() {
    xcodebuild test -enableCodeCoverage YES -workspace "$RFWorkspace" -scheme "$1" -destination "$2" ONLY_ACTIVE_ARCH=NO GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES | xcpretty
}

# Run macOS test
XC_TestMac() {
    xcodebuild test -enableCodeCoverage YES -workspace "$RFWorkspace" -scheme "Test-macOS" GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES | xcpretty
}

# Run watchOS test
XC_TestWatch() {
    xcodebuild build -workspace "$RFWorkspace" -scheme "Target-watchOS" ONLY_ACTIVE_ARCH=NO | xcpretty
}

# Run tests on iOS Simulator.
# The destinations are the first and last available destination that are automatically detected.
# $1 scheme
XC_TestAutoIOS() {
    logInfo "Detecting destinations..."
    destList=$(xcodebuild -showdestinations -workspace "$RFWorkspace" -scheme "$1" | grep "iOS Simulator")
    destCount=$(echo "$destList" | wc -l)
    destFirst=$(echo "$destList" | head -1)
    destLast=$(echo "$destList" | tail -2 | head -1)
    destFirstID=$(echo "$destFirst" | awk 'match($0,/id\:[0-9A-F-]+/){ print substr($0,RSTART+3,RLENGTH-3) }')
    destLastID=$(echo "$destLast" | awk 'match($0,/id\:[0-9A-F-]+/){ print substr($0,RSTART+3,RLENGTH-3) }')

    logWarning "Test on simulator (id: $destFirstID)."
    XC_Test "$1" "platform=iOS Simulator,id=$destFirstID"

    logWarning "Test on simulator (id: $destLastID)."
    XC_Test "$1" "platform=iOS Simulator,id=$destLastID"
}

STAGE_SETUP() {
    gem install cocoapods --no-document
}

STAGE_MAIN() {
    if [ "$RFCI_TASK" = "POD_LINT" ]; then
        if [[ "$TRAVIS_COMMIT_MESSAGE" = *"[skip lint]"* ]]; then
            logWarning "Skip pod lint"
        else
            if [[ "$TRAVIS_BRANCH" =~ ^[0-9]+\.[0-9]+ ]]; then
                logWarning "Release the podspec."
                pod trunk push "$RFCI_PRODUCT_NAME.podspec"
            elif [ "$TRAVIS_BRANCH" = "master" ]; then
                logInfo "Lint the podspec."
                pod lib lint --fail-fast
            else
                logInfo "Lint the podspec."
                pod lib lint --fail-fast --allow-warnings
            fi
        fi

    elif [ "$RFCI_TASK" = "Xcode10" ]; then
        pod install
        XC_TestMac
        XC_TestAutoIOS "Test-iOS"
    else
        logError "Unexpected CI task: $RFCI_TASK"
    fi
}

STAGE_SUCCESS() {
    if [ "${RFCI_COVERAGE-}" = "1" ]; then
        curl -s https://codecov.io/bash | bash -s
    fi
}

STAGE_FAILURE() {
    if [[ "$RFCI_TASK" == Xcode* ]]; then
        cat -n ~/Library/Logs/DiagnosticReports/xctest*.crash
    fi
}

"STAGE_$RFCI_STAGE"
