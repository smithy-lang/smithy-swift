#!/bin/bash

# Stop on any failed step of this script
set -eo pipefail

# Regenerates the test SDKs.  For use during development or before testing only.
# May be used on Mac or Linux.

# Run this script from the smithy-swift project root directory.

# Delete all previous Smithy build products
rm -rf test-sdks/build/smithyprojections/test-sdks/*

# Regenerate code
./gradlew -p test-sdks build

