FROM docker:latest

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


ENV DOCKER_MACHINE_VERSION=v0.13.0 \
    DOCKER_MACHINE_SHA256=8f5310eb9e04e71b44c80c0ccebd8a85be56266b4170b4a6ac6223f7b5640df9
ENV SHELL=/bin/bash \
    DOCKER_MACHINE_URL=https://github.com/docker/machine/releases/download/${DOCKER_MACHINE_VERSION}

RUN cd /usr/local/bin \
    && curl -sL ${DOCKER_MACHINE_URL}/docker-machine-`uname -s`-`uname -m` > docker-machine \
    && echo "$DOCKER_MACHINE_SHA256 *docker-machine" | sha256sum -c - \
    && chmod +x docker-machine

RUN pip install \
    docker-compose \
    docker-cloud

ENV MANIFEST_TOOL_URL=https://github.com/estesp/manifest-tool/releases/download/v0.7.0/manifest-tool-linux-amd64
RUN curl -sLo /usr/local/bin/manifest-tool ${MANIFEST_TOOL_URL} \
    && chmod +x /usr/local/bin/manifest-tool

RUN \
    docker-machine version; \
    docker-compose version; \
    docker-cloud --version; \
    docker version || true

WORKDIR /root
ENTRYPOINT []
CMD ["/bin/bash"]

COPY fs/ /

# install editor
ENV TERM=linux
RUN apk add --update --no-cache \
    joe \
    vim \
    nano \
    && rm -rf /var/cache/apk/*

