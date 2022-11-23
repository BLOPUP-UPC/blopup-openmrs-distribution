# Description
Run openmrs distribution referenceapplication and mysql as docker containers.

## Requirements
  - Docker engine
  - Docker compose

## Modules 
If you want to use your own modules or different version of OpenMRS modules, you should create a new image to control it.

### Multi-architecture image push
To push an image compatible with linux/amd64 and linux/arm64 architecture: 
```
$ docker buildx build --push --platform linux/amd64,linux/arm64 --tag blopup/openmrs-referenceapplication:1.0.0 .
```

The general syntax:
```
$ docker buildx build --push --platform=[architectures name]--tag [image name]:[version] .
```

❗️ This statement must be use in the root of the Dockerfile. 

### Buildx
To be able to use 'buildx' syntax do the following steps below:

VERSIONS --> https://github.com/docker/buildx/releases
ARCH (for M1 chip) = arm64
ARCH (for intel chip) = amd64
```
$ curl -LO https://github.com/docker/buildx/releases/download/${VERSION}/buildx-${VERSION}.darwin-${ARCH}
$ mkdir -p ~/.docker/cli-plugins
$ mv buildx-${VERSION}.darwin-${ARCH} ~/.docker/cli-plugins/docker-buildx
$ chmod +x ~/.docker/cli-plugins/docker-buildx
$ docker buildx version
```

If it doesn't work go to official page: https://docs.docker.com/build/buildx/install/ or go to the versions link and download manually the version needed.

## Database
To create the database dump use the below command (we need to change the database name): 
```
$ mysqldump -u root -p database_name > database_name.sql
```
 
## Development

To start both containers:
```
$ docker-compose up
```

Application will be accessible on http://localhost:8080/openmrs.

Note: if you are using Docker Toolbox you need to replace `localhost` with the IP address of your docker machine,
which you can get by running:
```
$ docker-machine url
```

Use _CTRL + C_ to stop all containers.

If you made any changes (modified modules/owas/war) to the distro run:
```
$ docker-compose up --build
```

If you want to destroy containers and delete any left over volumes and data when doing changes to the docker
configuration and images run:
```
$ docker-compose down -v
```

In the development mode the OpenMRS server is run in a debug mode and exposed at port 1044. You can change the port by
setting the DEBUG_PORT environment property or by editing the `.evn` file before starting up containers.

Similarly MySQL is exposed at port 3306 and can be customized by setting the MYSQL_PORT property.

## Production

To start containers in production:
```
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up
```

Application will be accessible on http://localhost/openmrs.

Note that in contrary to the development mode the OpenMRS server is exposed on port 80 instead of 8080.
No other ports are exposed in the production mode.

## Customisations

The `docker-compose.yml` is an example and can be customised. The next time you run openmrs-sdk:build-distro, it will
not modify your docker files, but update war and modules if needed. If you want SDK to recreate your docker files,
run:
```
$ mvn openmrs-sdk:build-distro -Dreset
```

### Customizing initial database

If you want to build a distribution with a database in a certain state you can pass a db dump to the build-distro goal:
```
$ mvn openmrs-sdk:build-distro -DdbSql=initial_db.sql
```

## Deploying referenceapplication to dockerhub

The image in 'referenceapplication' can be built and pushed to dockerhub, to be used in test environments or production:

```
$ cd referenceapplication
$ docker build -t <username>/openmrs-referenceapplication:latest .
$ docker push <username>/openmrs-referenceapplication:latest
```

If the image is pushed to dockerhub, `docker-compose.yml` can be modified to use that image
instead of building the new image.

## Other similar docker images and relevant links
- <https://wiki.openmrs.org/display/RES/Demo+Data>
- <https://wiki.openmrs.org/display/docs/Installing+OpenMRS+on+Docker>
- <https://github.com/tusharsoni/OpenMRS-Docker/blob/master/Dockerfile>
- <https://github.com/chaityabshah/openmrs-core-docker/blob/master/Dockerfile>
- <https://github.com/bmamlin/openmrs-core-docker/blob/master/Dockerfile>
