ARG DOCKER_VERSION=latest

FROM alpine:latest AS dl
RUN apk add --no-cache \
    curl

WORKDIR /usr/local/bin/

FROM dl AS p1
ARG DOCKER_MACHINE_VERSION=v0.14.0
ARG DOCKER_MACHINE_SHA256=a4c69bffb78d3cfe103b89dae61c3ea11cc2d1a91c4ff86e630c9ae88244db02
ENV DOCKER_MACHINE_URL=https://github.com/docker/machine/releases/download/${DOCKER_MACHINE_VERSION}
RUN curl -sLo docker-machine ${DOCKER_MACHINE_URL}/docker-machine-`uname -s`-`uname -m` \
    && echo "$DOCKER_MACHINE_SHA256 *docker-machine" | sha256sum -c - \
    && chmod +x docker-machine

FROM dl AS p2
ARG MANIFEST_TOOL_VERSION="v0.7.0/manifest-tool-linux-amd64"
ENV MANIFEST_TOOL_BASE_URL=https://github.com/estesp/manifest-tool/releases/download
RUN echo "${MANIFEST_TOOL_BASE_URL}/${MANIFEST_TOOL_VERSION}" \
    && curl -sLo manifest-tool ${MANIFEST_TOOL_BASE_URL}/${MANIFEST_TOOL_VERSION} \
    && chmod +x manifest-tool

FROM dl AS p3
ARG OPENFAASCLI_VERSION=0.6.4
ARG OPENFAASCLI_SHA256
ENV OPENFAASCLI_URL=https://github.com/openfaas/faas-cli/releases/download/${OPENFAASCLI_VERSION}/faas-cli
RUN curl -fsSLo faas-cli ${OPENFAASCLI_URL} \
    && echo "${OPENFAASCLI_SHA256} *faas-cli" | sha256sum -c - \
    && chmod +x faas-cli

FROM scratch AS collect
COPY --from=p1 /usr/local/bin/ /usr/local/bin/
COPY --from=p2 /usr/local/bin/ /usr/local/bin/
COPY --from=p3 /usr/local/bin/ /usr/local/bin/

FROM docker:$DOCKER_VERSION
RUN apk add --no-cache \
    bash \
    bind-tools \
    ca-certificates \
    curl \
    gettext \
    git \
    jq \
    lftp \
    make \
    openssh-client \
    rsync

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
    python3 \
    python3-dev \
    && pip3 install --upgrade pip \
    && pip3 install docker-compose==$DOCKER_COMPOSE_VERSION

RUN pip3 install awscli
RUN ls -l /usr/local/bin/
ENV SHELL=/bin/bash

COPY --from=collect /usr/local/bin/ /usr/local/bin/
RUN { \
      docker-machine version; \
      docker-compose version; \
      docker version || true; \
      faas-cli version || true; \
      manifest-tool --version || true; \
    }

WORKDIR /root
ENTRYPOINT []
CMD ["/bin/bash"]

COPY fs/ /
