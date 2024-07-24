ARG MW_VERSION=$MW_VERSION

FROM php:7.4-apache

# System dependencies
RUN set -eux; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    git \
    librsvg2-bin \
    imagemagick \
    # Required for SyntaxHighlighting
    python3 \
    ; \
    rm -rf /var/lib/apt/lists/*

# Install the PHP extensions we need
RUN set -eux; \
    \
    savedAptMark="$(apt-mark showmanual)"; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    libicu-dev \
    libonig-dev \
    ; \
    \
    docker-php-ext-install -j "$(nproc)" \
    calendar \
    intl \
    mbstring \
    mysqli \
    opcache \
    ; \
    \
    pecl install APCu-5.1.23; \
    docker-php-ext-enable \
    apcu \
    ; \
    rm -r /tmp/pear; \
    \
    # reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
    | awk '/=>/ { print $3 }' \
    | sort -u \
    | xargs -r dpkg-query -S \
    | cut -d: -f1 \
    | sort -u \
    | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*

# Enable Short URLs
RUN set -eux; \
    a2enmod rewrite; \
    { \
    echo "<Directory /var/www/html>"; \
    echo "  RewriteEngine On"; \
    echo "  RewriteCond %{REQUEST_FILENAME} !-f"; \
    echo "  RewriteCond %{REQUEST_FILENAME} !-d"; \
    echo "  RewriteRule ^ %{DOCUMENT_ROOT}/index.php [L]"; \
    echo "</Directory>"; \
    } > "$APACHE_CONFDIR/conf-available/short-url.conf"; \
    a2enconf short-url

# Enable AllowEncodedSlashes for VisualEditor
RUN sed -i "s/<\/VirtualHost>/\tAllowEncodedSlashes NoDecode\n<\/VirtualHost>/" "$APACHE_CONFDIR/sites-available/000-default.conf"

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# SQLite Directory Setup
RUN set -eux; \
    mkdir -p /var/www/data; \
    chown -R www-data:www-data /var/www/data

# Version
ENV MEDIAWIKI_MAJOR_VERSION 1.39
ENV MEDIAWIKI_VERSION 1.39.8

# MediaWiki setup
RUN set -eux; \
    fetchDeps=" \
    gnupg \
    dirmngr \
    "; \
    apt-get update; \
    apt-get install -y --no-install-recommends $fetchDeps; \
    \
    curl -fSL "https://releases.wikimedia.org/mediawiki/${MEDIAWIKI_MAJOR_VERSION}/mediawiki-${MEDIAWIKI_VERSION}.tar.gz" -o mediawiki.tar.gz; \
    curl -fSL "https://releases.wikimedia.org/mediawiki/${MEDIAWIKI_MAJOR_VERSION}/mediawiki-${MEDIAWIKI_VERSION}.tar.gz.sig" -o mediawiki.tar.gz.sig; \
    export GNUPGHOME="$(mktemp -d)"; \
    # gpg key from https://www.mediawiki.org/keys/keys.txt
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys \
    D7D6767D135A514BEB86E9BA75682B08E8A3FEC4 \
    441276E9CCD15F44F6D97D18C119E1A64D70938E \
    F7F780D82EBFB8A56556E7EE82403E59F9F8CD79 \
    1D98867E82982C8FE0ABC25F9B69B3109D3BB7B0 \
    ; \
    gpg --batch --verify mediawiki.tar.gz.sig mediawiki.tar.gz; \
    tar -x --strip-components=1 -f mediawiki.tar.gz; \
    gpgconf --kill all; \
    rm -r "$GNUPGHOME" mediawiki.tar.gz.sig mediawiki.tar.gz; \
    chown -R www-data:www-data extensions skins cache images; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $fetchDeps; \
    rm -rf /var/lib/apt/lists/*

# copy install script
COPY scripts/install-git-extension.sh ./install-git-extension.sh
COPY extensions.csv ./extensions.csv

# set permissions
RUN chmod +x ./install-git-extension.sh

RUN bash install-git-extension.sh

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer self-update 2.1.14

# Check if composer.json is there, if yes, chown to current owner
RUN if [ -f /var/www/html/composer.json ]; then chown -R www-data:www-data /var/www/html/composer.json; fi

COPY scripts/require-composer-extension.sh .
COPY extensions.csv .   

RUN bash require-composer-extension.sh

# Now install the packages which are listed to update in our script
RUN --mount=type=cache,target=/root/.composer/cache composer update

# Dump autoload
RUN composer dump-autoload

# Copy in the jobrunner-entrypoint.sh TODO: get the build file insead of the copied in file in this dir
COPY jobrunner-entrypoint.sh /jobrunner-entrypoint.sh
#set ownership
RUN chown www-data:www-data /jobrunner-entrypoint.sh
RUN chmod +x /jobrunner-entrypoint.sh

CMD ["apache2-foreground"]