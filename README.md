[![OpenMRS Pipeline](https://github.com/OpenMRSTest/ReferenceApplication/actions/workflows/main.yml/badge.svg)](https://github.com/OpenMRSTest/ReferenceApplication/actions/workflows/main.yml)

# OpenMRS project distribution
This repo aims to create a OpenMRS distribution that suits the needs of the project requirements.
That is a OpenMRS client server distribution with the required modules and a database MySQL compatible.
This repo will build and configure both services and package them into Docker images.
It will also create a Github Action pipeline to automate the above task and deploy the resulting docker stack into a VM using either docker compose or docker swarm technology.

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

## Deploy to a remote docker host
https://www.docker.com/blog/how-to-deploy-on-remote-docker-hosts-with-docker-compose/

### Directly
```shell
DOCKER_HOST="ssh://[remoteUser]@[remoteHost]" docker-compose up -d
```

### Docker context
```shell
docker context create remote ‐‐docker "host=ssh://[remoteUser]@[remoteHost]"
```

