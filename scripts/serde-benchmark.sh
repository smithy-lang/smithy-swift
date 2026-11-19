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
rm -rf serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkAWSJSONRPC10/swift-codegen/SerdeBenchmarkAWSJSONRPC10/*
rm -rf serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkAWSQuery/swift-codegen/SerdeBenchmarkAWSQuery/*
rm -rf serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkAWSRestJSON/swift-codegen/SerdeBenchmarkAWSRestJSON/*
rm -rf serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkAWSRestXML/swift-codegen/SerdeBenchmarkAWSRestXML/*
rm -rf serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkSmithyRPCV2CBOR/swift-codegen/SerdeBenchmarkSmithyRPCV2CBOR/*

# Regenerate all serde-benchmark test SDKs
./gradlew -p serde-benchmark build

# Run tests, using release config, for each serde performance test SDK.
# Benchmark tests are Swift Testing tests, which run in parallel by default; --no-parallel keeps
# benchmarks from contending with each other for CPU and from racing on the results file.
cd serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkAWSJSONRPC10/swift-codegen/SerdeBenchmarkAWSJSONRPC10
swift test -c release --no-parallel
cd ../../../../../../..

cd serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkAWSQuery/swift-codegen/SerdeBenchmarkAWSQuery
swift test -c release --no-parallel
cd ../../../../../../..

cd serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkAWSRestJSON/swift-codegen/SerdeBenchmarkAWSRestJSON
swift test -c release --no-parallel
cd ../../../../../../..

cd serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkAWSRestXML/swift-codegen/SerdeBenchmarkAWSRestXML
swift test -c release --no-parallel
cd ../../../../../../..

cd serde-benchmark/build/smithyprojections/serde-benchmark/SerdeBenchmarkSmithyRPCV2CBOR/swift-codegen/SerdeBenchmarkSmithyRPCV2CBOR
swift test -c release --no-parallel
cd ../../../../../../..

# Cumulative results will be written to the root of the smithy-swift project, named instance-report.json
