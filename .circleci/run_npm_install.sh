#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

# Runs `npm ci` if the node_modules cache is not fresh.
#
# The cache staleness is determined by check_node_modules_cache_freshness.sh.

echo "node version: $(node --version)"
echo "npm version: $(npm --version)"
echo

if [[ "${NODE_MODULES_CACHE_STATUS}" == 'fresh' ]]; then
  echo 'Skipping `npm install` because package-lock.json has not changed.'
  exit 0
fi

# Move to /dev/shm because we want the speed up of having node_modules in /dev/shm.
mkdir -p /dev/shm/ci/ci_speed_test
cp /home/ci/ci_speed_test/{package.json,package-lock.json} /dev/shm/ci/ci_speed_test
cd /dev/shm/ci/ci_speed_test

# Make a backup so we can see if npm ci changed package-lock.json.
cp package-lock.json old-package-lock.json

# Install node_modules.
npm ci --ignore-scripts --prefer-offline --no-audit

# npm ci deletes node_modules before starting, so this needs to come after npm ci.
echo
echo "Writing hash ${NODE_MODULES_CACHE_HASH} to ${NODE_MODULES_CACHE_HASH_FILE}"
echo "${NODE_MODULES_CACHE_HASH}" > "${NODE_MODULES_CACHE_HASH_FILE}"

# With npm ci, this should never happen.  npm install, however, may modify package-lock.json.
# See https://stackoverflow.com/a/45566871/30900.
if ! cmp --silent old-package-lock.json package-lock.json; then
  echo
  echo '# Warning: npm ci changed package-lock.json'
  echo '# ========================================='
  echo
  echo '`npm ci` should never modify package-lock.json. The build fails if package-lock.json'
  echo 'changes because we use the SHA1 hash of package-lock.json as the cache key for '
  ehco 'node_modules.  If package-lock.json changed, subsequent jobs in this workflow will'
  echo 'not be able to restore the node_modules cache. The diff is below:'
  echo
  git --no-pager diff --no-index old-package-lock.json package-lock.json || true
  exit 1
fi
