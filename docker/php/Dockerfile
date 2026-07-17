FROM php:8.3-fpm

# System libs needed to build Magento's PHP extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
        libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
        libicu-dev libxml2-dev libxslt1-dev libzip-dev \
        libsodium-dev libonig-dev \
        git unzip cron default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Configure + install the extensions Magento 2.4 requires
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath gd intl mbstring pdo_mysql soap sockets sodium xsl zip opcache pcntl

# Magento-tuned PHP settings
COPY conf/php.ini    /usr/local/etc/php/conf.d/zz-magento.ini
COPY conf/www.conf   /usr/local/etc/php-fpm.d/zz-magento.conf

# Composer 2
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
