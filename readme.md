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