#!/bin/bash

# Stop on any failed step of this script
set -eo pipefail

# Regenerates the test SDKs.  For use during development or before testing only.
# May be used on Mac or Linux.

# Run this script from the smithy-swift project root directory.

# Delete all previous Smithy build products
rm -rf serde-benchmark/build/smithyprojections/serde-benchmark/*

# Regenerate code
./gradlew -p serde-benchmark build

# Delete Package.swift for test SDKs so generated files are accessible in Xcode
rm -rf serde-benchmark/build/smithyprojections/serde-benchmark/awsjson/swift-codegen/Package.swift
rm -rf serde-benchmark/build/smithyprojections/serde-benchmark/rpcv2cbor/swift-codegen/Package.swift
rm -rf serde-benchmark/build/smithyprojections/serde-benchmark/waiters/swift-codegen/Package.swift
