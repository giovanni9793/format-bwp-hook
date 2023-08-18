FROM alpine:latest

COPY script.sh /srv/formatBwp

RUN \
    apk update && \
    apk add --no-cache --update-cache bash libxml2-utils coreutils sed && \
    rm -rf /var/cache/apk/*