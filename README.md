[![OpenMRS Pipeline](https://github.com/OpenMRSTest/ReferenceApplication/actions/workflows/main.yml/badge.svg)](https://github.com/OpenMRSTest/ReferenceApplication/actions/workflows/main.yml)

# OpenMRS project distribution
This repository aims to create an OpenMRS distribution that suits the needs of the project requirements.
That is an OpenMRS client server distribution with the required modules and an SQL database.
This repo will deploy the OpenMRS application in a remote host via ssh using Github Action and docker compose.

# Table of Contents
* [Development Pre Requisites](#development-pre-requisites) 
  * [Pre-commit](#pre-commit)
  * [Colima (only for mac)](#colima-only-for-mac)
  * [Buildx](#buildx)
* [Build own images](#build-own-images)
  * [Docker repository](#docker-repository)
  * [Multi-architecture image push](#multi-architecture-image-push)
* [Database backup](#database-backup)
* [Deployment](#deployment)
  * [Environments to deploy](#environments-to-deploy)
  * [SSH](#ssh)
  * [Deployment user](#deployment-user)

# Development Pre Requisites
## Pre-commit
This project works with [pre-commit](https://pre-commit.com) in order to
guarantee certain minimum requirements.

To install:
`brew install pre-commit`

To prepare the hooks:
```
pre-commit install
pre-commit install --hook-type commit-msg
```

For further information, see [CONTRIBUTING.md](https://github.com/BLOPUP-UPC/blopup-openmrs-distribution/blob/master/CONTRIBUTING.md)

## Colima (only for mac)
The docker runtime is no longer free of charge, so it's needed a docker runtime to be used in development. [Colima](https://github.com/abiosoft/colima) is our friend.

To have the docker running in local machine, follow the next steps: 
```
bash
$> brew install colima
$> brew install docker
$> brew install docker-compose
$> brew install docker-credential-helper
$> colima start
```

Assumptions:
* It's using Mac computer (iOs system)
* Hombrew is installed

To run openMRS images it's required more memory and CPU than the default. To extend this use the following comand:
```
bash
$> colima start --memory 8 --cpu 4
```

For further information about how to install colima, read [this](https://smallsharpsoftwaretools.com/tutorials/use-colima-to-run-docker-containers-on-macos/)

## Buildx
Buildx is an expanded docker images builder, that allows to build multi-architecture images.

To be able to use `buildx` syntax do the following steps below:
```
$ curl -LO https://github.com/docker/buildx/releases/download/${VERSION}/buildx-${VERSION}.darwin-${ARCH}
$ mkdir -p ~/.docker/cli-plugins
$ mv buildx-${VERSION}.darwin-${ARCH} ~/.docker/cli-plugins/docker-buildx
$ chmod +x ~/.docker/cli-plugins/docker-buildx
$ docker buildx version
```

Versions: https://github.com/docker/buildx/releases

Architectures:
* For M1 chip: `arm64`
* For intel chip: `amd64`

If it doesn't work go to official page: https://docs.docker.com/build/buildx/install/ or go to the versions link and download manually the version needed.

And done!

# Build own images
To use our own modules or different version of OpenMRS modules, we should create a new image to control it.
OpenMRs provides an SDK to do this based on an `openmrs-distro.properties`. To install said SDK follow [this steps](https://wiki.openmrs.org/display/docs/OpenMRS+SDK#OpenMRSSDK-Installation).

To create the image use the following statement:
```
$ mvn openmrs-sdk:build-distro -e -Ddistro=src/main/resources/{DISTRO_NAME}.properties -Ddir=docker
```
Real example: 
```
$ mvn openmrs-sdk:build-distro -e -Ddistro=src/main/resources/openmrs-distro.properties -Ddir=docker
```

The previous statement generates all the necessary files to create the docker image in the `-Ddir` folder.

> **Warning**
> All files on the -Ddir folder will be **REMOVED** and recreated.

## Docker repository
We have a free [docker hub account](https://hub.docker.com/repository/docker/blopup/openmrs-referenceapplication) to host all docker images.

If needed, ask any of the team members for the user and password.

## Multi-architecture image push
By default, all images are generated with the local machine architecture. To do the image compatible with different architectures it's required to execute this command in the `-Ddir` folder.

To push an image compatible with linux/amd64 and linux/arm64 architecture:
```
$ docker buildx build --push --platform linux/amd64,linux/arm64 --tag blopup/openmrs-referenceapplication:tag .
```

The general syntax:
```
$ docker buildx build --push --platform=[architectures name]--tag [image name]:[version] .
```

# Database backup
To create the database dump use the below command (it's need to change the database name):
```
$ mysqldump -u root -p database_name > database_name.sql --result-file="${FILENAME_LOCATION}/dump.sql" --skip-lock-tables --skip-add-locks --skip-disable-keys --skip-add-drop-table --column-statistics=0 --skip-create-options --extended-insert --all-databases
```
After generating the dump, you can execute the sql commands in the new database.

# Deployment
This application consist of 3 docker images:
* Traefik as a reverse-proxy
* OpenMRS client-server distribution
* Relational database. MariaDB(10.10.2 at the time of writing)

## Environments to deploy
To use the same pipeline for different environments add ```input``` attribute in your pipeline. This attribute must be choice type. Moreover, in options parameter it's needed to add the different environments.
```
on:
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        description: Select environment
        options:
          - blopup-dev.upc.edu     #environment1
          - blopup-staging.upc.edu #environment2
```

## SSH
Deployment to the remote host from [this Github Actions pipeline](https://github.com/BLOPUP-UPC/blopup-openmrs-distribution/blob/master/.github/workflows/main.yml) will be done securily over SSL using ssh keys. We have created a deployment user in the remote host and added an SSH key. The private key content must be stored in the GitHub Secrets like this:
* DOCKER_SSH_PRIVATE_KEY: the private key in pem format


## Deployment user
To create a new user follow the next steps in this section, inside the remote host.
```
$ useradd deployment 
$ mkdir -p /home/deployment/.ssh
$ chown -R deployment /home/deployment # To add permissions
```

After that, add the user to the corresponding group.
```
$ sudo usermod -aG docker deployment
$ newgrp docker #apply new changes
```

> **Note**
> Use `groups` to see if group it was created.
> For more information about groups, click [here](https://phoenixnap.com/kb/docker-permission-denied)

Now, we have to create an SSH key for the deployment user. 
```
$ ssh-keygen -C "$(whoami)@blopup.upc.edu"
```
This will prompt you for the key name and the passphrase. 

> **Note**
> In non-prod environment we left the passphrase empty

We have to create an `authorized-keys` file and copy the public key inside. 

```
$ cat <key_name>.pub > authorized-keys 
```

The content of the private key must be stored in a GitHub secret named `DOCKER_SSH_PRIVATE_KEY`.