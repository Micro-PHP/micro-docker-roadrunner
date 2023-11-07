# Common base stage
ARG PHP_VERSION=8.2
ARG ROADRUNNER_VERSION=2023.3.3
FROM ghcr.io/roadrunner-server/roadrunner:${ROADRUNNER_VERSION} as rr
FROM php:${PHP_VERSION}-cli AS php-base

ENV COMPOSER_ALLOW_SUPERUSER=1

# Set the SHELL option -o pipefail before RUN with a pipe in it
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN if [ -z "$PHP_VERSION" ]; then echo "The PHP_VERSION argument is not set."; exit 1; fi \
 && if [ "$(printf '%s\n' "8.2" "$PHP_VERSION" | sort -V | head -n1)" != "8.2" ]; then \
        echo "PHP version must be at least 8.2"; \
        exit 1; \
    fi

VOLUME /app
WORKDIR /app

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    acl \
    file \
    gettext \
    gnupg \
    g++ \
    procps \
    openssl \
    git \
    unzip \
    zlib1g-dev \
    libzip-dev \
    libfreetype6-dev \
    make \
    libpng-dev \
    libjpeg-dev \
    libicu-dev  \
    libonig-dev \
    libxslt1-dev \
    libpq-dev \
 && rm -rf /var/lib/apt/lists/* # Added cleanup

RUN echo 'alias sf="php bin/console"' >> ~/.bashrc

# Combining RUN commands to consolidate layers
RUN docker-php-ext-configure gd --with-jpeg --with-freetype \
 && docker-php-ext-install -j"$(nproc)" \
    intl zip xsl opcache pdo_mysql gd exif mbstring sockets

COPY docker/php/docker-entrypoint.sh /etc/entrypoint.sh
RUN chmod +x /etc/entrypoint.sh

###> recipes ###
###< recipes ###

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
COPY --from=rr /usr/bin/rr /usr/local/bin/rr
COPY docker/php/app.ini /usr/local/etc/php/conf.d/

FROM php-base as php-prod
ENV ENV=prod
ENV COMPOSER_NO_DEV=1
RUN docker-php-ext-enable opcache
COPY docker/php/prod/app.prod.ini /usr/local/etc/php/conf.d/
COPY . .
ENTRYPOINT ["/etc/entrypoint.sh"]

FROM php-base as php-dev
ENV ENV=dev
RUN pecl install xdebug && docker-php-ext-enable xdebug
COPY --link docker/php/dev/app.dev.ini /usr/local/etc/php/conf.d/

ENTRYPOINT ["/etc/entrypoint.sh"]
