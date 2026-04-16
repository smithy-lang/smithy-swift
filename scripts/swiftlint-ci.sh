#!/bin/bash
#
# Runs swiftlint the same way CI does, including the analyzer pass on compiled code.
# Usage: ./scripts/swiftlint-ci.sh [--analyze-only | --lint-only] [--fix]
#
set -euo pipefail
cd "$(dirname "$0")/.."

MODE="all"
FIX=""
for arg in "$@"; do
    case "$arg" in
        --fix)           FIX="--fix" ;;
        --lint-only)     MODE="lint" ;;
        --analyze-only)  MODE="analyze" ;;
        -h|--help)
            echo "Usage: $0 [--analyze-only | --lint-only] [--fix]"
            exit 0
            ;;
        *) echo "Unknown arg: $arg"; exit 1 ;;
    esac
done

run_lint() {
    swiftlint --strict $FIX
}

run_analyze() {
    xcodebuild -scheme smithy-swift-Package -destination platform=macOS > xcodebuild.log 2>&1 || {
        echo "xcodebuild failed. See xcodebuild.log"
        exit 1
    }
    # Filter platform-specific compiler errors that are false positives when analyzing on macOS
    grep -v "no such module 'FoundationNetworking'" xcodebuild.log \
        | grep -v "no such module 'Glibc'" \
        | grep -v "Cannot use a an operating system we do not support" \
        > xcodebuild-filtered.log
    swiftlint analyze --strict --compiler-log-path xcodebuild-filtered.log $FIX
}

case "$MODE" in
    lint)    run_lint ;;
    analyze) run_analyze ;;
    all)     run_lint; run_analyze ;;
esac
