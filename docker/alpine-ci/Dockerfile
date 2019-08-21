ARG NODE_VERSION=10.15.3
ARG ALPINE_VERSION=3.10.1

ARG CI_HOME=/home/ci

# Alias the base image so we can upgrade it in one spot.
FROM alpine:${ALPINE_VERSION} as alpine


# Builder image for bash.
FROM alpine as builder-bash
RUN apk --no-cache add bash


# Builder image for certs to copy into the base Debian image.
FROM alpine as builder-certs
RUN apk --no-cache add ca-certificates


FROM alpine as builder-git
RUN set -eux \
  && apk --no-cache add git \
  && cd /usr/libexec/git-core \
  && rm git-bisect git-credential-cache git-credential-cache--daemon \
    git-credential-store git-filter-branch  git-http-fetch git-http-push \
    git-legacy-stash git-mergetool git-mergetool--lib git-rebase--preserve-merges \
    git-remote-http git-request-pull git-sh-i18n--envsubst git-sh-setup \
    git-submodule git-web--browse


# Builder image for the node-prune utility.
# Binary saved at /go/bin/node-prune.
FROM golang:1.12.9-alpine3.10 as builder-node-prune
RUN apk add --no-cache git && go get github.com/tj/node-prune/cmd/node-prune


# Builder image for ssh.
FROM alpine as builder-ssh
RUN apk --no-cache add openssh


# docker build --target alpine-ci -t jschaf/alpine-ci:latest docker/alpine-ci
# docker run --interactive --tty jschaf/alpine-ci:latest
FROM alpine as alpine-ci
# Bash
COPY --from=builder-bash /bin/bash /bin/
COPY --from=builder-bash /usr/lib/bash /usr/lib/bash
COPY --from=builder-bash /usr/lib/libreadline.so.8 /usr/lib/
COPY --from=builder-bash /usr/share/terminfo/x/xterm /usr/share/terminfo/x/xterm
COPY --from=builder-bash /usr/share/terminfo/d/dumb /usr/share/terminfo/d/dumb
# Certs
COPY --from=builder-certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
# Git
COPY --from=builder-git /usr/bin/git /usr/bin/
COPY --from=builder-git \
  /usr/lib/libcurl.so.4 \
  /usr/lib/libpcre2-8.so.0 \
  /usr/lib/libpcre2-posix.so.2 \
  /usr/lib/
# SSH
COPY --from=builder-ssh /usr/bin/ssh /usr/bin/
COPY --from=builder-ssh \
  /usr/lib/libedit.so.0 \
  /usr/lib/libformw.so.6 \
  /usr/lib/libmenuw.so.6 \
  /usr/lib/libncursesw.so.6 \
  /usr/lib/libpanelw.so.6  \
  /usr/lib/
RUN set -eux \
  && ln -s /usr/share/terminfo /usr/lib/terminfo \
  && echo '/bin/bash' >> /etc/shells \
  && echo "export PS1='\u@\h:\w\$ '" > /root/.bashrc \
  && sed -ie 's#/root:/bin/ash#/root:/bin/bash#' /etc/passwd


# Builder image for Node customization.
#
# docker build --target builder-node -t jschaf/alpine-ci-builder-node:latest docker/alpine-ci
# docker run --interactive --tty jschaf/alpine-ci-builder-node:latest
FROM node:${NODE_VERSION}-alpine as builder-node
ARG NODE_MODULES=/usr/local/lib/node_modules
# node-prune
COPY --from=builder-node-prune /go/bin/node-prune /usr/local/bin/
COPY shim_mocha.js shim_tsc.js ${REPO}/bin/
RUN set -eux \
  && rm -rf ${NODE_MODULES}/npm/{man,html,doc,changelogs} \
  && find ${NODE_MODULES} -type f -name '*.min.js'  | xargs rm -f \
  && node-prune ${NODE_MODULES}


# The main image for Node building and testing. To build:
#
# docker build --target alpine-ci-node -t jschaf/alpine-ci-node:latest docker/alpine-ci
# docker run --interactive --tty jschaf/debian-ci-speed-test-node:latest /bin/sh
FROM alpine-ci as alpine-ci-node
ARG REPO=/home/ci/ci_speed_test
ARG REPO_RAMFS=/dev/shm/ci_speed_test
# Node and NPM
COPY --from=builder-node /usr/local/bin/node /usr/local/bin/
COPY --from=builder-node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder-node /usr/lib/libgcc_s.so.1 '/usr/lib/libstdc++.so.6' /usr/local/lib/
# node-prune
COPY --from=builder-node-prune /go/bin/node-prune /usr/local/bin/
# Shims
COPY shim_mocha.js shim_tsc.js ${REPO}/bin/
RUN set -eux \
  && mkdir -p ${REPO} \
  && ln -s ${REPO_RAMFS}/node_modules ${REPO}/node_modules \
  && ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
  && echo 'export PATH="/home/ci/ci_speed_test/bin:${PATH}"' >> /root/.bashrc
WORKDIR /home/ci
CMD ["/bin/bash"]

