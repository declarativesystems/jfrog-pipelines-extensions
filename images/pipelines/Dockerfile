# Ubuntu 20.10
FROM ubuntu:groovy-20201022.1
ARG DEBIAN_FRONTEND=noninteractive
ARG AWS_CLI_VERSION="2.0.61"
ARG JFROG_CLI_VERSION="1.41.1"
ARG NODE_JS_VERSION="v15.0.1"
ARG GOLANG_VERSION="1.15.3"
ARG GORELEASER_VERSION="v0.145.0"

RUN apt update && apt install -y \
    sudo \
    software-properties-common \
    wget \
    unzip \
    curl \
    openssh-client \
    ftp \
    gettext \
    smbclient \
    mercurial \
    make \
    tree \
    jq \
    git \
    bash \
    podman


# GCP - not supported
# Azure - not supported
# kubectl - todo
# helm - todo
# terraform - not supported
# packer - not supported
# ansible - not supported


# AWS API
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install

# JFrog CLI
RUN wget -nv https://api.bintray.com/content/jfrog/jfrog-cli-go/${JFROG_CLI_VERSION}/jfrog-cli-linux-amd64/jfrog?bt_package=jfrog-cli-linux-amd64 -O jfrog \
    && chmod +x jfrog \
    && mv jfrog /usr/bin/jfrog

# NodeJS
RUN curl -O https://nodejs.org/dist/${NODE_JS_VERSION}/node-${NODE_JS_VERSION}-linux-x64.tar.xz \
    && tar -Jxvf node-${NODE_JS_VERSION}-linux-x64.tar.xz \
    && mv node-${NODE_JS_VERSION}-linux-x64 /usr/local \
    && ln -s /usr/local/node-${NODE_JS_VERSION}-linux-x64 /usr/local/node

# Golang
RUN curl -LO https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz \
    && tar -zxvf go${GOLANG_VERSION}.linux-amd64.tar.gz \
    && mv go go${GOLANG_VERSION} \
    && mv go${GOLANG_VERSION} /usr/local \
    && ln -s /usr/local/go${GOLANG_VERSION} /usr/local/go

# podman - force vfs driver to allow running in pipelines containerised build
#RUN sed -i 's/driver = ""/driver = "vfs"/' /etc/containers/storage.conf

# goreleaser
RUN curl -LO https://github.com/goreleaser/goreleaser/releases/download/${GORELEASER_VERSION}/goreleaser_amd64.deb \
    && dpkg -i goreleaser_amd64.deb

RUN apt clean
ENV PATH=/usr/local/node/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

CMD ["/bin/bash"]
