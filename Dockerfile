ARG DOCKER_VERSION=latest
FROM docker:$DOCKER_VERSION

RUN apk add --update --no-cache \
    bash \
    bind-tools \
    ca-certificates \
    curl \
    git \
    jq \
    openssh-client \
    py-pip \
    && rm -rf /var/cache/apk/*

ARG DOCKER_MACHINE_VERSION=v0.13.0
ARG DOCKER_MACHINE_SHA256=8f5310eb9e04e71b44c80c0ccebd8a85be56266b4170b4a6ac6223f7b5640df9

ENV SHELL=/bin/bash \
    DOCKER_MACHINE_URL=https://github.com/docker/machine/releases/download/${DOCKER_MACHINE_VERSION}

RUN cd /usr/local/bin \
    && curl -sL ${DOCKER_MACHINE_URL}/docker-machine-`uname -s`-`uname -m` > docker-machine \
    && echo "$DOCKER_MACHINE_SHA256 *docker-machine" | sha256sum -c - \
    && chmod +x docker-machine

ARG DOCKER_COMPOSE_VERSION=1.18.0
ARG DOCKER_CLOUD_VERSION=v1.0.9

RUN pip install \
    docker-compose==$DOCKER_COMPOSE_VERSION \
    docker-cloud==$DOCKER_CLOUD_VERSION

ENV DOCKER_GARBAGE_COLLECT_URL=https://raw.githubusercontent.com/spotify/docker-gc/master/docker-gc
RUN curl -sLo /usr/local/bin/docker-gc ${DOCKER_GARBAGE_COLLECT_URL} \
    && chmod +x /usr/local/bin/docker-gc

ARG MANIFEST_TOOL_VERSION="v0.7.0/manifest-tool-linux-amd64"
ENV MANIFEST_TOOL_BASE_URL=https://github.com/estesp/manifest-tool/releases/download

RUN echo "${MANIFEST_TOOL_BASE_URL}/${MANIFEST_TOOL_VERSION}" \
    && curl -sLo /usr/local/bin/manifest-tool ${MANIFEST_TOOL_BASE_URL}/${MANIFEST_TOOL_VERSION} \
    && chmod +x /usr/local/bin/manifest-tool

RUN \
    docker-machine version; \
    docker-compose version; \
    docker-cloud --version; \
    docker version || true; \
    manifest-tool --version || true \
    docker-gc --help || true

WORKDIR /root
ENTRYPOINT []
CMD ["/bin/bash"]

COPY fs/ /
