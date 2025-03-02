# Advanced Docker Setup

_Credit goes to @Helmi for creating this setup_

## What is different from the basic setup

- Web services (`teslamate` and `grafana`) sits behind a reverse proxy (Traefik) which terminates HTTPS traffic
- Custom configuration was moved into a separate `.env` file
- All publicly accessible services use fully qualified domain name and automatically acquire a Let's Encrypt certificate

## Requirements

* Docker running on a machine that's always on
* Two FQDN (`teslamate.example.com` & `grafana.example.com`)
* External internet access, to talk to tesla.com

## Quick Start

Create the following three files:

### docker-compose.yml

```YAML
version: '3'

services:
  teslamate:
    image: teslamate/teslamate:latest
    restart: always
    depends_on:
      - database
    environment:
      - DATABASE_USER=${TM_DB_USER}
      - DATABASE_PASS=${TM_DB_PASS}
      - DATABASE_NAME=${TM_DB_NAME}
      - DATABASE_HOST=database
      - MQTT_HOST=mosquitto
      - VIRTUAL_HOST=${FQDN_TM}
      - CHECK_ORIGIN=true
      - TZ={$TM_TZ}
    labels:
      - 'traefik.enable=true'
      - 'traefik.port=4000'
      - "traefik.http.middlewares.redirect.redirectscheme.scheme=https"
      - "traefik.http.middlewares.auth.basicauth.usersfile=/auth/.htpasswd"
      - "traefik.http.routers.teslamate-insecure.rule=Host(`${FQDN_TM}`)"
      - "traefik.http.routers.teslamate-insecure.middlewares=redirect"
      - "traefik.http.routers.teslamate.rule=Host(`${FQDN_TM}`)"
      - "traefik.http.routers.teslamate.middlewares=auth"
      - "traefik.http.routers.teslamate.entrypoints=websecure"
      - "traefik.http.routers.teslamate.tls.certresolver=tmhttpchallenge"

  database:
    image: postgres:11
    restart: always
    environment:
      - POSTGRES_USER=${TM_DB_USER}
      - POSTGRES_PASSWORD=${TM_DB_PASS}
      - POSTGRES_DB=${TM_DB_NAME}
    volumes:
      - teslamate-db:/var/lib/postgresql/data

  grafana:
    image: teslamate/grafana:latest
    restart: always
    environment:
      - DATABASE_USER=${TM_DB_USER}
      - DATABASE_PASS=${TM_DB_PASS}
      - DATABASE_NAME=${TM_DB_NAME}
      - DATABASE_HOST=database
      - GRAFANA_PASSWD=${GRAFANA_PW}
      - GF_SECURITY_ADMIN_USER=${GRAFANA_USER}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PW}
      - GF_AUTH_BASIC_ENABLED=true
      - GF_AUTH_ANONYMOUS_ENABLED=false
      - GF_SERVER_ROOT_URL=https://${FQDN_GRAFANA}
    volumes:
      - teslamate-grafana-data:/var/lib/grafana
    labels:
      - 'traefik.enable=true'
      - 'traefik.port=3000'
      - "traefik.http.middlewares.redirect.redirectscheme.scheme=https"
      - "traefik.http.routers.grafana-insecure.rule=Host(`${FQDN_GRAFANA}`)"
      - "traefik.http.routers.grafana-insecure.middlewares=redirect"
      - "traefik.http.routers.grafana.rule=Host(`${FQDN_GRAFANA}`)"
      - "traefik.http.routers.grafana.entrypoints=websecure"
      - "traefik.http.routers.grafana.tls.certresolver=tmhttpchallenge"

  mosquitto:
    image: eclipse-mosquitto:1.6
    restart: always
    volumes:
      - mosquitto-conf:/mosquitto/config
      - mosquitto-data:/mosquitto/data

  proxy:
    image: traefik:v2.0
    restart: always
    command:
      - "--global.sendAnonymousUsage=false"
      - "--providers.docker"
      - "--providers.docker.exposedByDefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.tmhttpchallenge.acme.httpchallenge=true"
      - "--certificatesresolvers.tmhttpchallenge.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.tmhttpchallenge.acme.email=${LETSENCRYPT_EMAIL}"
      - "--certificatesresolvers.tmhttpchallenge.acme.storage=/etc/acme/acme.json"
    ports:
      - 80:80
      - 443:443
    volumes:
      - ./.htpasswd:/auth/.htpasswd
      - ./acme/:/etc/acme/
      - /var/run/docker.sock:/var/run/docker.sock:ro

volumes:
    teslamate-db:
    teslamate-grafana-data:
    mosquitto-conf:
    mosquitto-data:
```

### .env

```
TM_DB_USER=teslamate
TM_DB_PASS=secret
TM_DB_NAME=teslamate

GRAFANA_USER=admin
GRAFANA_PW=admin

FQDN_GRAFANA=grafana.example.com
FQDN_TM=teslamate.example.com

TM_TZ=Europe/Berlin

LETSENCRYPT_EMAIL=yourperson@example.com
```

### .htpasswd

This file contains a user and password for accessing TeslaMate (Basic-auth), note this is NOT your tesla.com password. You can generate it on the web if you don't have the Apache tools installed (e.g. http://www.htaccesstools.com/htpasswd-generator/).

**Example:**

```
teslamate:$apr1$0hau3aWq$yzNEh.ABwZBAIEYZ6WfbH/
```

## Start Docker

Afterwards start the stack with `docker-compose up`.

## Usage

1) Open the web interface [https://tesla.example.com](https://tesla.example.com)
2) Sign in with your Tesla Account open the web interface
3) The Grafana dashboards are available at [https://grafana.example.com](https://grafana.example.com).


## Tips for upgrading from the recommended docker setup

If you are upgrading and want to keep your EXISTING DATA:

- Make sure to setup your `.env` file so the login/password are exactly what you used in your recommended setup (e.g. `teslamate/secret`)
- If you have difficulty logging into your Grafana i.e. you cannot login with the credentials from either the original recommended setup or the values stored in the `.env` file reset the admin password with the following command: `docker-compose exec grafana grafana-cli admin reset-admin-password`
