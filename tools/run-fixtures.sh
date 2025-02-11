#!/usr/bin/env bash

set -eEuo pipefail

# Put script directory on the directories stack, so the script is executed in its directory
pushd "$(dirname "$0")" >/dev/null

# Change the working directory to the project's root
cd ..

tenant_graphql_api_url="http://api.edgehog.localhost/tenants/test/api"
tenant_jwt=$(cat backend/priv/repo/seeds/keys/tenant_jwt.txt)
fixture_dir="fixtures"

for fixture in "$fixture_dir"/*.json; do
  filename=$(basename -- "$fixture")

  echo "Running fixture: $filename"

  curl -s -X POST "$tenant_graphql_api_url" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $tenant_jwt" \
    --data "@$fixture"
done

# Restore the directory from which the script was called as the working directory
popd >/dev/null
