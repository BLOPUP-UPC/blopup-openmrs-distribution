[![prod](https://github.com/BLOPUP-UPC/blopup-openmrs-distribution/actions/workflows/deploy-to-prod.yml/badge.svg)](https://github.com/BLOPUP-UPC/blopup-openmrs-distribution/actions/workflows/deploy-to-prod.yml)
[![non-prod](https://github.com/BLOPUP-UPC/blopup-openmrs-distribution/actions/workflows/deploy-to-non-prod.yml/badge.svg)](https://github.com/BLOPUP-UPC/blopup-openmrs-distribution/actions/workflows/deploy-to-non-prod.yml)

# OpenMRS project distribution

This repository aims to create an OpenMRS distribution that suits the needs of the project requirements.
That is an OpenMRS client server distribution with the required modules and an SQL database.
This repo will deploy the OpenMRS application in a remote host via ssh using Github Actions and docker compose.

# Table of Contents
* [Development Pre Requisites](#development-pre-requisites) 
  * [Colima (only for mac)](#colima-only-for-mac)
* [Build our own images](#build-our-own-images)
  * [Updating the modules](#updating-the-modules)
  * [Docker repository](#docker-repository)
* [Deployment](#deployment)
* [Traefik](#traefik)
  * [Routing](#routing)
  * [Docker socket](#docker-socket)
* [Metrics dashboard - Clasp](#Metrics-dashboard)
* [Troubleshooting](#troubleshooting)

# Development Pre Requisites

## Colima (only for mac)
The docker runtime is no longer free of charge, so a docker runtime is needed to be used in development. [Colima](https://github.com/abiosoft/colima) is our friend.

To have the docker running in local machine, follow the next steps: 
```bash
brew install colima
brew install docker
brew install docker-compose
brew install docker-credential-helper
colima start
```

Assumptions:
* You are using a Mac computer.
* [Homebrew](https://brew.sh/) is installed.

To run openMRS images, more memory and CPU than the default are required. To extend this, use the following command:
```bash
colima start --memory 8 --cpu 4
```

For further information about how to install colima, read [this](https://smallsharpsoftwaretools.com/tutorials/use-colima-to-run-docker-containers-on-macos/)

# Build our own images

## Updating the modules

As OpenMRS has a modular architecture, all changes to the backend are applied through introducing new or modifying existing modules. 
To add a new module or make sure an existing module is up-to-date, you have to complete the following steps:
1. In the module repo
   * make sure that you have included the `build-and-release-omod-file` workflow (check out the blopup-file-upload-module repo for an example)
   * the project name should follow this format: `blopup.<module-name>`. The module name can't contain special characters.
2. In the `scripts` folder, you need to add the module name to the `update-custom-modules.sh` file

## Creating a module 

To use our own modules or different version of OpenMRS modules, we should create a new image to control it. 
OpenMRs provides an SDK to help with this, based on an [openmrs-distro.properties](src/main/resources/openmrs-distro.properties) file. 
To install said SDK and generate the necessary files for the image, follow this steps (more information [here](https://wiki.openmrs.org/display/docs/OpenMRS+SDK#OpenMRSSDK-Installation)):

```bash
mvn org.openmrs.maven.plugins:openmrs-sdk-maven-plugin:setup-sdk
```

Then, from the root of the repository, you have to execute this command:

```bash
mvn openmrs-sdk:build-distro -e -Ddistro=src/main/resources/openmrs-distro.properties -Ddir=update
```

This will create an `update` folder with some files in it. Then you have to copy the `openmrs.war` file, and the `modules` and `owa` folders to the `docker/web` folder, and replace them. You can then remove the `update` folder (please, do not commit it).

> **Warning**
> All files on the -Ddir folder will be **REMOVED** and recreated. Please don't use the docker folder as a value for the -Ddir parameter.

## Docker repository
We have a free [docker hub account](https://hub.docker.com/repository/docker/blopup/openmrs-referenceapplication) to host all docker images.

If needed, ask any of the team members for the user and password.

# Deployment

Our system contains four docker images:

* Docker socket proxy for security
* Traefik as a reverse-proxy and SSL certificate provider
* OpenMRS client-server distribution
* Relational database (only for non-prod environments). MariaDB(10.10.2 at the time of writing)

The deployment is done via github actions in the github repository. There is a pipeline for non-prod environments and another one for production.

# Running the application locally

You just have to run the following command from the root of the repository:

```bash
docker compose -f docker-compose-local.yml up -d --build
```

The [.env](.env) file contains the environment variables used to deploy the app and the database in your local machine.

# Traefik

Traefik is used as a reverse proxy and for SSL with Let's encrypt. The reverse proxy redirects all http traffic to https and it routes some paths to different docker containers.

## Routing

We are currently routing only one backend application, the OpenMRS distribution that we generate in this repository. Internally, openmrs runs in port 8080 and Traefik is redirecting all calls to the root path to said port.

To configure routing to new apps, you just need to add some labels to the service you want to redirect in the `docker-compose.yml` file.

```yaml
- traefik.enable=true 
- traefik.http.routers.{name-of-app}.rule=Host(`${DOMAIN:-localhost}`) && PathPrefix(`/$PATH_TO_APP`)
- traefik.http.routers.{name-of-app}.middlewares={name-of-app}-stripprefix
- traefik.http.middlewares.{name-of-app}-stripprefix.stripprefix.prefixes=/$PATH_TO_APP
```

## Docker socket

Traefik is docker aware. This means that it connects to the docker socket running on the host machine to query the active containers for the routing. This is a security issue since, by default, it has no limitations on the docker API. To solve this, we've followed [these steps](https://medium.com/@containeroo/traefik-2-0-paranoid-about-mounting-var-run-docker-sock-22da9cb3e78c) and we've added a docker socket proxy image that exposes a read-only docker API.

The docker socket proxy uses the host docker socket and exposes it with some configurable limitations (in our case, we only expose the container API). 

> **Warning**
> If you are using colima as a docker runtime in your host machine, you need to make sure that there is a symlink to the colima socket under the `/var/run/docker.sock` path. If the `/var/run/docker.sock` does not exist follow the steps below

# Metrics dashboard

The dashboard that show metrics about the projects is hosted in Google Sheets. The dashboard is updated automatically
every day based on reports from this server accessed by API.

The scripts are stored in the `.appsscript` folder and is managed using the [clasp](https://developers.google.com/apps-script/guides/clasp) tool.

# Troubleshooting

**Problem**

OpenMRS does not start and in the logs you can see something like

```
App 'referenceapplication.registrationapp.registerPatient' says its an instanceOf 'registrationapp.registerPatient' but there is no AppTemplate with that id
```

**Cause**

This error means that the character set and collation of the database is not set correctly. Openmrs expects a value of utf8 for character and utf8_general_ci for collation.

**Solution**

If you are using a dockerised database, make sure to include this in the `command` section of the image:

```yaml
command: "mysqld --character-set-server=utf8 --collation-server=utf8_general_ci"
```

If you are using a database in another host or in your local machine, execute this SQL commands in the database directly:

```mysql
SET character_set_server = 'utf-8';
SET collation_server = 'utf8_general_ci';
```

**Problem**
OpenMRS does not start and in the logs you can see something like

```
1 change sets check sum
          liquibase.xml::daa579e7-b8de-4858-bfe5-c9ef2606db5e::Samuel Male was: 8:8c0e70ceade1a06bd939857cc4d82841 but is now: 8:fa0293619384334f16e246e0aab32df7
```

**Cause**

The md5sum of liquibase in your database is different from the one in the repository changeset.

This usually happens when you load a database dump from and old version of openmrs to a newer version.

**Solution**

You can try updating the relevant module or service version or you can just change the md5sum in your database for the correct one. In the case of the example above, you should need to run this SQL command

```mysql
UPDATE openmrs.liquibasechangelog SET MD5SUM = '8:fa0293619384334f16e246e0aab32df7' WHERE MD5SUM = '8:8c0e70ceade1a06bd939857cc4d82841';
```

> **Warning**
> Be very careful when updating a database manually. Never autocommit and make sure that only one row is affected before committing the database transaction.