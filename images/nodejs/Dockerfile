FROM ubuntu:focal-20200925

RUN mkdir /u18
COPY install.sh /u18/install.sh
COPY ssh_config /u18/config
COPY 90forceyes /u18/90forceyes

# jfrog random crap installer copied from /u18 dir in image
# docker run --rm -ti docker.bintray.io/jfrog/pipelines-u18node:12.14.0 bash
RUN chmod +x /u18/install.sh \
    && /u18/install.sh

RUN curl -O https://nodejs.org/dist/v15.0.1/node-v15.0.1-linux-x64.tar.xz \
    && tar -Jxvf node-v15.0.1-linux-x64.tar.xz \
    && mv node-v15.0.1-linux-x64 /usr/local \
    && ln -s /usr/local/node-v15.0.1-linux-x64 /usr/local/node

ENV PATH=/usr/local/node/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

CMD ["/bin/bash"]
