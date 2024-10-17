# OJS (Open Journal Systems)

O Open Journal Systems (OJS) é uma aplicação de código aberto desenvolvida para facilitar a gestão e a publicação de revistas acadêmicas e científicas online. Criado pela Public Knowledge Project (PKP), o OJS é amplamente utilizado por universidades e instituições de pesquisa em todo o mundo, fornecendo uma plataforma robusta para editores, autores e revisores.

### Documentação Oficial

Para mais detalhes sobre o projeto, instalação e contribuições, visite o [GitHub Oficial do OJS](https://github.com/pkp/ojs).

##### Créditos
O OJS é desenvolvido e mantido pela Public Knowledge Project (PKP). Para mais informações, visite o [site oficial](https://pkp.sfu.ca/software/ojs/).

# Instalação e Manutenção com Docker

## Pré-requisitos
Antes de começar, certifique-se de que você tem os seguintes itens instalados:

- [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)

# Instalação
## 1. Clone o repositório
Para clonar o repositório do ojs:

```sh
git clone https://github.com/pkp/ojs.git
```
Agora acesso a pasto do repositório.
```sh
cd ojs
```

## 2. Criação dos arquivos Docker Compose

No diretório do projeto, crie um arquivo docker-compose.yml

```yaml

services:
  db:
    image: mariadb:10.5
    container_name: ojs_db
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: ojs
      MYSQL_USER: ojs_user
      MYSQL_PASSWORD: ojs_password
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - ojs_network

  ojs:
    build: .
    container_name: ojs_app
    depends_on:
      - db
    ports:
      - "8080:80"
    volumes:
      - ojs_data:/var/www/html/public
      - ojs_files:/var/www/files
    environment:
      DB_HOST: db
      DB_NAME: ojs
      DB_USER: ojs_user
      DB_PASSWORD: ojs_password
    networks:
      - ojs_network

volumes:
  db_data:
  ojs_data:

networks:
  ojs_network:


```
## 3. Criação da imagem Docker para o OJS
No diretório do OJS, crie um arquivo Dockerfile:

```Dockerfile
FROM php:7.4-apache

RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd

# Instalar dependências necessárias para o OJS
RUN apt-get update && apt-get install -y git unzip curl

# Clonar o código do OJS
RUN git clone https://github.com/pkp/ojs.git /var/www/html

# Configurar permissões
RUN chown -R www-data:www-data /var/www/html

# Expor a porta 80
EXPOSE 80

```

## 4. Construir e iniciar os containers
Com o docker-compose.yml configurado, execute:

```sh
docker compose up -d --build
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

Para atualizar o OJS, primeiro baixe a nova versão do OJS do repositório:

```sh
git pull origin main
```

Depois, reinicie os containers:

```sh
docker compose down
```

```sh
docker-compose up -d --build
```

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