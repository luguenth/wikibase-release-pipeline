ARG MW_VERSION=$MW_VERSION

FROM mediawiki:${MW_VERSION}

#(using Debian) Downgrade php to 7.4 and add the packages because they are deprecated

# change line in /etc/apt/sources.list.d/ondrej-ubuntu-php-kinetic.list
#sudo apt install -y apt-transport-https lsb-release ca-certificates wget 
# wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
# echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list 
# set php to 7.4
RUN apt update && apt upgrade -y \
    && apt install python3-launchpadlib sed software-properties-common ca-certificates lsb-release apt-transport-https wget -y \
    && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" |  tee /etc/apt/sources.list.d/php.list \
    && apt update && apt install php7.4 php7.4-cli php7.4-common php7.4-curl php7.4-dev php7.4-gd php7.4-mbstring php7.4-mysql php7.4-xml php7.4-zip -y

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer self-update 2.1.14

# check if compers.json is there if yes chown to curr owner
RUN if [ -f /var/www/html/composer.json ]; then chown -R www-data:www-data /var/www/html/composer.json; fi

COPY scripts/require-composer-extension.sh .
COPY extensions.csv .

RUN bash require-composer-extension.sh

# now install the packages which are listed to update in our script
RUN --mount=type=cache,target=/root/.composer/cache composer update

# Dump autoload
RUN composer dump-autoload

CMD ["apache2-foreground"]