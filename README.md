[![prod](https://github.com/BLOPUP-UPC/blopup-openmrs-distribution/actions/workflows/deploy-to-prod.yml/badge.svg)](https://github.com/BLOPUP-UPC/blopup-openmrs-distribution/actions/workflows/deploy-to-prod.yml)
[![non-prod](https://github.com/BLOPUP-UPC/blopup-openmrs-distribution/actions/workflows/deploy-to-non-prod.yml/badge.svg)](https://github.com/BLOPUP-UPC/blopup-openmrs-distribution/actions/workflows/deploy-to-non-prod.yml)

# OpenMRS project distribution

This repository aims to create an OpenMRS distribution that suits the needs of the project requirements.
That is an OpenMRS client server distribution with the required modules and an SQL database.
This repo will deploy the OpenMRS application in a remote host via ssh using Github Actions and docker compose.

# Table of Contents
* [Development Pre Requisites](#development-pre-requisites) 
  * [Colima (only for mac)](#colima-only-for-mac)
  * [Buildx](#buildx)
* [Build our own images](#build-our-own-images)
  * [Updating the modules](#updating-the-modules)
  * [Docker repository](#docker-repository)
  * [Multi-architecture image push](#multi-architecture-image-push)
* [Database backup](#database-backup)
* [Deployment](#deployment)
  * [SSH](#ssh)
  * [Deployment user](#deployment-user)
* [Deploy to localhost](#deploy-to-localhost)
* [Traefik](#traefik)
  * [Routing](#routing)
  * [Docker socket](#docker-socket)
    * [Symlink the default docker socket to the colima socket](#symlink-the-default-docker-socket-to-the-colima-socket)
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

## Buildx
Buildx is an expanded docker image builder that allows to build multi-architecture images.

To be able to use `buildx` syntax do the following steps below:
```bash
curl -LO https://github.com/docker/buildx/releases/download/${VERSION}/buildx-${VERSION}.darwin-${ARCH}
mkdir -p ~/.docker/cli-plugins
mv buildx-${VERSION}.darwin-${ARCH} ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx
docker buildx version
```

To see the latest version of `buildx` you can check it [here](https://github.com/docker/buildx/releases)

Architectures:
* For M1 chip: `arm64`
* For intel chip: `amd64`

If it does not work, visit the [official page](https://docs.docker.com/build/buildx/install/) or go to the versions link and manually download the needed version.

# Build our own images

## Updating the modules

To use our own modules or different version of OpenMRS modules, we should create a new image to control it. OpenMRs provides an SDK to help with this, based on an [openmrs-distro.properties](src/main/resources/openmrs-distro.properties) file. To install said SDK and generate the necessary files for the image, follow this steps (more information [here](https://wiki.openmrs.org/display/docs/OpenMRS+SDK#OpenMRSSDK-Installation)):

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

## Multi-architecture image push
By default, all images are generated with the local machine architecture. To build compatible images with different architectures, you have to execute this command in the `docker/web` folder.

```bash
cd docker/web
```

Do a docker login. Credentials are in Bitwarden.
```bash
docker login
```

To push an image compatible with linux/amd64 and linux/arm64 architecture:

```bash
docker buildx build --push --platform linux/amd64,linux/arm64 --tag blopup/openmrs-referenceapplication:latest .
```

The general syntax:
```bash
docker buildx build --push --platform=[architectures name]--tag [dockerhub-user]/[image name]:[version] .
```

Whenever we have to publish a new image, it is convention to push both the image with the version for the tag and also another one with the `latest` tag. The version of the image is defined in the [pom](pom.xml) file and you have to manually modify it accordingly every time you want to build a new image, following the [semantic versioning](https://semver.org/) principles.

# Database backup

To create a database dump, use the below command:
```bash
mysqldump -u root -p [database_name] > [database_name].sql --result-file="${FILENAME_LOCATION}/dump.sql" --skip-lock-tables --skip-add-locks --skip-disable-keys --skip-add-drop-table --column-statistics=0 --skip-create-options --extended-insert --all-databases
```
After generating the dump, you can execute the sql commands inside it in the new database.

# Deployment

Our system contains four docker images:

* Docker socket proxy for security
* Traefik as a reverse-proxy and SSL certificate provider
* OpenMRS client-server distribution
* Relational database (only for non-prod environments). MariaDB(10.10.2 at the time of writing)

The deployment is done via github actions in the github repository. There is a pipeline for non-prod environments and another one for production.

## SSH

Deployment to the remote host from [this Github Actions pipeline](.github/workflows) will be done securely over SSH using ssh keys. We have created a deployment user in the remote hosts and added an SSH key. The private key content must be stored in a GitHub Secret.

## Deployment user

To create a new user follow the next steps in this section, inside the remote host.
```bash
useradd deployment
mkdir -p /home/deployment/.ssh
chown -R deployment /home/deployment
```

After that, add the user to the corresponding group.
```bash
sudo usermod -aG docker deployment
newgrp docker #apply new changes
```

> **Note**
> Use `groups` to see if the group was created.
> For more information about groups, see [here](https://phoenixnap.com/kb/docker-permission-denied)

Now, we have to create an SSH key for the deployment user. 
```bash
cd /home/deployment/.ssh
ssh-keygen -C "$(whoami)@blopup.upc.edu"
```
This will prompt you for the key name and the passphrase. Leave the passphrase empty since this ssh keypair is intended to be used in a non-interactive shell (i.e. the pipeline).

Now you have to create an `authorized-keys` file and copy the content of the public key inside. 

```bash
cat <key_name>.pub > authorized-keys
```

The content of the private key must be stored in a GitHub secret.

# Deploy to localhost

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

### Symlink the default docker socket to the colima socket

```bash
cd /var/run
sudo ln -s ~/.colima/docker.sock docker.sock
```

The colima socket is usually under the `~/.colima/docker.sock` path, but you can run a `colima status` to check if it is there.

```bash
colima status
> INFO[0000] colima is running
> INFO[0000] arch: x86_64
> INFO[0000] runtime: docker
> INFO[0000] mountType: sshfs
> INFO[0000] socket: unix:///Users/your_user_name/.colima/default/docker.sock
```

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