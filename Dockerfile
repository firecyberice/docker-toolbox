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


ENV DOCKER_MACHINE_VERSION=v0.10.0 \
    DOCKER_MACHINE_SHA256=74f77385f6744fb83ec922b206f39b4c33ac42e63ed09d4d63652741d8a94df9
ENV SHELL=/bin/bash \
    DOCKER_MACHINE_URL=https://github.com/docker/machine/releases/download/${DOCKER_MACHINE_VERSION}

RUN cd /usr/local/bin \
    && curl -sL ${DOCKER_MACHINE_URL}/docker-machine-`uname -s`-`uname -m` > docker-machine \
    && echo "$DOCKER_MACHINE_SHA256 *docker-machine" | sha256sum -c - \
    && chmod +x docker-machine

RUN pip install \
    docker-compose \
    docker-cloud

ENV MANIFEST_TOOL_URL=https://github.com/estesp/manifest-tool/releases/download/v0.3.0/manifest-tool-amd64-linux
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

