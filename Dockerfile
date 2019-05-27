ARG DOCKER_VERSION=latest

FROM alpine:latest AS downloader
RUN apk add --no-cache \
    curl \
    && rm -rf /var/cache/apk/*

WORKDIR /usr/local/bin/
ARG DOCKER_MACHINE_VERSION=v0.14.0
ARG DOCKER_MACHINE_SHA256=a4c69bffb78d3cfe103b89dae61c3ea11cc2d1a91c4ff86e630c9ae88244db02
ENV DOCKER_MACHINE_URL=https://github.com/docker/machine/releases/download/${DOCKER_MACHINE_VERSION}
RUN curl -sLo docker-machine ${DOCKER_MACHINE_URL}/docker-machine-`uname -s`-`uname -m` \
    && echo "$DOCKER_MACHINE_SHA256 *docker-machine" | sha256sum -c - \
    && chmod +x docker-machine

ARG MANIFEST_TOOL_VERSION="v0.7.0/manifest-tool-linux-amd64"
ENV MANIFEST_TOOL_BASE_URL=https://github.com/estesp/manifest-tool/releases/download
RUN echo "${MANIFEST_TOOL_BASE_URL}/${MANIFEST_TOOL_VERSION}" \
    && curl -sLo manifest-tool ${MANIFEST_TOOL_BASE_URL}/${MANIFEST_TOOL_VERSION} \
    && chmod +x manifest-tool

ENV DOCKER_GARBAGE_COLLECT_URL=https://raw.githubusercontent.com/spotify/docker-gc/master/docker-gc
RUN curl -sLo docker-gc ${DOCKER_GARBAGE_COLLECT_URL} \
    && chmod +x docker-gc

ARG OPENFAASCLI_VERSION=0.6.4
ARG OPENFAASCLI_SHA256

ENV OPENFAASCLI_URL=https://github.com/openfaas/faas-cli/releases/download/${OPENFAASCLI_VERSION}/faas-cli
RUN curl -fsSLo faas-cli ${OPENFAASCLI_URL} \
    && echo "${OPENFAASCLI_SHA256} *faas-cli" | sha256sum -c - \
    && chmod +x faas-cli

WORKDIR /tmp
ARG DOCKER_APP_VERSION
ARG DOCKER_APP_SHA256
ENV DOCKER_APP_URL=https://github.com/docker/app/releases/download/${DOCKER_APP_VERSION}/docker-app-linux.tar.gz
RUN curl -fsSLo dockerapp.tar.gz ${DOCKER_APP_URL} \
    && tar -xzf dockerapp.tar.gz \
    && install docker-app-linux /usr/local/bin/docker-app \
    && install duffle-linux /usr/local/bin/duffle \
    && rm -f dockerapp.tar.gz  docker-app-linux duffle-linux

FROM docker:$DOCKER_VERSION
RUN apk add --no-cache \
    curl \
    && rm -rf /var/cache/apk/*

#ARG DOCKER_COMPOSE_VERSION=1.20.1
#ARG DOCKER_COMPOSE_SHA256
#ENV DOCKER_COMPOSE_URL=https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}
#RUN curl -sLo docker-compose ${DOCKER_COMPOSE_URL}/docker-compose-`uname -s`-`uname -m` \
#    && echo "$DOCKER_COMPOSE_SHA256 *docker-compose" | sha256sum -c - \
#    && chmod +x docker-compose

# install docker-compose via pip because of musl vs libc6
ARG DOCKER_COMPOSE_VERSION=1.20.1
RUN apk add --no-cache \
      alpine-sdk \
      gcc \
      libffi-dev \
      openssl-dev \
      py3-pip \
      python3-dev \
    && pip3 install --upgrade pip \
    && pip3 install docker-compose==$DOCKER_COMPOSE_VERSION

RUN apk add --no-cache \
    bash \
    bind-tools \
    ca-certificates \
    curl \
    gettext \
    git \
    jq \
    make \
    openssh-client \
    python3 \
    && rm -rf /var/cache/apk/*

RUN ls -l /usr/local/bin/

ENV SHELL=/bin/bash
COPY --from=downloader /usr/local/bin/ /usr/local/bin/

RUN \
    docker-machine version; \
    docker-compose version; \
    docker version || true; \
    docker-app version || true; \
    duffle version || true; \
    faas-cli version || true; \
    manifest-tool --version || true; \
    docker-gc --help || true;

WORKDIR /root
ENTRYPOINT []
CMD ["/bin/bash"]

COPY fs/ /
