#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

# Installs the node modules for this project.
#
# If the existing node_modules cache is fresh, this script halts the CircleCI
# job that runs this script. The cache is fresh if the node_modules cache key
# for the current state of the repo matches the cache key for the node_modules
# precheck key.

REPO_DIR='/home/ci/ci_speed_test'
REPO_RAMFS_DIR='/dev/shm/ci/ci_speed_test'
NODE_MODULES_DIR='/dev/shm/ci/ci_speed_test/node_modules'

printf '
# Checking if node_modules cache is fresh
=========================================\n'
# The precheck step downloads a single file with cache key for the node_modules
# which is a few bytes large. If the cache key didn't change we skip the rest
# of this job.
#
# Restoring the node_modules cache takes about 1 second per 10MB. Since the
# compressed node modules cache is 120MB, the precheck step saves about
# 12 seconds.

current_hash_file="${REPO_DIR}/.circleci/node_modules_cache_key"
if [[ ! -e "${current_hash_file}" ]]; then
  echo "ERROR: node_modules cache key file not found at ${current_hash_file}."
  echo '   The cache key file should be created in the checkout_repo step.'
fi
current_hash="$(< "${current_hash_file}")"

precheck_hash_file="${REPO_DIR}/.circleci/node_modules_precheck_cache_key"
precheck_hash='<none>'
precheck_status='stale'
if [[ -f "${precheck_hash_file}" ]]; then
  precheck_hash="$(< ${precheck_hash_file})"
  if [[ "${current_hash}" == "${precheck_hash}" ]]; then
    precheck_status='fresh'
  fi
fi

printf 'value from %-65s %s\n' "${current_hash_file}" "${current_hash}"
printf 'value from %-65s %s\n' "${precheck_hash_file}" "${precheck_hash}"
echo "cache_status: ${precheck_status}"

if [[ "${precheck_status}" == 'fresh' ]]; then
  printf '\nSkipping installing node_modules because because the cache is fresh.\n'
  circleci task halt
  exit 0
fi

printf '
# Installing node_modules because cache is stale
================================================\n'

echo "node version: $(node --version)"
echo "npm version: $(npm --version)"
echo

# Move to /dev/shm because for IO speedup.
mkdir -p ${REPO_RAMFS_DIR}
cp ${REPO_DIR}/package-lock.json ${REPO_RAMFS_DIR}
cp ${REPO_DIR}/package.json ${REPO_RAMFS_DIR}
cd ${REPO_RAMFS_DIR}

# Install node_modules.
npm ci --ignore-scripts --prefer-offline --no-audit

printf '
# Updating precheck cache key
=============================\n'
echo "Writing hash '${current_hash}' to ${precheck_hash_file}."
echo 'The hash will be saved to the node_modules precheck cache.'
echo "${current_hash}" > "${precheck_hash_file}"

printf '
# Pruning node_modules
======================'
node-prune ${NODE_MODULES_DIR}

printf '
# node_modules size
===================\n'
du -sh ${NODE_MODULES_DIR}

