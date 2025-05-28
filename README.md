# Podman For Ubuntu

## Scripts to install latest version of Podman v5 on Ubuntu

The installation of Podman v5 on Ubuntu is simple once you've tried it!!  

This script installs already built binaries of some helper programs if available and builds PODMAN from source.  
PASST is built from its source from https://passt.top  As this git repository is not github like I cannot use lastversion to detect an update, so it is built on every run of the script.  
Also CONMON has to be built to get the systemd and journald support.  


Only for AMD64

On Ubuntu Jammy the version in the package archive is v3, on Lunar and Mantic it is 4.3 and on Ubuntu Noble it is 4.9.3  
At time of updating this project, PODMON is 5.5.0  

Both podman ROOTFUL and ROOTLESS are supported.
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


### Podman API
In spite of podman not having a running daemon it is still possible to interact with an API.
If the `podman.sock` is poked, it triggers `podman.service` which runs the podman executable to respond.
The `podman-4-ubuntu.sh`script uses podman's `make install PREFIX=/usr/local` so that the socket and service unit files are installed in `/usr/local/lib/systemd/system`. This location satisfies both root and user requirements.  
** Ensure no podman unit files are in `/etc/xdg/...`. I had some left over from a previous installation.  
** Enable the podman.socket  
`# systemctl enable podman.socket`  
`$ systemctl --user enable podman.socket`  
** `podman.service` does not need to be enabled.  
Use `podman info | grep APIVersion` to get the API version. Note that when using it needs a prefix of a `v`, so at time of writing I have `v5.5.0`.  
** Ensure that XDG_RUNTIME_DIR is correctly set with, `systemctl --user show-environment | sort` which gives `XDG_RUNTIME_DIR=/run/user/1000` for example.  
** For a User, poke the API with, `curl --unix-socket $XDG_RUNTIME_DIR/podman/podman.sock http://d/v5.5.0/libpod/info`.  
** For Root, poke the API with, `curl --unix-socket /run/podman/podman.sock http://d/v5.5.0/libpod/info`
** I found getting above working was very fussy. You might try `podman system reset` and many reboots to be sure all is working.  


May 2025
