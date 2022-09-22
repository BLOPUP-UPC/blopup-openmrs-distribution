[![OpenMRS Pipeline](https://github.com/OpenMRSTest/ReferenceApplication/actions/workflows/main.yml/badge.svg)](https://github.com/OpenMRSTest/ReferenceApplication/actions/workflows/main.yml)

# OpenMRS project distribution
This repo aims to create a OpenMRS distribution that suits the needs of the project requirements.
That is a OpenMRS client server distribution with the required modules and a database MySQL compatible.
This repo will build and configure both services and package them into Docker images.
It will also create a Github Action pipeline to automate the above task and deploy the resulting docker stack into a VM using either docker compose or docker swarm technology.

# Table of Contents

* [OpenMRS project distribution](#openmrs-project-distribution)
* [Table of Contents](#table-of-contents)
  * [Pre Requisites](#pre-requisites)
  * [Build docker-compose distro](#build-docker-compose-distro)
  * [Deployment](#deployment)
    * [Docker swarm](#docker-swarm)
    * [Github action to deploy](#github-action-to-deploy)
    * [SSH](#ssh)
    * [References](#references)

## Pre Requisites
This project works with [pre-commit](https://pre-commit.com) in order to
guarantee certain minimum requirements.

To install:
`brew install pre-commit`

To prepare the hooks:
```
pre-commit install
pre-commit install --hook-type commit-msg
```

And done!

## Build docker-compose distro
This will be achieved using OpenMRS maven SDK as described [here in the OpenMRS documentation](https://wiki.openmrs.org/display/docs/OpenMRS+SDK#OpenMRSSDK-Creatingdockerconfigurationfordistribution).

* Set up OpenMRS maven SDK
```shell
./mvnw org.openmrs.maven.plugins:openmrs-sdk-maven-plugin:setup-sdk
```
* Create docker distributionm files in the designed directory
```shell
./mvnw openmrs-sdk:build-distro -Ddistro=src/main/resources/openmrs-distro.properties -Ddir=docker/generated
```

## Deployment
This application consist of 2 docker images:
* OpenMRS client-server distribution
* Relational database. MySQL (Other can be used such as MariaDB or Postgres)

Docker swarm cluster has been chosen in order to deploy this stack. At first the stack will only be deployed to a single host/node to avoid
complexity but at the same time being able to easily expand to several nodes. This way it will be possible to scale out the application.
### Docker swarm
Remote host should have swarm mode initialized
* `docker swarm init`

To deploy docker stack manually to docker swarm
* `docker stack deploy -c [compose file name] [service name]`

### Github action to deploy
THis already available action is used to deploy whit docker swarm:
https://github.com/wshihadeh/docker-deployment-action
### SSH

Deployment to the remote host securily from [this Github Actions pipeline](.github/workflows/main.yml) will be done over SSL using private public ssh keys. Those must be available in the Repository Secrets of this repository and also the public key installed in the host machine.
This secrets must be created in this repo:
* DOCKER_SSH_PRIVATE_KEY: the private key in pem format
* DOCKER_SSH_PUBLIC_KEY: the public key fingerprint (this is not the public key). Similar as the one created in `${HOME}/.ssh/known_hosts` when a remote terminal connection is done via ssh.
* DOCKER_HOST: The ip or the dns name of the remote host

In order to retrieve the public key fingerprint a remote terminal session over ssh can be done. Once the remote host is trusted the public key fingerprint will be placed in `${HOME}/.ssh/known_hosts`.
1. `cat ${HOME}/.ssh/known_hosts`
2. Copy the public key fingerprint part. The full entry has the format `[HOST] [public key fingerprint]`. Example of public key fingerprint:

### References
* [Remote host deployment](https://www.docker.com/blog/how-to-deploy-on-remote-docker-hosts-with-docker-compose/)
* [Intro to swarm](https://dockerswarm.rocks/)
