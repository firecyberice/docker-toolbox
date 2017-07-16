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

#ENV MANIFEST_TOOL_VERSION=v0.6.0/manifest-tool-linux-amd64 \
#    MANIFEST_TOOL_BASE_URL=https://github.com/estesp/manifest-tool/releases/download
#RUN curl -sLo /usr/local/bin/manifest-tool ${MANIFEST_TOOL_BASE_URL}/${MANIFEST_TOOL_VERSION} \
#    && chmod +x /usr/local/bin/manifest-tool

COPY ./manifest-tool /usr/local/bin/manifest-tool

ENV DOCKER_GARBAGE_COLLECT_URL=https://raw.githubusercontent.com/spotify/docker-gc/master/docker-gc
RUN curl -sLo /usr/local/bin/docker-gc ${DOCKER_GARBAGE_COLLECT_URL} \
    && chmod +x /usr/local/bin/docker-gc

RUN \
    docker-machine version; \
    docker-compose version; \
    docker-cloud --version; \
    docker version || true; \
    manifest-tool --help || true \
    docker-gc --help || true

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

