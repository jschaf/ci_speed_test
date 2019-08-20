ARG ALPINE_VERSION=3.10.1

# Alias the base image so we can upgrade it in one spot.
FROM alpine:${ALPINE_VERSION} as alpine

FROM alpine as ssh-builder
RUN apk --no-cache add openssh

FROM alpine as git-builder
RUN set -eux \
  && apk --no-cache add git \
  && cd /usr/libexec/git-core \
  && rm git-bisect git-credential-cache git-credential-cache--daemon \
    git-credential-store git-filter-branch  git-http-fetch git-http-push \
    git-legacy-stash git-mergetool git-mergetool--lib git-rebase--preserve-merges \
    git-remote-http git-request-pull git-sh-i18n--envsubst git-sh-setup \
    git-submodule git-web--browse


# docker build --target alpine-ci-git -t jschaf/alpine-ci-git:latest docker/alpine-ci
# docker run --interactive --tty jschaf/alpine-ci-git:latest
FROM alpine as alpine-ci-git
# Git
COPY --from=git-builder /usr/bin/git /usr/bin/
COPY --from=git-builder \
  /usr/lib/libcurl.so.4 \
  /usr/lib/libpcre2-8.so.0 \
  /usr/lib/libpcre2-posix.so.2 \
  /usr/lib/
# SSH
COPY --from=ssh-builder /usr/bin/ssh /usr/bin/
COPY --from=ssh-builder \
  /usr/lib/libedit.so.0 \
  /usr/lib/libformw.so.6 \
  /usr/lib/libmenuw.so.6 \
  /usr/lib/libncursesw.so.6 \
  /usr/lib/libpanelw.so.6  \
  /usr/lib/
