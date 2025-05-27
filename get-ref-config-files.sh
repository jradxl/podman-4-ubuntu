#!/bin/bash

location="ref-config-files"

mkdir -p   ./"$location"
curl -L -o ./"$location"/registries.conf   https://raw.githubusercontent.com/containers/image/main/registries.conf
curl -L -o ./"$location"/policy.json       https://raw.githubusercontent.com/containers/image/main/default-policy.json
curl -L -o ./"$location"/containers.conf   https://raw.githubusercontent.com/containers/common/main/pkg/config/containers.conf
curl -L -o ./"$location"/seccomp.json      https://raw.githubusercontent.com/containers/common/main/pkg/seccomp/seccomp.json
curl -L -o ./"$location"/storage.conf      https://raw.githubusercontent.com/containers/storage/main/storage.conf
curl -L -o ./"$location"/shortnames.conf   https://raw.githubusercontent.com/containers/shortnames/main/shortnames.conf
