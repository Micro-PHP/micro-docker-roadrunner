# Common base stage
ARG PHP_VERSION=8.2
ARG ROADRUNNER_VERSION=2023.3.3
FROM ghcr.io/roadrunner-server/roadrunner:${ROADRUNNER_VERSION} as rr
FROM php:${PHP_VERSION}-cli-alpine AS php-base

ENV COMPOSER_ALLOW_SUPERUSER=1

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# Validate PHP_VERSION argument
RUN if [ -z "$PHP_VERSION" ]; then echo "The PHP_VERSION argument is not set."; exit 1; fi \
 && if [ "$(printf '%s\n' "8.2" "$PHP_VERSION" | sort -V | head -n1)" != "8.2" ]; then \
        echo "PHP version must be at least 8.2"; \
        exit 1; \
    fi

VOLUME /app
WORKDIR /app

# hadolint ignore=DL3018
RUN apk update && apk add --no-cache linux-headers \
    acl \
    file \
    gettext \
    g++ \
    procps \
    openssl \
    git \
    unzip \
    libzip-dev \
    freetype-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    icu-dev \
    oniguruma-dev \
    libxslt-dev \
    postgresql-dev

RUN echo 'alias micro="php bin/console"' >> ~/.ashrc

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j"$(nproc)" \
    intl zip xsl opcache pdo_mysql gd exif mbstring sockets

COPY docker/php/docker-entrypoint.sh /etc/entrypoint.sh
RUN chmod +x /etc/entrypoint.sh

# Composer and RoadRunner binaries
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
COPY --from=rr /usr/bin/rr /usr/local/bin/rr

# Configuration files
COPY docker/php/app.ini /usr/local/etc/php/conf.d/

# Production stage
FROM php-base as php-prod
ENV ENV=prod
ENV COMPOSER_NO_DEV=1
RUN docker-php-ext-enable opcache
COPY docker/php/prod/app.prod.ini /usr/local/etc/php/conf.d/
COPY . .
ENTRYPOINT ["/etc/entrypoint.sh"]

# Development stage
FROM php-base as php-dev
ENV ENV=dev

# hadolint ignore=DL3018
RUN apk add --no-cache $PHPIZE_DEPS \
 && pecl install xdebug \
 && docker-php-ext-enable xdebug
COPY --link docker/php/dev/app.dev.ini /usr/local/etc/php/conf.d/
ENTRYPOINT ["/etc/entrypoint.sh"]
