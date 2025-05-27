#!/bin/bash

echo "Installing dependencies for Podman v5, using root/sudo"

sudo apt-get -y update && sudo apt-get -y upgrade

# Lets try without:  iptables \
# Lets try without:  libselinux1-dev \

# Go is needed:      golang-go \

# go-md2man is needed: Doesn't have dependencies, so use Ubuntu Package version
sudo apt-get -y install go-md2man
    
# If not build here: netavark \
# If not build here: passt \
# If not build here: runc \

sudo apt-get -y install \
    btrfs-progs \
    build-essential \
    curl \
    gcc \
    git \
    libassuan-dev \
    libbtrfs-dev \
    libc6-dev \
    libdevmapper-dev \
    libglib2.0-dev \
    libgpg-error-dev \
    libgpgme-dev \
    libprotobuf-c-dev \
    libprotobuf-dev \
    libseccomp-dev \
    libsystemd-dev \
    make \
    pkg-config \
    python3 \
    python3-pip \
    seccomp \
    uidmap \
    wget \
    expect
    
exit 0

# Reference:
# https://podman.io/docs/installation#building-from-source

