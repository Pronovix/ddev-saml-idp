#ddev-generated
ARG PHP_IMAGE_TAG=8.4
FROM php:${PHP_IMAGE_TAG}-apache

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        unzip \
        zip \
        libxml2-dev \
        openssl \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions bcmath intl opcache

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# Set up SimpleSAMLphp directory
WORKDIR /var/www/simplesamlphp

# Set Composer environment
ENV COMPOSER_ALLOW_SUPERUSER=1

ARG SSP_VERSION="^2.2"
RUN composer create-project simplesamlphp/simplesamlphp . "${SSP_VERSION}" --no-interaction --no-dev \
    && chown -R www-data:www-data /var/www/simplesamlphp

# Set environment variables for SimpleSAMLphp
ENV SIMPLESAMLPHP_CONFIG_DIR=/var/www/simplesamlphp/config

# Set up Apache virtual host configuration
RUN echo '<VirtualHost *:80>\n\
    DocumentRoot /var/www/html\n\
    RedirectMatch 302 ^/$ /simplesaml/\n\
    \n\
    # Enable mod_remoteip to handle X-Forwarded-For\n\
    <IfModule mod_remoteip.c>\n\
        RemoteIPHeader X-Forwarded-For\n\
        # DDEV network is typically in this range\n\
        RemoteIPInternalProxy 172.0.0.0/8\n\
    </IfModule>\n\
    \n\
    # Forcefully set HTTPS env var based on DDEV router header\n\
    RewriteEngine On\n\
    RewriteCond %{HTTP:X-Forwarded-Proto} =https\n\
    RewriteRule .* - [E=HTTPS:on]\n\
    \n\
    Alias /simplesaml /var/www/simplesamlphp/public\n\
    <Directory /var/www/simplesamlphp/public>\n\
        AllowOverride All\n\
        Require all granted\n\
        # This rewrite is for the application front-controller\n\
        RewriteEngine On\n\
        RewriteBase /simplesaml\n\
        RewriteCond %{REQUEST_FILENAME} !-d\n\
        RewriteCond %{REQUEST_FILENAME} !-f\n\
        RewriteRule ^(.*)$ index.php/$1 [L,QSA]\n\
    </Directory>\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Enable Apache modules
RUN a2enmod rewrite remoteip

# Copy defaults templates and entrypoint script
COPY defaults/ /var/www/simplesamlphp/defaults/
RUN cp /var/www/simplesamlphp/config/config.php.dist /var/www/simplesamlphp/defaults/config.php.dist
COPY entrypoint.sh /var/www/simplesamlphp/entrypoint.sh
RUN chmod +x /var/www/simplesamlphp/entrypoint.sh

ENTRYPOINT ["/var/www/simplesamlphp/entrypoint.sh"]

# Expose port 80
EXPOSE 80
