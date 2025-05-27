# Podman For Ubuntu

## Scripts to install latest version of Podman v5 on Ubuntu

The installation of Podman v5 on Ubuntu is simple once you've tried it!!  

This script installs already built binaries of some helper programs if available and builds PODMAN from source.  
PASST is built from its source from https://passt.top  As this git repository is not github like I cannot use lastversion to detect an update, so it is built on every run of the script.  
Also CONMON has to be built to get the systemd and journald support.  


Only for AMD64

On Ubuntu Jammy the version in the package archive is v3, on Lunar and Mantic it is 4.3 and on Ubuntu Noble it is 4.9.3  
At time of updating this project, PODMON is 5.5.0  

Both podman ROOTFULL and ROOTLESS are supported.
I have found it's better to install all binaries and config files as SUDO/ROOT.  

To avoid confusions, ensure PODMAN and all helper binaries from Ubuntu Packages are remove from root, i.e `apt purge` etc..  

`get-ref-config-files.sh`  
** Obtains what I believe are the refernces copies of the config files and stores them in directory `ref-config-files`  
** These files change between versions. Ensure the config files in the root of this project are updated and deployed.
** There are no config files in /usr/share/containers, or ${XDG_CONFIG_HOME/containers} unless the user adds them, so the files copied to /etc/containers are in use.

`set-subuids.py`  
** Man page for SUBUID(5) does allow for a syntax of UID:SUBID:Count, which is generated for users above UID=1000. This is a bit of fix and forget approach.

`copy-files.sh`  
** Allows copying of binaries and config files to appropiate places if needed.

###  NOTES
Both `$ podman system reset` and `# podman system reset` show directories in operation for storage.


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
`adduser podman1`\
`adduser podman1 sudo`

Then SSH to this account...\
`ssh podman1@localhost` \
and clone this repository and run script.


May 2025
