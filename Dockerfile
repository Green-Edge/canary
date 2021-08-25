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
pcre \
"

RUN set -x && \
    apk update && \
    apk upgrade && \
    apk add --no-cache $RUNTIME_PACKAGES && \
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/*

WORKDIR /usr/local/bin
COPY --from=builder /build/canary /usr/local/bin/canary

EXPOSE 80

CMD ["/usr/local/bin/canary"]
