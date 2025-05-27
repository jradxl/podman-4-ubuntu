#!/bin/bash

echo "Copying config files to /etc/containers..."
echo "Will require SUDO password."

containers_dir="/etc/containers"
sudo mkdir -p $containers_dir

helper_binaries_source="$HOME/podman/bin"
helper_binaries_destination="/usr/local/libexec/podman"

copy-config-files() {
    sudo mkdir -p "$containers_dir/registries.conf.d"
    sudo cp containers.conf "$containers_dir"
    sudo cp registries.conf "$containers_dir"
    sudo cp storage.conf "$containers_dir"
    sudo cp policy.json "$containers_dir"
    sudo cp seccomp.json "$containers_dir"
    sudo cp shortnames.conf "$containers_dir/registries.conf.d"
    echo "Copying finished."  
}

copy-helper-binaries() {
    sudo cp  /usr/local/bin/conmon              "$helper_binaries_destination"
    sudo cp "$helper_binaries_source"/crun      "/usr/local/bin"

    sudo cp "$helper_binaries_source"/netavark  "$helper_binaries_destination"
    sudo cp "$helper_binaries_source"/runc      "$helper_binaries_destination"
}

if [[ "$1" == "override" ]]; then
    echo "Override. Copying config files"
    copy-config-files
    exit 0
fi

if [[ -d $containers_dir ]]; then
    echo "$containers_dir already exists. Not copying files."
    echo "Use 'copy_files override' to force."
else
    echo "Copying files to $containers_dir..."
    copy-config-files
fi

echo "Copying Helper Binaries to $helper_binaries_destination"
copy-helper-binaries

exit 0
