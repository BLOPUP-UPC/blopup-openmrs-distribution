# Build docker-compose distro
https://wiki.openmrs.org/display/docs/OpenMRS+SDK#OpenMRSSDK-Creatingdockerconfigurationfordistribution

```shell
./mvnw openmrs-sdk:build-distro -Ddistro=src/main/resources/openmrs-distro.properties -Ddir=docker
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

