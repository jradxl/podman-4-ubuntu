#!/bin/bash

echo "Installing dependencies for Podman v4, using root"

sudo apt update && sudo apt upgrade

sudo apt-get install \
  btrfs-progs \
  git \
  iptables \
  libassuan-dev \
  libbtrfs-dev \
  libc6-dev \
  libdevmapper-dev \
  libglib2.0-dev \
  libgpgme-dev \
  libgpg-error-dev \
  libprotobuf-dev \
  libprotobuf-c-dev \
  libseccomp-dev \
  seccomp \
  libselinux1-dev \
  libsystemd-dev \
  pkg-config \
  uidmap \
  python3 \
  python3-pip \
  wget \
  curl

exit 0
