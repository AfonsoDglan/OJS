# Stage 1: Build PHP/Composer dependencies
FROM composer:2 AS php-builder

# Instalar as extensões PHP necessárias
FROM php:8.0-apache AS php-base

# Instalar as dependências do ICU, Git, e outras ferramentas necessárias
RUN apt-get update && apt-get install -y \
    libicu-dev \
    g++ \
    make \
    git \
    zip \
    unzip \
    && docker-php-ext-configure intl \
    && docker-php-ext-install mysqli pdo pdo_mysql intl

# Copiar o Composer do stage do builder PHP
COPY --from=php-builder /usr/bin/composer /usr/bin/composer

# Configurar o diretório de trabalho e copiar os arquivos do projeto
WORKDIR /var/www/html
COPY . .

# Instalar dependências PHP (Composer)
RUN composer --working-dir=lib/pkp install
RUN composer --working-dir=plugins/generic/citationStyleLanguage install
RUN composer --working-dir=plugins/paymethod/paypal install

# Stage 2: Build JavaScript dependencies
FROM node:16 AS node-builder

# Configurar o diretório de trabalho e copiar os arquivos do projeto
WORKDIR /var/www/html
COPY . .

# Instalar dependências JS e construir o frontend
RUN npm install && npm run build

# Stage 3: Final image
FROM php:8.0-apache

# Instalar as extensões PHP necessárias (novamente no estágio final)
RUN apt-get update && apt-get install -y libicu-dev git zip unzip \
    && docker-php-ext-configure intl \
    && docker-php-ext-install mysqli pdo pdo_mysql intl

# Copiar os arquivos e dependências do PHP e Node.js das fases anteriores
COPY --from=php-base /var/www/html /var/www/html
COPY --from=node-builder /var/www/html /var/www/html

# Configurar o diretório de cache e dar permissões corretas
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    mkdir -p /var/www/files /var/www/html/public /var/www/html/cache/opcache && \
    chown -R www-data:www-data /var/www/files /var/www/html/public /var/www/html/cache/opcache


# Expor a porta 80 para o Apache
EXPOSE 80

# Configurar o Apache para rodar o PHP
CMD ["apache2-foreground"]