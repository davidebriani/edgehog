#!/usr/bin/env bash

set -eEuo pipefail

# Put script directory on the directories stack, so the script is executed in its directory
pushd "$(dirname "$0")" >/dev/null

# Change the working directory to the project's root
cd ..

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

verlte() {
    [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

verlt() {
    [ "$1" = "$2" ] && return 1 || verlte $1 $2
}

if ! command_exists docker; then
    echo "Error: Docker is not installed. Please install Docker before proceeding."
    exit 1
fi

docker_version=$(docker -v | awk '{print $3}' | sed 's/,//')
if verlt $docker_version "19"; then
    echo "Error: Docker version 19 or later is required. Found $docker_version."
    exit 1
fi

docker_compose_version=$(docker compose version | awk '{print $4}' | sed 's/,//')
if verlt $docker_compose_version "2.21"; then
    echo "Error: Docker Compose version 2.21 or later is required. Found $docker_compose_version."
    exit 1
fi

echo "Deprovisioning Edgehog..."

docker compose down -v

if [ -d astarte ]; then
    echo "Deprovisioning Astarte..."
    (cd astarte && docker compose down -v)
fi

echo "The Edgehog cluster has been deprovisioned."

# Restore the directory from which the script was called as the working directory
popd >/dev/null
