#!/bin/bash

# downloads the preview_build binary, if not present, and then runs it

set -euo pipefail

if [ ! -f preview_build ]; then
  echo "preview_build doesn't exist, downloading it..."
  curl -LO https://artifacts.us-east-1.prod.workshops.aws/v2/cli/osx/preview_build
  chmod +x preview_build
fi

echo "running preview_build with all of your parameters..."
./preview_build "$@"
