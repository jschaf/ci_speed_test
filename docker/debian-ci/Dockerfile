ARG DEBIAN_VERSION=stretch-20190812-slim
ARG NODE_VERSION=10.15.3
ARG PYTHON_VERSION=2.7.16

ARG CI_HOME=/home/ci
ARG REPO=${CI_HOME}/ci_speed_test

# Alias the base Debian image so we can upgrade it in one spot.
FROM debian:${DEBIAN_VERSION} as debian
ENV CI_HOME=/home/ci
RUN set -eux \
  && rm -rf /usr/share/common-licenses /usr/share/doc


FROM gcr.io/distroless/base as distroless-base
FROM gcr.io/distroless/base:debug as distroless-base-debug



# Builder image for certs to copy into the base Debian image.
FROM debian as builder-certs
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates


# Builder image for the node-prune utility.
# Binary saved at /go/bin/node-prune.
FROM golang:1.12.9-alpine3.10 as builder-node-prune
RUN apk add --no-cache git && go get github.com/tj/node-prune/cmd/node-prune


# Builder image for Git to copy into the base Debian image.
FROM debian:sid-20190812-slim as builder-git
COPY install-slim-debian-git.sh /usr/bin/
RUN /usr/bin/install-slim-debian-git.sh


FROM debian as builder-bash
RUN set -eux \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends bash-static


FROM debian as builder-git-src
ARG GIT_VERSION=2.23.0
RUN set -eux \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
         gcc autoconf libc-dev zlib1g-dev curl ca-certificates make libssl-dev \
  && curl -L https://github.com/git/git/archive/v${GIT_VERSION}.tar.gz --output git.tar.gz
COPY install-git-from-src.sh /usr/bin/
RUN install-git-from-src.sh


# Builder image for SSH to copy onto the base Debian image.
FROM debian as builder-ssh
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends openssh-client

# The base distroless image for langauge specific images. To build:
#
# docker build --target distroless-ci -t jschaf/distroless-ci:latest docker/debian-ci
# docker run --interactive --tty jschaf/distroless-ci:latest /bin/bash
FROM scratch as distroless-ci
COPY --from=distroless-base / /
COPY --from=distroless-base-debug /busybox /bin
COPY --from=debian \
  /lib/x86_64-linux-gnu/libselinux.so.1 \
  /lib/x86_64-linux-gnu/libz.so.1 \
  /lib/x86_64-linux-gnu/
# Bash
COPY --from=builder-bash /bin/bash-static /bin/bash
# Git
COPY --from=builder-git-src /usr/bin/git /usr/bin/
COPY --from=builder-git-src /usr/lib/git-core /usr/lib/git-core
COPY --from=builder-git-src /usr/share/git-core/templates /usr/share/git-core/templates
# SSH
COPY --from=builder-ssh \
  /usr/lib/x86_64-linux-gnu/libgssapi_krb5.so.2 \
  /usr/lib/x86_64-linux-gnu/libcrypto.so.1.0.2 \
  /usr/lib/x86_64-linux-gnu/libkrb5.so.3 \
  /usr/lib/x86_64-linux-gnu/libkrb5support.so.0 \
  /usr/lib/x86_64-linux-gnu/libk5crypto.so.3 \
  /usr/lib/x86_64-linux-gnu/
COPY --from=builder-ssh /usr/bin/ssh /usr/bin/ssh
COPY --from=builder-ssh /usr/lib/openssh /usr/lib/openssh
COPY --from=builder-ssh \
  /lib/x86_64-linux-gnu/libkeyutils.so.1 \
  /lib/x86_64-linux-gnu/libcom_err.so.2 \
  /lib/x86_64-linux-gnu/libpcre.so.3 \
  /lib/x86_64-linux-gnu/
RUN echo "export PS1='\u@\h:\w\$ '" > /root/.bashrc

