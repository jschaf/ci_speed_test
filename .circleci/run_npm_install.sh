#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

# Installs the node modules for this project.
#
# The script halts the CircleCI job that runs this script if the node_modules
# cache is fresh. The cache is fresh if the node_modules cache key for the
# current state of the repo matches the cache key for the node_modules
# precheck key.

echo "node version: $(node --version)"
echo "npm version: $(npm --version)"
echo

current_hash_file='/home/ci/ci_speed_test/.circleci/node_modules_cache_key'
if [[ ! -e "${current_hash_file}" ]]; then
  echo "ERROR: node_modules cache key file not found at ${current_hash_file}."
  echo '   The cache key file should be created in the checkout_repo step.'
fi
current_hash="$(< "${current_hash_file}")"

precheck_hash_file='/home/ci/ci_speed_test/.circleci/node_modules_precheck_cache_key'
precheck_hash='<none>'
precheck_status='stale'
if [[ -f "${precheck_hash_file}" ]]; then
  precheck_hash="$(< ${precheck_hash_file})"
  if [[ "${current_hash}" == "${precheck_hash}" ]]; then
    precheck_status='fresh'
  fi
fi

printf 'value from %-55s %s\n' "${current_hash_file}" "${current_hash}"
printf 'value from %-55s %s\n' "${precheck_hash_file}" "${precheck_hash}"
echo "cache_status: ${precheck_status}"

if [[ "${precheck_status}" == 'fresh' ]]; then
  printf '\nHalting this job because the cache is fresh.\n'
  circleci step halt
  exit 0
fi

printf '
# Installing node_modules
=========================\n\n'

# Move to /dev/shm because for IO speedup.
mkdir -p /dev/shm/ci/ci_speed_test
cp /home/ci/ci_speed_test/package-lock.json /dev/shm/ci/ci_speed_test
cp /home/ci/ci_speed_test/package.json /dev/shm/ci/ci_speed_test
cd /dev/shm/ci/ci_speed_test

# Make a backup to check if npm ci changed package-lock.json.
cp package-lock.json old-package-lock.json

# Install node_modules.
npm ci --ignore-scripts --prefer-offline --no-audit

# npm ci deletes node_modules before starting, so this needs to come after
# npm ci.
echo
echo "Writing hash ${current_hash} to ${precheck_hash_file}"
echo "${current_hash}" > "${precheck_hash_file}"

# With npm ci, this should never happen.  npm install, however, may modify
# package-lock.json. See https://stackoverflow.com/a/45566871/30900.
if ! cmp --silent old-package-lock.json package-lock.json; then
  echo
  echo '# Warning: npm ci changed package-lock.json'
  echo '# ========================================='
  echo
  echo '`npm ci` should never modify package-lock.json. The build fails if package-lock.json'
  echo 'changes because we use the SHA1 hash of package-lock.json as the cache key for '
  echo 'node_modules.  If package-lock.json changed, subsequent jobs in this workflow will'
  echo 'not be able to restore the node_modules cache. The diff is below:'
  echo
  git --no-pager diff --no-index old-package-lock.json package-lock.json || true
  exit 1
fi
