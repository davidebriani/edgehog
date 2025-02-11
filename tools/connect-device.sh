#!/usr/bin/env bash

set -eEuo pipefail

# Put script directory on the directories stack, so the script is executed in its directory
pushd "$(dirname "$0")" >/dev/null

# Change the working directory to the project's root
cd ..

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

if ! command_exists git; then
    echo "Error: git is not installed. Please install git before proceeding."
    exit 1
fi

if ! command_exists cargo; then
    echo "Error: cargo is not installed. Please install Rust / cargo before proceeding."
    exit 1
fi

if ! command_exists cc; then
    echo "Error: cc is not installed. Please install the gcc / build-essential before proceeding."
    exit 1
fi

echo "Initializing Edgehog Device Runtime..."

if [ ! -d edgehog-device-runtime ]; then
    git clone --depth=1 https://github.com/edgehog-device-manager/edgehog-device-runtime.git -b main
    ( cd edgehog-device-runtime && git reset --hard c583372e3c7f73be62e0bb841230e30260d5d614 )
    ( cd edgehog-device-runtime && echo '*' > .gitignore )
fi

store_directory="/tmp/edgehog/edgehog-store/"
download_directory="/tmp/edgehog/edgehog-updates/"
rm -rf $store_directory
rm -rf $download_directory

echo "Registering a new device in Astarte..."

device_id="$(astartectl utils device-id generate-random)"
credentials_secret="$(astartectl pairing agent register --compact-output -r test -u http://api.astarte.localhost -k backend/priv/repo/seeds/keys/realm_private.pem -- "$device_id")"

echo "Writing Edgehog Device Runtime configuration..."

cat <<EOF > edgehog-device-runtime/edgehog-config.toml
astarte_library = "astarte-device-sdk"
interfaces_directory = "$(pwd)/backend/priv/astarte_resources/interfaces"
store_directory = "$store_directory"
download_directory = "$download_directory"
[astarte_device_sdk]
credentials_secret = "$credentials_secret"
device_id = "$device_id"
pairing_url = "http://api.astarte.localhost/pairing"
realm = "test"
ignore_ssl = true
[[telemetry_config]]
interface_name = "io.edgehog.devicemanager.SystemStatus"
enabled = true
period = 60
EOF

# TODO: run `ttyd -W bash` to support Edgehog's remote terminal functionality

echo "Starting Edgehog Device Runtime..."

(cd edgehog-device-runtime && RUST_LOG=debug cargo run --features "forwarder containers")

# Restore the directory from which the script was called as the working directory
popd >/dev/null
