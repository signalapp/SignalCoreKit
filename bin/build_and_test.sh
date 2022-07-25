#!/bin/sh
set -e
set -u
set -o pipefail

XCODE_XCCONFIG_FILE=SignalCoreKit/CI.xcconfig \
  pod lib lint --verbose
