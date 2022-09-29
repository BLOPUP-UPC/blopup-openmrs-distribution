[![OpenMRS Pipeline](https://github.com/OpenMRSTest/ReferenceApplication/actions/workflows/main.yml/badge.svg)](https://github.com/OpenMRSTest/ReferenceApplication/actions/workflows/main.yml)

# OpenMRS project distribution
This repo aims to create a OpenMRS distribution that suits the needs of the project requirements.
That is a OpenMRS client server distribution with the required modules and an SQL database.
This repo will deploy the OpenMRS application in a remote host via ssh using Github Action and docker compose.

# Table of Contents

* [Table of Contents](#table-of-contents)
  * [Development Pre Requisites](#development-pre-requisites)
  * [Deployment](#deployment)
    * [SSH](#ssh)
    * [References](#references)

## Development Pre Requisites
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

For more information, see [CONTRIBUTING.md](https://github.com/BLOPUP-UPC/blopup-openmrs-distribution/blob/master/CONTRIBUTING.md)

## Deployment
This application consist of 3 docker images:
* Traefik as a reverse-proxy
* OpenMRS client-server distribution
* Relational database. MySQL(5.6 at the time of writing) 

### SSH

Deployment to the remote host securily from [this Github Actions pipeline](https://github.com/BLOPUP-UPC/blopup-openmrs-distribution/blob/master/.github/workflows/main.yml) will be done over SSL using private public ssh keys. Those must be available in the Repository Secrets of this repository and also the public key installed in the host machine.
This secrets must be created in this repo:
* DOCKER_SSH_PRIVATE_KEY: the private key in pem format
* DOMAIN: The dns name of the remote host

### References
* [Remote host deployment](https://www.docker.com/blog/how-to-deploy-on-remote-docker-hosts-with-docker-compose/)