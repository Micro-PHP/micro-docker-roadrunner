# Micro Docker & RoadRunner environment

A [Docker](https://www.docker.com/)-based installer and runtime for the [Micro](https://micro-php.net) web framework, with [RoadRunner](https://roadrunner.dev/) support.

## Getting Started

1. If not already done, [install Docker Compose](https://docs.docker.com/compose/install/) (v2.10+)
2. To overwrite the main configuration file (.env), simply create a new file that will depend on the APP_ENV environment variable ".env.<$APP_ENV>"
3. Run `make build` to build fresh images
4. Run `make up` (the logs will not be displayed in the current shell. Use `make logs` if you want to see the container's log after it has started.)
5. Open `http://localhost` in your favorite web browser
6. Run `make down` to stop the Docker containers.

## Features

* Production, development and CI ready
* Native [XDebug](docs/xdebug.md) integration

## License
Micro Docker is available under the MIT License.