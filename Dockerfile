ARG DOCKER_VERSION=latest
FROM docker:$DOCKER_VERSION

RUN apk add --no-cache \
    bash \
    bind-tools \
    ca-certificates \
    curl \
    git \
    jq \
    make \
    openssh-client \
    py-pip \
    && rm -rf /var/cache/apk/*

ARG DOCKER_MACHINE_VERSION=v0.14.0
ARG DOCKER_MACHINE_SHA256=a4c69bffb78d3cfe103b89dae61c3ea11cc2d1a91c4ff86e630c9ae88244db02

ENV SHELL=/bin/bash \
    DOCKER_MACHINE_URL=https://github.com/docker/machine/releases/download/${DOCKER_MACHINE_VERSION}

RUN cd /usr/local/bin \
    && curl -sL ${DOCKER_MACHINE_URL}/docker-machine-`uname -s`-`uname -m` > docker-machine \
    && echo "$DOCKER_MACHINE_SHA256 *docker-machine" | sha256sum -c - \
    && chmod +x docker-machine

ARG DOCKER_COMPOSE_VERSION=1.20.1

RUN pip install --upgrade pip && \
    pip install \
    docker-compose==$DOCKER_COMPOSE_VERSION

ARG MANIFEST_TOOL_VERSION="v0.7.0/manifest-tool-linux-amd64"
ENV MANIFEST_TOOL_BASE_URL=https://github.com/estesp/manifest-tool/releases/download

RUN echo "${MANIFEST_TOOL_BASE_URL}/${MANIFEST_TOOL_VERSION}" \
    && curl -sLo /usr/local/bin/manifest-tool ${MANIFEST_TOOL_BASE_URL}/${MANIFEST_TOOL_VERSION} \
    && chmod +x /usr/local/bin/manifest-tool

ENV DOCKER_GARBAGE_COLLECT_URL=https://raw.githubusercontent.com/spotify/docker-gc/master/docker-gc
RUN curl -sLo /usr/local/bin/docker-gc ${DOCKER_GARBAGE_COLLECT_URL} \
    && chmod +x /usr/local/bin/docker-gc

ARG OPENFAASCLI_VERSION=0.6.4
ENV OPENFAASCLI_URL=https://github.com/openfaas/faas-cli/releases/download/${OPENFAASCLI_VERSION}/faas-cli
RUN curl -fsSLo /usr/local/bin/faas-cli ${OPENFAASCLI_URL} \
    && chmod +x /usr/local/bin/faas-cli

RUN \
    docker-machine version; \
    docker-compose version; \
    docker version || true; \
    faas-cli version || true; \
    manifest-tool --version || true; \
    docker-gc --help || true;

WORKDIR /root
ENTRYPOINT []
CMD ["/bin/bash"]

COPY fs/ /
