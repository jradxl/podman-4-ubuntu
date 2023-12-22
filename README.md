# Podman 4 Ubuntu

## Scripts to install latest version of Podman v4 on Ubuntu Jammy or Mantic

The installation of Podman v4 on Ubuntu is awkward...

This script installs already build binaries of helper programs if available and builds PODMAN from source.\
Only for AMD64

On Ubuntu Jammy the version in the archive is v3, on Lunar and Mantic it is 4.3\
At time of updating the project PODMON is 4.8

Only Podman ROOTLESS is supported here.\
I can't get PODMAN to work as root using the install from this script.\
To avoid confusions, ensure PODMAN and all helper binaries are remove from root, i.e `apt purge` etc

###  NOTES
* `storage.conf` does not appear to be necessary, as `podman system reset` offers to remove it.


### PING inside a container
on the host\
`apt install iputils-ping`\
`net.ipv4.ping_group_range = 0 2147483647 >> /etc/sysctl.conf`

within an Ubuntu container\
`setcap cap_net_raw+p /usr/bin/ping`

### KUBIC alternative
We are told that the Kubic repositories are no longer supported\
[https://podman.io/blogs/2022/04/05/ubuntu-2204-lts-kubic.html](kubic)

but debs are available using this apt's sources podman.list\
`deb [arch=amd64] http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/unstable/xUbuntu_22.04/ /`\
apt's KEY\
`curl -fsSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/xUbuntu_22.04/Release.key | gpg --dearmor > /etc/apt/trusted.gpg.d/podmon.gpg`

### TESTING
Create a new user on your machine...\
`adduser podman1`
`adduser podman1 sudo`

Then SSH to this account...\
`ssh podman1@localhost` \
and clone this repository and run script.


December 2023
