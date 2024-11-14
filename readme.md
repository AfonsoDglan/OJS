# OJS (Open Journal Systems)

O Open Journal Systems (OJS) é uma aplicação de código aberto desenvolvida para facilitar a gestão e a publicação de revistas acadêmicas e científicas online. Criado pela Public Knowledge Project (PKP), o OJS é amplamente utilizado por universidades e instituições de pesquisa em todo o mundo, fornecendo uma plataforma robusta para editores, autores e revisores.

### Documentação Oficial

Para mais detalhes sobre o projeto, instalação e contribuições, visite o [GitHub Oficial do OJS](https://github.com/pkp/ojs).

##### Créditos
O OJS é desenvolvido e mantido pela Public Knowledge Project (PKP). Para mais informações, visite o [site oficial](https://pkp.sfu.ca/software/ojs/).

# Instalação e Manutenção com Docker

### Essa documentação consta duas maneiras de instalação
- ### Primeira forma de instalação é usar uma imagem pronta do ojs no docker hub
- ### Segunda forma de instalação iremos clonar o projeto do projeto e criar a imagem que será usada para dockerizar o projeto.  

## Pré-requisitos
Antes de começar, certifique-se de que você tem os seguintes itens instalados:

- [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
### 
# Instalação - Primeira forma de instalação.
### Clone o repositório
Para clonar o repositório do ojs:

```sh
git clone https://github.com/pkp/docker-ojs.git
```

### Renomei sua pasta

```sh
mv docker-ojs meujornal
```

### Agora acesso a pasta do repositório.

```sh
cd meujornal
```

### Renomei o arquivo de variaveis de ambiente.

```sh
mv .env.TEMPLATE .env
```

### Baixe o arquivo de configuração do ojs de acordo com a cersão usada.

```sh
source .env && wget "https://github.com/pkp/ojs/raw/${OJS_VERSION}/config.TEMPLATE.inc.php" -O ./volumes/config/ojs.config.inc.php
```
Caso você esteja usando o windowns use o comando abaixo.

```sh
wget "https://github.com/pkp/ojs/raw/3_3_0-14/config.TEMPLATE.inc.php" -O ./volumes/config/ojs.config.inc.php
```

### Dê as permissões para as pstas.

```sh
sudo chown 100:101 ./volumes -R
```
```sh
sudo chown 999:999 ./volumes/db -R
```

### Crie as pastas mapedas para volumes 

```sh
mkdir -p ./volumes/private
```
```sh
mkdir -p ./volumes/public
```

### Dê as permissões para as pstas.

```sh
chmod -R 777 ./volumes/private
```
```sh
chmod -R 777 ./volumes/public
```

### Agora para criar nossos coneiner e rodar a aplicação execulte
```sh
docker compose up -d
```
Isso irá iniciar os containers do MySQL e do OJS.

# Instalação - Segunda forma de instalação.

### Clone o repositório
Para clonar o repositório do ojs:

```sh
git clone https://github.com/pkp/ojs --recurse-submodules -b stable-3_4_0
```

### Se atentar a branch do projeto que está sendo clonada.

### Copiar o arquivo de configuração padrão a ser usado no projeto.

```sh
cp config.TEMPLATE.inc.php config.inc.php
```

### Abrir o arquivo config.inc.php, procurar as configurações de banco de dados e atualizar com as informações do seu banco de dados a ser usado no proejto.

```php
[database]

driver = <driver>   # mysql or postgres9
host = <host>       # usually `localhost`
username = <user>
password = <pass>
name = <db>
```

### Usando as informações do banco de dados usado no projeto em docker fica assim:

```php
[database]

driver = mysqli
host = db
username = ojs
password = ojsPassword
name = ojs
```

### Agora crie o arquivo Dockerfile

```sh
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
```

### vamos criar o arquivo docker-compose.yml para gerenciar nossos serviços docker.
```yml
version: "3.8"

networks:
  inside:
    external: false

volumes:
  db_data:
  ojs_files:
  ojs_public:
  ojs_logs:
  ojs_cache:

services:
  db:
    image: mariadb:10.2
    container_name: "ojs_db_${COMPOSE_PROJECT_NAME}"
    environment:
      MYSQL_ROOT_PASSWORD: "${MYSQL_ROOT_PASSWORD}"
      MYSQL_DATABASE: "${OJS_DB_NAME}"
      MYSQL_USER: "${OJS_DB_USER}"
      MYSQL_PASSWORD: "${OJS_DB_PASSWORD}"
    volumes:
      - db_data:/var/lib/mysql
      - ./volumes/dump:/docker-entrypoint-initdb.d
    networks:
      - inside
    restart: always

  ojs:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: "ojs_app_${COMPOSE_PROJECT_NAME}"
    hostname: "${COMPOSE_PROJECT_NAME}"
    ports:
      - "${HTTP_PORT}:80"
    environment:
      MYSQL_HOST: db
      MYSQL_DATABASE: "${OJS_DB_NAME}"
      MYSQL_USER: "${OJS_DB_USER}"
      MYSQL_PASSWORD: "${OJS_DB_PASSWORD}"
    volumes:
      - ojs_files:/var/www/files
      - ojs_public:/var/www/html/public
      - ojs_logs:/var/log/apache2
      - ojs_cache:/var/www/html/cache/opcache
    networks:
      - inside
    depends_on:
      - db
    restart: always
```

### Renomear o arquivo .env-exemplo para .env e altere as variaveis de ambiente e altere as senha e configurações para o projeto.

```sh
mv .env-exemplo .env
```

### Agora para criar nossos coneiner e rodar a aplicação execulte
```sh
docker compose up -d
```
Isso irá iniciar os containers do MySQL e do OJS.

# Configuração do OJS

## 1. Acessar o OJS via navegador

Após iniciar o Docker, abra o navegador e vá para [http://localhost:8080](http://localhost:8080).

## 2. Configuração Inicial

No navegador, você deverá ver a página de configuração do OJS, onde precisará fornecer as credenciais do banco de dados. Utilize as mesmas credenciais fornecidas no docker-compose.yml

- **Database Host:** db
- **Database Name:** ojs
- **Database Username:** ojs_user
- **Database Password:** ojs_password

## 3. Finalizar a configuração

Complete as demais configurações solicitadas pelo OJS e siga os passos até concluir o processo de instalação.

# Manutenção

## Backup de Dados

### 1. Backup do banco de dados

Para fazer backup do banco de dados MySQL:

```sh
docker exec ojs_db /usr/bin/mysqldump -u ojs_user --password=ojs_password ojs > backup.sql
```

### 2. Backup dos arquivos

Os arquivos da aplicação estão montados no volume ojs_data. Você pode copiar o conteúdo do volume para um local seguro.

```sh
docker cp ojs_app:/var/www/html /path/to/backup
```

# Atualização
## 1. Atualizar o OJS


# Restaurar de um Backup
## 1. Restaurar o banco de dados

Para restaurar o banco de dados a partir de um backup:

```sh
docker exec -i ojs_db /usr/bin/mysql -u ojs_user --password=ojs_password ojs < backup.sql
```

## 2. Restaurar os arquivos

Restaure os arquivos da aplicação:

```sh
docker cp /path/to/backup ojs_app:/var/www/html
```

Certifique-se de ajustar as permissões após restaurar:

```sh
docker exec ojs_app chown -R www-data:www-data /var/www/html
```