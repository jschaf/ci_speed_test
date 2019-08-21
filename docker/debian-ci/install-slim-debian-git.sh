#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

# Installs Git on Debian without Perl to save 50MB.

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libcurl3-gnutls

# Allow apt to download as _apt user instead of root.
mkdir -p /var/cache/apt/archives/partial/
chown -Rv _apt:root /var/cache/apt/archives/partial/
chown -Rv _apt:root /var/cache/apt/archives/partial/
cd /var/cache/apt/archives/partial
apt-get download git

# Force install Git and ignore the 50MB perl dependency which is only needed for
# a few Git commands.
# - git-archimport
# - git-add--interactive
dpkg --force-all --ignore-depends=perl,git-man,liberror-perl,libexpat --install git_*.deb

# Overwrite the duplicated git binary. Saves 3MB.
ln -sf /usr/bin/git /usr/lib/git-core/git \

# 22MB of Git we don't need for CI.
cd /usr/lib/git-core
rm git-add--interactive git-bisect git-credential-cache git-credential-cache--daemon \
    git-credential-store git-daemon git-fast-import git-filter-branch \
    git-http-backend git-http-fetch git-http-push git-imap-send git-instaweb \
    git-legacy-stash git-mergetool git-mergetool--lib git-rebase--preserve-merges \
    git-remote-http git-remote-testsvn git-request-pull git-sh-i18n--envsubst \
    git-sh-prompt git-sh-setup git-shell git-submodule git-subtree git-web--browse
