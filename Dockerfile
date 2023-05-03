# ./build/Dockerfile
FROM php:8.1-apache
# An Updated image with all dependancies we need


# End environment Defitinions

# Let's make sure we don't get prompted when installing packages
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Add uvdesk user
RUN adduser uvdesk -q --disabled-password --gecos ""

# Install packages
RUN apt-get update && apt-get upgrade -y
RUN apt-get -y install wget git unzip zip curl nano inotify-tools screen;

# Install PHP extensions installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions

# Install PHP extensions
RUN install-php-extensions imap mailparse mysqli pdo_mysql

# Download the latest stable build
RUN wget "https://cdn.uvdesk.com/uvdesk/downloads/opensource/uvdesk-community-current-stable.zip" -P /var/www/ 

# Download Minio client for S3 configuration
RUN wget https://dl.minio.io/client/mc/release/linux-amd64/mc -P /usr/local/bin/
RUN chmod +x /usr/local/bin/mc


# Unzip contents
RUN unzip -q /var/www/uvdesk-community-current-stable.zip -d /var/www/


# Move to working directory
RUN mv /var/www/uvdesk-community-v1.1.1/ /var/www/uvdesk

# Copy configuration files for Apache
COPY ./.docker/config/apache2/env /etc/apache2/envvars
COPY ./.docker/config/apache2/httpd.conf /etc/apache2/apache2.conf
COPY ./.docker/config/apache2/vhost.conf /etc/apache2/sites-available/000-default.conf

#Copy configuration for s3 sync
COPY ./s3/s3_sync.sh /usr/local/bin/s3_sync.sh
RUN chmod +x /usr/local/bin/s3_sync.sh
RUN touch /var/log/s3_sync.log

# Copy entry point
COPY ./.docker/bash/uvdesk-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/uvdesk-entrypoint.sh;

# Run composer to build dependancies
RUN \
    # Update apache configurations
    a2enmod rewrite; \
    # Download and verify composer installer signature
    wget -O /usr/local/bin/composer.php "https://getcomposer.org/installer"; \
    actualSig="$(wget -q -O - https://composer.github.io/installer.sig)"; \
    currentSig="$(shasum -a 384 /usr/local/bin/composer.php | awk '{print $1}')"; \
    if [ "$currentSig" != "$actualSig" ]; then \
        echo "Warning: Failed to verify composer signature."; \
        exit 1; \
	fi; \
    # Install composer
    php /usr/local/bin/composer.php --install-dir=/usr/local/bin --filename=composer \ && chmod +x /usr/local/bin/composer;

#Add environment file

ADD env /var/www/uvdesk/.env
RUN chmod 775 /var/www/uvdesk/.env


# Clean up files
RUN rm -rf \
    /var/www/html \
    /usr/local/bin/composer.php \
    /var/www/uvdesk-community-current-stable.zip;

RUN usermod -aG uvdesk root && usermod -aG uvdesk www-data;
RUN chown -R uvdesk:uvdesk /var/www;

WORKDIR /var/www

ENTRYPOINT ["uvdesk-entrypoint.sh"]
CMD ["/bin/bash"]