# The base Debian image for langauge specific images. To build:
#
# docker build --target debian-ci -t jschaf/debian-ci-speed-test:latest docker/debian-ci
# docker run --interactive --tty jschaf/debian-ci:latest /bin/bash
FROM debian as debian-ci
# Certs
COPY --from=builder-certs /etc/ssl/certs /etc/ssl/certs
# Git
COPY --from=builder-git /usr/bin/git /usr/bin/
COPY --from=builder-git /usr/lib/git-core /usr/lib/git-core
COPY --from=builder-git /usr/share/git-core/templates /usr/share/git-core/templates
COPY --from=builder-git /usr/lib/sasl2 /usr/lib/sasl2
COPY --from=builder-git /usr/lib/x86_64-linux-gnu/engines-1.1 /usr/lib/x86_64-linux-gnu/engines-1.1
COPY --from=builder-git /usr/lib/x86_64-linux-gnu/krb5 /usr/lib/x86_64-linux-gnu/krb5
COPY --from=builder-git /usr/lib/x86_64-linux-gnu/sasl2 /usr/lib/x86_64-linux-gnu/sasl2
COPY --from=builder-git \
  /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 \
  /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.* \
  /usr/lib/x86_64-linux-gnu/libgssapi_krb5.so.* \
  /usr/lib/x86_64-linux-gnu/libk5crypto.so.* \
  /usr/lib/x86_64-linux-gnu/libkrb5.so.* \
  /usr/lib/x86_64-linux-gnu/libkrb5support.so.* \
  /usr/lib/x86_64-linux-gnu/libblber-2.4.so.* \
  /usr/lib/x86_64-linux-gnu/libldap-2.4.so.* \
  /usr/lib/x86_64-linux-gnu/libldap_4-2.4.so.* \
  /usr/lib/x86_64-linux-gnu/libnghttp2.so.* \
  /usr/lib/x86_64-linux-gnu/libpsl.so.* \
  /usr/lib/x86_64-linux-gnu/librtmp.so.* \
  /usr/lib/x86_64-linux-gnu/libsasl2.so.* \
  /usr/lib/x86_64-linux-gnu/libssh2.so.* \
  /usr/lib/x86_64-linux-gnu/libssl.so.* \
  /usr/lib/x86_64-linux-gnu/
# SSH
COPY --from=builder-ssh /usr/bin/ssh /usr/bin/
COPY --from=builder-ssh /usr/lib/openssh /usr/lib/openssh
COPY --from=builder-ssh /lib/x86_64-linux-gnu/libkeyutils.so.* /lib/x86_64-linux-gnu/
# CircleCI user
RUN set -eux \
  && groupadd --gid 3434 ci \
  && useradd --uid 3434 --gid ci --groups ci --groups sudo --create-home --shell /bin/bash ci


# Builder image for Node customization.
FROM node:${NODE_VERSION}-stretch as builder-node
ARG REPO=/home/ci/ci_speed_test
# node-prune
COPY --from=builder-node-prune /go/bin/node-prune /usr/local/bin/
ARG NODE_MODULES=/usr/local/lib/node_modules
RUN set -eux \
  && rm -rf ${NODE_MODULES}/npm/{man,html,doc,changelogs} \
  && find ${NODE_MODULES} -type f -name '*.min.js'  | xargs rm -f \
  && node-prune ${NODE_MODULES}


# docker build --target distroless-ci-node -t jschaf/distroless-ci-node:latest docker/debian-ci
# docker run --interactive --tty --entrypoint node jschaf/distroless-ci-node:latest
FROM distroless-ci as distroless-ci-node
ARG CI_HOME=/home/ci
# Node and NPM
COPY --from=builder-node /usr/local/bin/node /usr/local/bin/
COPY --from=builder-node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder-node '/usr/lib/x86_64-linux-gnu/libstdc++.so.6' /usr/lib/x86_64-linux-gnu/
COPY --from=builder-node /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/x86_64-linux-gnu/
# node-prune
COPY --from=builder-node-prune /go/bin/node-prune /usr/local/bin/
# Shims
COPY shim_mocha.js ${REPO}/bin/mocha
COPY shim_tsc.js ${REPO}/bin/tsc
RUN set -eux \
  && ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
  && mkdir -p ${CI_HOME} \
  && echo 'export PATH="/home/ci/ci_speed_test/bin:${PATH}"' >> /root/.bashrc
WORKDIR /home/ci

# The main image for Node building and testing. To build:
#
# docker build --target debian-ci-node -t jschaf/debian-ci-node:latest docker/debian-ci
# docker run --interactive --tty jschaf/debian-ci-node:latest /bin/bash
FROM debian-ci as debian-ci-node
ARG CI_HOME=/home/ci
# Node and NPM
COPY --from=builder-node /usr/local/bin/node /usr/local/bin/
COPY --from=builder-node /usr/local/lib/node_modules /usr/local/lib/node_modules
# node-prune
COPY --from=builder-node-prune /go/bin/node-prune /usr/local/bin/
# Shims
COPY shim_mocha.js ${REPO}/bin/mocha
COPY shim_tsc.js ${REPO}/bin/tsc
RUN set -eux \
  && ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
  && mkdir -p ${CI_HOME} \
  && echo 'export PATH="/home/ci/ci_speed_test/bin:${PATH}"' >> ${CI_HOME}/.bashrc
USER ci
WORKDIR /home/ci
CMD ["/bin/bash"]

