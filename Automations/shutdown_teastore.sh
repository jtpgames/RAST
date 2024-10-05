#!/bin/bash

# Function to compare version numbers
version_lt() {
    # Compare two version strings using sort -V (version sort)
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$2" ]
}

# Get Docker version
DOCKER_VERSION=$(docker version --format '{{.Server.Version}}')

# Check if Docker version is less than 27.0.0
if version_lt "$DOCKER_VERSION" "27.0.0"; then
    # Use docker-compose for versions below 27.0.0
    echo "Docker version $DOCKER_VERSION detected. Using docker-compose."
    docker-compose -f docker-compose_kieker.yml down
    docker-compose -f docker-compose_rabbitmq.yml down
else
    # Use docker compose for versions 27.0.0 and above
    echo "Docker version $DOCKER_VERSION detected. Using docker compose."
    docker compose -f docker-compose_kieker.yml down
    docker compose -f docker-compose_rabbitmq.yml down
fi

