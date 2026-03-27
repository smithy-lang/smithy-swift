#!/bin/bash

# Stop on any failed step of this script
set -eo pipefail

# Regenerates the test SDKs.  For use during development only.
# Arguments passed into this script are passed on to the manifest generator.

# May be used on Mac or Linux.
# When run on Mac, kills Xcode before codegen & restarts it after.

# Run this script from the smithy-swift project root directory.

# Delete all previous Smithy build products
rm -rf test-sdks/build/smithyprojections/test-sdks/*

# Regenerate code
./gradlew -p test-sdks build

# Delete Package.swift for test SDKs so generated files are accessible in Xcode
rm -rf test-sdks/build/smithyprojections/test-sdks/rpcv2cbor/swift-codegen/Package.swift

# Add generated files to Git so they may be committed (-f option is used because build/ is .gitignored)
git add -f test-sdks/build/smithyprojections/test-sdks/rpcv2cbor/swift-codegen/Sources/RPCv2CBORTestSDK/*
