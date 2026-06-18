#!/bin/bash

# Stop on any failed step of this script
set -eo pipefail

# Generates the test SDKs for serde performance, then runs performance tests.
#
# For use during development or before testing only.
# May be used on Mac or Linux.

# Run this script from the smithy-swift project root directory.

# Delete previous test reports
rm -rf instance-report.json

# Delete all previous serde-benchmark Swift build products
rm -rf serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkAWSJSONRPC10/swift-codegen/*
rm -rf serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkAWSQuery/swift-codegen/*
rm -rf serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkAWSRestJSON/swift-codegen/*
rm -rf serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkAWSRestXML/swift-codegen/*
rm -rf serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkSmithyRPCV2CBOR/swift-codegen/*

# Regenerate all serde-benchmark test SDKs
./gradlew -p serde-benchmark build

# Run tests, using release config, for each serde performance test SDK
cd serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkAWSJSONRPC10/swift-codegen/SerdeBenchmarkAWSJSONRPC10
swift test -c release
cd ../../../../../..

cd serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkAWSQuery/swift-codegen/SerdeBenchmarkAWSQuery
swift test -c release
cd ../../../../../..

cd serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkAWSRestJSON/swift-codegen/SerdeBenchmarkAWSRestJSON
swift test -c release
cd ../../../../../..

cd serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkAWSRestXML/swift-codegen/SerdeBenchmarkAWSRestXML
swift test -c release
cd ../../../../../..

cd serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkSmithyRPCV2CBOR/swift-codegen/SerdeBenchmarkSmithyRPCV2CBOR
swift test -c release
cd ../../../../../..

# Cumulative results will be written to the root of the smithy-swift project, named instance-report.json
