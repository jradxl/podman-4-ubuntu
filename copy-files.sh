#!/bin/bash

containers_dir="$HOME/.config/containers"

if [[ -d $containers_dir ]]; then
    echo "$containers_dir exists. Not copying files."
else
    echo "$containers_dir does not exists. Copying files..."
    mkdir -p "$containers_dir/registries.conf.d"
    cp containers.conf "$containers_dir"
    cp registries.conf "$containers_dir"
    cp storage.conf "$containers_dir"
    cp policy.json "$containers_dir"
    cp seccomp.json "$containers_dir"
    cp shortnames.conf "$containers_dir/registries.conf.d"
    echo "Copying finished."
fi

exit 0

