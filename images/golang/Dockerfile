FROM ubuntu:focal-20200925

RUN mkdir /u18
COPY install.sh /u18/install.sh
COPY ssh_config /u18/config
COPY 90forceyes /u18/90forceyes

# jfrog random crap installer copied from /u18 dir in image
# docker run --rm -ti docker.bintray.io/jfrog/pipelines-u18node:12.14.0 bash
RUN chmod +x /u18/install.sh \
    && /u18/install.sh

RUN curl -LO https://golang.org/dl/go1.15.3.linux-amd64.tar.gz \
    && tar -zxvf go1.15.3.linux-amd64.tar.gz \
    && mv go go1.15.3 \
    && mv go1.15.3 /usr/local \
    && ln -s /usr/local/go1.15.3 /usr/local/go

ENV PATH=/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

CMD ["/bin/bash"]
