# Use official PHP image with FPM
FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    unzip \
    curl \
    git \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    mariadb-client \
    nginx \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql gd zip

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Set working directory
WORKDIR /var/www

# Copy project files
COPY . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --ignore-platform-reqs

# Fix Laravel Mix build issues
ENV NODE_OPTIONS="--max-old-space-size=512"

# Install Node.js dependencies and build assets
RUN npm install && npm run prod

# Generate Laravel app key
RUN php artisan key:generate

# Ensure storage is linked correctly
RUN php artisan storage:link

# Set proper permissions
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache /var/www/public && \
    chmod -R 775 /var/www/storage /var/www/bootstrap/cache /var/www/public

# Copy Nginx configuration and enable site
COPY ./nginx/default.conf /etc/nginx/sites-available/default
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Expose ports for Nginx and PHP-FPM
EXPOSE 80

# Start both PHP-FPM and Nginx properly
CMD ["sh", "-c", "nginx && php-fpm"]
