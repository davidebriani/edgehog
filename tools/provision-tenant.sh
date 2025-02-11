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

if ! command_exists git; then
    echo "Error: git is not installed. Please install git before proceeding."
    exit 1
fi

git_version=$(git -v | awk '{print $3}' | sed 's/,//')
if verlt $git_version "2"; then
    echo "Error: git version 2 or later is required. Found $git_version."
    exit 1
fi

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

if ! command_exists astartectl; then
    echo "Error: astartectl is not installed. Please install it before proceeding."
    exit 1
fi

astartectl_version=$(astartectl version | awk '{print $2}' | sed 's/,//')
if verlt $astartectl_version "22.11"; then
    echo "Error: astartectl version 22.11 or later is required. Found $astartectl_version."
    exit 1
fi

echo "All prerequisites met."

aio_max_nr=$(cat /proc/sys/fs/aio-max-nr)
if [[ "$aio_max_nr" -lt 1048576 ]]; then
    echo "Updating aio-max-nr..."
    echo "fs.aio-max-nr = 1048576" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
fi

echo "Initializing Astarte..."

if [ ! -d astarte ]; then
    git clone --depth=1 https://github.com/astarte-platform/astarte.git -b v1.2.0
    ( cd astarte && echo '*' > .gitignore )
    ( cd astarte && docker run -v $(pwd)/compose:/compose astarte/docker-compose-initializer:1.2.0 )
fi
( cd astarte && docker compose pull )
( cd astarte && docker compose down -v )
( cd astarte && docker compose up -d )

echo "Waiting for Astarte services to be ready..."

while true; do
    a_aea_status=$(curl -s -o /dev/null -w "%{http_code}" http://api.astarte.localhost/appengine/health)
    a_rma_status=$(curl -s -o /dev/null -w "%{http_code}" http://api.astarte.localhost/realmmanagement/health)
    a_pa_status=$(curl -s -o /dev/null -w "%{http_code}" http://api.astarte.localhost/pairing/health)
    a_ha_status=$(curl -s -o /dev/null -w "%{http_code}" http://api.astarte.localhost/housekeeping/health)

    if [[ $a_aea_status == "200" && $a_rma_status == "200" && $a_pa_status == "200" && $a_ha_status == "200" ]]; then
        echo "Astarte services are ready."
        break
    fi

    echo "Waiting for Astarte services to be ready..."
    sleep 3
done

echo "Creating Astarte realm..."

astartectl housekeeping realms create test --astarte-url http://api.astarte.localhost --realm-public-key backend/priv/repo/seeds/keys/realm_public.pem -k astarte/compose/astarte-keys/housekeeping_private.pem -y

echo "Initializing Edgehog..."

docker compose down -v
docker compose up -d --build

while true; do
    e_ara_status=$(curl -s -o /dev/null -w "%{http_code}" http://api.edgehog.localhost/admin-api/v1/swagger)

    if [[ $e_ara_status == "200" ]]; then
        echo "Edgehog services are ready."
        break
    fi

    echo "Waiting for Edgehog services to be ready..."
    sleep 3
done

admin_jwt=$(cat backend/priv/repo/seeds/keys/admin_jwt.txt)

curl -s -X POST "http://api.edgehog.localhost/admin-api/v1/tenants" \
     -H "Content-Type: application/vnd.api+json" \
     -H "Accept: application/vnd.api+json" \
     -H "Authorization: Bearer $admin_jwt" \
     -d '{
       "data": {
         "type": "tenant",
         "attributes": {
           "name": "Test",
           "slug": "test",
           "default_locale": "en-US",
           "public_key": "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEhV0KI4hByk0uDkCg4yZImMTiAtz2\nazmpbh0sLAKOESdlRYOFw90Up4F9fRRV5Li6Pn5XZiMCZhVkS/PoUbIKpA==\n-----END PUBLIC KEY-----",
           "astarte_config": {
             "base_api_url": "http://api.astarte.localhost",
             "realm_name": "test",
             "realm_private_key": "-----BEGIN EC PRIVATE KEY-----\nMHcCAQEEIKsJwOKgTwhzWG3tnldd71K4hef5EfjvcNroSqQDY1+5oAoGCCqGSM49\nAwEHoUQDQgAEAdBOfYfLD2ukDqgSIQyzRsLc1xEa8/ujpZFaU1/s9F/cKmvJmnOJ\nBDfpPin7DXqOng+2JsinHuhLEdP/i0InLw==\n-----END EC PRIVATE KEY-----"
           }
         }
       }
     }'

astarte_realm_jwt=$(cat backend/priv/repo/seeds/keys/realm_jwt.txt)
edgehog_tenant_jwt=$(cat backend/priv/repo/seeds/keys/tenant_jwt.txt)

python3 -m webbrowser "http://dashboard.astarte.localhost/auth?realm=test#access_token=$astarte_realm_jwt"
python3 -m webbrowser "http://edgehog.localhost/login?tenantSlug=test&authToken=$edgehog_tenant_jwt"

echo "The Edgehog cluster has been provisioned and the tenant is ready."

# Restore the directory from which the script was called as the working directory
popd >/dev/null
