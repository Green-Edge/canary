FROM crystallang/crystal:latest-alpine AS builder

USER root
WORKDIR /build

ENV LANG=C.UTF-8

RUN test -e /var/run || ln -s /run /var/run

COPY shard.yml /build
RUN shards install

COPY src/* /build/src/
RUN crystal build --release --progress --threads=$(nproc) src/canary.cr

FROM alpine:latest

ENV LANG=C.UTF-8
ENV RUNTIME_PACKAGES="\
gcc \
openssl \
openssh \
pcre \
"

ADD https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.1/s6-overlay-amd64-installer /tmp/

RUN set -x && \
    apk update && \
    apk upgrade && \
    apk add --no-cache $RUNTIME_PACKAGES && \
    chmod +x /tmp/s6-overlay-amd64-installer && \
    /tmp/s6-overlay-amd64-installer / && \
    rm /tmp/s6-overlay-amd64-installer && \
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/*

RUN sed -i \
    -e 's~^#PermitRootLogin prohibit-password~PermitRootLogin yes~g' \
    -e 's~^#PubkeyAuthentication yes~PubkeyAuthentication yes~g' \
    -e 's~^#PasswordAuthentication yes~PasswordAuthentication yes~g' \
    -e 's~^#PermitEmptyPasswords no~PermitEmptyPasswords yes~g' \
    -e 's~^#UseDNS no~UseDNS no~g' \
    -e 's~^#Port 22~Port 2222~g' \
    /etc/ssh/sshd_config \
    && mkdir -p $HOME/.ssh \
    && chmod 700 $HOME/.ssh \
    &&  { \
            echo 'Host *'; \
            echo '  UserKnownHostsFile /dev/null'; \
            echo '  StrictHostKeyChecking no'; \
            echo '  LogLevel quiet'; \
            echo '  Port 2222'; \
        } > $HOME/.ssh/config \
    && chmod 600 $HOME/.ssh/config \
    \
    && ssh-keygen -A \
    && ssh-keygen -q -N "" -t rsa -f $HOME/.ssh/id_rsa \
    && cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys \
    && chmod 600 $HOME/.ssh/authorized_keys

# RUN mkdir -p ~root/.ssh /etc/authorized_keys && chmod 700 ~root/.ssh/ \
#     && echo "root:root" | chpasswd

WORKDIR /usr/local/bin
COPY --from=builder /build/canary /usr/local/bin/canary
COPY docker/services.d /etc/services.d

EXPOSE 80 22

ENTRYPOINT ["/init"]
