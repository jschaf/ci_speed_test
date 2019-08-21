#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

tar xvf git.tar.gz
cd git-${GIT_VERSION}

export NO_CURL=1 NO_EXPAT=1 NO_GETTEXT=1 NO_PERL=1 NO_PYTHON=1 NO_TCLTK=1
export NO_INSTALL_HARDLINKS=1 NO_OPENSSL=1 NO_CROSS_DIRECTORY_HARDLINKS=1

CFLAGS='-g -O2 -fdebug-prefix-map=/=. -fstack-protector-strong -Wformat -Werror=format-security' \
make -j8 prefix=/usr gitexecdir=/usr/lib/git-core install
make prefix=/usr gitexecdir=/usr/lib/git-core install

cd /usr/lib/git-core
rm git-add--interactive git-bisect git-credential-cache git-credential-cache--daemon \
    git-credential-store git-daemon git-fast-import git-filter-branch \
    git-http-backend git-imap-send git-instaweb git-legacy-stash git-mergetool \
    git-mergetool--lib git-rebase--preserve-merges  git-remote-testsvn \
    git-request-pull git-sh-i18n--envsubst git-sh-setup git-shell \
    git-submodule git-web--browse

rm /usr/lib/git-core/git
ln -s /usr/bin/git /usr/lib/git-core/git
