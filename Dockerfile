FROM nginx:1.19-alpine

RUN set -eux; \
    NGINX_VERSION="$( \
    nginx -v 2>&1 | \
    sed -n 's#^nginx version: nginx/\(.\+\)$#\1#p' \
    )"; \
    CONFIGURE_ARGS="$( \
    nginx -V 2>&1 | \
    sed -n 's/^configure arguments: \(.\+\)$/\1/p' \
    )"; \
    \
    apk add --no-cache --virtual .build-deps \
    wget \
    git \
    openssh \
    make \
    gcc \
    libc-dev \
    linux-headers \
    pcre-dev \
    openssl-dev \
    zlib-dev \
    ; \
    \
    git config --global --bool advice.detachedHead false; \
    \
    BUILDDIR="$(mktemp -d)"; \
    cd "$BUILDDIR"; \
    \
    wget -qO "nginx-${NGINX_VERSION}.tar.gz" \
    "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"; \
    tar xf "nginx-${NGINX_VERSION}.tar.gz"; \
    cd "nginx-${NGINX_VERSION}"; \
    \
    git clone \
    --quiet --depth 1 --recursive \
    -b v1.0.0rc https://github.com/google/ngx_brotli \
    ; \
    \
    ( \
    echo '#!/bin/sh'; \
    echo ./configure `echo "$CONFIGURE_ARGS"` \
    --with-compat \
    '--add-dynamic-module="$(pwd)/ngx_brotli"' \
    ) \
    > cfg; \
    chmod +x cfg; \
    ./cfg; \
    \
    make modules; \
    \
    mv \
    objs/ngx_http_brotli_filter_module.so \
    objs/ngx_http_brotli_static_module.so \
    /usr/lib/nginx/modules \
    ; \
    \
    chmod 0755 \
    /usr/lib/nginx/modules/ngx_http_brotli_filter_module.so \
    /usr/lib/nginx/modules/ngx_http_brotli_static_module.so \
    ; \
    \
    cd; rm -rf "$BUILDDIR"; \
    \
    apk del --purge .build-deps; \
    rm -rf /var/cache/apk/*
