#!/bin/bash

set -e

# This script tests the built test projections, e.g. `weather` for the WeatherSDK.

PROJECTIONS_DIR="./smithy-swift-codegen-test/build/smithyprojections/smithy-swift-codegen-test/"
if [ ! -d "$PROJECTIONS_DIR" ]; then
  exit 1
fi

cd $PROJECTIONS_DIR
PROJECTIONS=$(find . -maxdepth 1 -type d -exec echo {} \;)
for projection in $PROJECTIONS; do
  if [ "$projection" = "." ]; then
    continue
  elif [ "$projection" = "./source" ]; then
    continue
  fi
  echo "Building projection: $projection"
  cd $projection/swift-codegen
  swift build
  cd ../../
done
