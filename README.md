[![OpenMRS Pipeline](https://github.com/OpenMRSTest/ReferenceApplication/actions/workflows/main.yml/badge.svg)](https://github.com/OpenMRSTest/ReferenceApplication/actions/workflows/main.yml)
# Build docker-compose distro
https://wiki.openmrs.org/display/docs/OpenMRS+SDK#OpenMRSSDK-Creatingdockerconfigurationfordistribution

```shell
./mvnw openmrs-sdk:build-distro -Ddistro=src/main/resources/openmrs-distro.properties -Ddir=docker/generated
```

```shell
printf '%s\n' n | ./mvnw org.openmrs.maven.plugins:openmrs-sdk-maven-plugin:setup-sdk
```

# Set up remote docker
https://www.docker.com/blog/how-to-deploy-on-remote-docker-hosts-with-docker-compose/

## Directly
```shell
DOCKER_HOST="ssh://[remoteUser]@[remoteHost]" docker-compose up -d
```

## Docker context
```shell
docker context create remote ‐‐docker "host=ssh://[remoteUser]@[remoteHost]"
```

