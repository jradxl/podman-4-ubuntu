#!/bin/bash

## USAGE:
## ./install-podman5.sh [podman | conmon]
##

#Check for a few to see if install script should run.
pkgs='wget curl git libsystemd-dev'
install=false
for pkg in $pkgs; do
  status="$(dpkg-query -W --showformat='${db:Status-Status}' "$pkg" 2>&1)"
  #echo "$status"
  if [[ ! "$?" == 0 ]] || [[ ! "$status" == installed ]]; then
    install=true
    break
  fi
done
if "$install"; then
    echo "Missing some dependancies..."
    exit 1
fi

if [[ "$(command -v lastversion)" ]]; then
    echo "Good: Lastversion is installed: $(lastversion --version)"
else
    echo "Please run the script, install-deps-as-root.sh first..."
    exit 1
fi

if [[ "$(command -v go)"  ]]; then
    echo "Good! Golang is installed: $(go version)"
else
    echo "Please install GOLANG first..."
    exit 1
fi

if [[ ":$PATH:" == *":$HOME/podman/bin:"* ]]; then
  echo "You must NOT have $HOME/podman/bin on your PATH."
  echo "I've found that PODMAN and all helper-binaries are better installed as SUDO/ROOT"
  echo "$HOME/podman is just a staging and build directory"
  echo "Please remove and then rerun this script"
  exit 1
fi

current_kernel=$(uname -a | awk '{print $3}')
#echo "Current Kernel: $current_kernel"

namespace_configured=$(grep CONFIG_USER_NS /boot/config-"$current_kernel")
#echo "Namespace Config: $namespace_configured"

if [[ "CONFIG_USER_NS=y" == "$namespace_configured" ]]; then
    echo "Good: Kernel is configured for Namespaces."
else
    echo "Bad: Kernel is not configured for Namespaces."
    exit 1
fi 

userns_enabled=$(sysctl kernel.unprivileged_userns_clone)
if [[ "kernel.unprivileged_userns_clone = 1" == "$userns_enabled" ]]; then
    echo "Good: unprivileged_userns is enabled"
else
    echo "Bad: unprivileged_userns is not enabled"
    exit 1
fi

#***For testing, uncomment if needed.
#rm -rf "$HOME/podman"
#rm -rf "$HOME"/podman/catatonit
#rm -rf "$HOME"/podman/conmon
#rm -rf "$HOME"/podman/crun
#rm -rf "$HOME"/podman/fuse-overlayfs
#rm -rf "$HOME"/podman/runc
#rm -rf "$HOME"/podman/netavark
#rm -rf "$HOME"/podman/slirp4netns
#***End testing

## This is a staging location
## I have found it's better to install everything as a root user.
## 
mkdir -p "$HOME/podman/bin"
cwd=$(pwd)

#=== Start Checks and Installtion Processing.... ===###

echo ""
## PASST/PASTA ##
## Built from sources
## SEE: https://passt.top/passt/about
## NOTE: Do not use make pkgs  for .deb as it does not work
# git clone https://passt.top/passt
# cd passt
# make
# Ensure Deb package is not installed
# sudo apt-get purge passt
build-passt() {
    echo "Installing/Upgrading PASST/PASTA..."
    echo "NO version checks are possible, so always built."
    rm -rf "$HOME/podman/builds/passt"
    git clone https://passt.top/passt "$HOME/podman/builds/passt"    
    cd "$HOME/podman/builds/passt" || exit 1
    make
    echo "Installing to /usr/local so will need SUDO password."
    sudo make install
}

## PASST is not on github so does not have method to check versions
## Hence build always
#Needs sudo apt-get install expect
current_passt=$(unbuffer passt --version | grep passt)
echo "Current PASST/PASTA is: ${current_passt}"
echo "PASST/PASTA install location is: $(which passt)"
build-passt
cd "$cwd" || exit 1

echo ""
## FUSEOVERLAYFS ##
##NOTE: The version string here is puzzling and might be a bug. Thus this fudge may break
latest_fuseoverlayfs=$(lastversion https://github.com/containers/fuse-overlayfs)
echo "Latest fuseoverlayfs is: ${latest_fuseoverlayfs}"
if command -v fuse-overlayfs > /dev/null 2>&1 ; then
    current_fuseoverlayfs=$(fuse-overlayfs --version | grep fuse-overlayfs)
    current_fuseoverlayfs=${current_fuseoverlayfs: 24:4}
    echo "Current fuseoverlayfs is: ${current_fuseoverlayfs}"
else
    echo "fuse-overlayfs not installed"
    current_fuseoverlayfs=""
fi
if [[ ${current_fuseoverlayfs} == "${latest_fuseoverlayfs}" ]]; then
	echo "FUSEOVERLAYFS is the latest version"
else
	echo "Installing/Upgrading fuseoverlayfs..."
    wget https://github.com/containers/fuse-overlayfs/releases/download/v"${latest_fuseoverlayfs}"/fuse-overlayfs-x86_64
	chmod +x fuse-overlayfs-x86_64
    mv fuse-overlayfs-x86_64 "$HOME/podman/bin/fuse-overlayfs"
fi

echo ""
## SLIRP4NETNS
# sudo apt purge slirp4netns libslirp0
latest_slirp4netns=$(lastversion https://github.com/rootless-containers/slirp4netns)
echo "Latest slirp4netns is: ${latest_slirp4netns}"
if command -v slirp4netns > /dev/null 2>&1 ; then
    current_slirp4netns=$(slirp4netns -v | grep "slirp4netns version" )
    current_slirp4netns=${current_slirp4netns: 20}
    echo "Current slirp4netns is: ${current_slirp4netns}"
else
    echo "slirp4netns not installed"
    current_slirp4netns=""
fi

if [[ ${current_slirp4netns} == "${latest_slirp4netns}" ]]; then
	echo "slirp4netns is the latest version"
else
	echo "Installing/Upgrading slirp4netns..."
    rm -rf slirp4netns-x86_64
    if [[ $(wget https://github.com/rootless-containers/slirp4netns/releases/download/v"${latest_slirp4netns}"/slirp4netns-x86_64) ]]; then
        echo "wget fails. slirp4netns not found, or some other reason. Exiting."
        exit 1
    fi
    if [[ -f slirp4netns-x86_64 ]]; then
      echo "Sucessful get of slirp4netns-x86_64"
      chmod +x slirp4netns-x86_64
      mv slirp4netns-x86_64 "$HOME/podman/bin/slirp4netns"
      "$HOME/podman/bin/slirp4netns" -v
    else
      echo "Failed to get slirp4netns-x86_64"
      exit 1
    fi
fi

echo ""
## NETAVARK ##
latest_netavark=$(lastversion https://github.com/containers/netavark)
echo "Latest Netavark is: v$latest_netavark"

if command -v netavark > /dev/null 2>&1 ; then
    current_netavark="$(netavark -V)"
    current_netavark="${current_netavark: 9}"
    echo "Current Netavark is: v${current_netavark}"
else
    echo "Netavark not installed"
    current_netavark=""
fi
if [[ "${current_netavark}" == "${latest_netavark}" ]]; then
    echo "NETAVARK is the latest version"
else
    ### THIS IS A BINARY! https://github.com/containers/netavark/releases/download/v1.15.0/netavark.gz
    wget https://github.com/containers/netavark/releases/download/v"${latest_netavark}"/netavark.gz
    gunzip -f ./netavark.gz
    chmod +x ./netavark
    mv ./netavark "$HOME/podman/bin/"
fi

echo ""
## RUNC ##
## Written in Golang, slower than CRUN, and PODMAN uses CRUN as precedent over RUNC. ##
latest_runc=$(lastversion https://github.com/opencontainers/runc)
echo "Latest RUNC is: ${latest_runc}"
if command -v runc > /dev/null 2>&1 ; then
    current_runc=$(runc -v | grep "runc version" )
    current_runc=${current_runc: 13}
    echo "Current RUNC is: ${current_runc}"
else
    echo "RUNC not installed"
    current_runc=""
fi
if [[ "${current_runc}" == "${latest_runc}" ]]; then
	echo "RUNC is the latest version"
else
	echo "Installing/Upgrading RUNC..."
	wget https://github.com/opencontainers/runc/releases/download/v"${latest_runc}"/runc.amd64
        #--auth-no-challenge --user=$userid --password=$userkey
	chmod +x runc.amd64
    mv runc.amd64 "$HOME/podman/bin/runc"
fi

echo ""
## CRUN ##
## Written in C, faster than RUNC, and PODMAN uses CRUN as precedent over RUNC. ##
## NOTE: CRUN needs to be on path for podman to find    
latest_crun=$(lastversion https://github.com/containers/crun)
echo "Latest crun is: ${latest_crun}"
if command -v crun > /dev/null 2>&1 ; then
    current_crun="$(crun --version | grep "crun version")"
    current_crun="${current_crun: 13}"
    echo "Current crun is: ${current_crun}"
else
    echo "crun not installed"
    current_crun=""
fi
if [[ "${current_crun}" == "${latest_crun}" ]]; then
	echo "CRUN is the latest version"
else
	echo "Installing/Upgrading CRUN..."
	wget https://github.com/containers/crun/releases/download/"${latest_crun}"/crun-"${latest_crun}"-linux-amd64
	chmod +x crun-"${latest_crun}"-linux-amd64
    mv crun-"${latest_crun}"-linux-amd64 "$HOME/podman/bin/crun"
fi

echo ""
## CONMON ##
## Needs to be build from sources to enable systemd and journald support.
# git clone https://github.com/containers/conmon
# cd conmon
# export GOCACHE="$(mktemp -d)"
# make
build-conmon() {
    echo "Installing/Upgrading CONMON..."
    rm -rf "$HOME/podman/builds/conmon"
    git clone https://github.com/containers/conmon "$HOME/podman/builds/conmon"    
    cd "$HOME/podman/builds/conmon" || exit 1
    export GOCACHE="$(mktemp -d)"
    make
    #Except the /usr/local/ default and move later
    echo "Installing to /usr/local so will need SUDO password."
    sudo make install
}

latest_conmon=$(lastversion https://github.com/containers/conmon)
echo "Latest CONMON is: ${latest_conmon}"
if command -v conmon > /dev/null 2>&1 ; then
    current_conmon="$(conmon --version | grep conmon)"
    current_conmon="${current_conmon: 15}"
    echo "Current CONMON is: ${current_conmon}"
    echo "CONMON install location is: $(which conmon)"
else
    echo "CONMON not installed"  
    current_conmon=""
fi
if [[ "${current_conmon}" == "${latest_conmon}" ]]; then
    echo "CONMON is the latest version"
    if [[ "$1" == "conmon" ]]; then
        echo "Force build CONMON specified... "
        build-conmon
    fi    
else
    build-conmon
fi
cd "$cwd" || exit 1

echo ""
## PODMAN ##
## git clone https://github.com/containers/podman/
## cd podman
## make BUILDTAGS="selinux seccomp" PREFIX=/usr
## sudo env PATH=$PATH make install PREFIX=/usr

build_podman() {
     echo "Installing/Upgrading PODMAN..."
     rm -rf "$HOME/podman/builds/podman"
     git clone -b v"${latest_podman}" --depth 1 https://github.com/containers/podman.git "$HOME/podman/builds/podman"    
     cd "$HOME/podman/builds/podman" || exit 1
     
     make BUILDTAGS="systemd seccomp" PREFIX=/usr/local
     #OR THIS?
     #make BUILDTAGS="apparmor systemd seccomp"
     #LOCAL make install PREFIX="$HOME/podman"
 
     echo "Making PODMAN for /usr/local."
     echo "Install will ask for Sudo password..."
     sudo env PATH=$PATH make install PREFIX=/usr/local
     # NOTE: rootlessport and quadlet are installed 
     #       into /usr/local/libexec/podman/
}

latest_podman=$(lastversion https://github.com/containers/podman)
echo "Latest PODMAN is: ${latest_podman}"
if command -v podman > /dev/null 2>&1 ; then
    current_podman=$(podman --version | grep podman)
    current_podman=${current_podman: 15}
    echo "Current PODMAN is: ${current_podman}"
    echo "PODMAN install location is: $(which podman)"
else
    echo "PODMAN not installed"
    current_podman=""
fi
if [[ "${current_podman}" == "${latest_podman}" ]]; then
    echo "PODMAN is the latest version"
    if [[ "$1" == "podman" ]]; then
        echo "Force build PODMAN specified... "
        build_podman 
    fi
else
    build_podman
fi
cd "$cwd" || exit 1

##DEPLOY##
# Some are used from PATH, hence /usr/local/bin whereas
# some are used from /usr/local/libexec/podman
# It's easier to copy all to both locations!
echo ""
echo "Deploying binaries... Will overwrite all..."
for f in "$HOME"/podman/bin/* ; do  sudo cp "$f" /usr/local/bin ; done
for f in "$HOME"/podman/bin/* ; do  sudo cp "$f" /usr/local/libexec/podman ; done
    
echo "Deploying files... Will NOT overwrite if already present."
echo ""
containers_dir="/etc/containers"
copy-config-files() {
    sudo mkdir -p $containers_dir
    sudo mkdir -p "$containers_dir/registries.conf.d"
    sudo cp shortnames.conf "$containers_dir/registries.conf.d"
    sudo cp containers.conf "$containers_dir"
    sudo cp registries.conf "$containers_dir"
    sudo cp storage.conf "$containers_dir"
    sudo cp policy.json "$containers_dir"
    sudo cp seccomp.json "$containers_dir"
    echo "Copying finished."  
}
if [[ -d $containers_dir ]]; then
    echo "$containers_dir already exists. Not copying config files."
else
    echo "$containers_dir created. Copying config files."
    copy-config-files
fi

echo ""
echo "## ===== SUMMARY ===== ##"
echo "NETAVARK version installed: $(netavark --version)"
echo "RUNC version installed: $(runc --version | grep "runc version")"
echo "CRUN version installed: $(crun --version | grep "crun version")"
echo "CONMON installed: $(conmon --version | grep "conmon version")"
echo "FUSE_OVERLAYFS installed: $(fuse-overlayfs --version | grep overlayfs)"
echo "PASST/PASTA installed: $(unbuffer passt --version | grep passt)"
echo "SLIRP4NETNS installed: $(slirp4netns --version | grep slirp4netns)"

echo ""
echo "Finished."
exit 0




#### =============================================== ####
## NOTE: With recent PODMAN v5 I've not found need for these
## Left here for the moment...

latest_cni=$(lastversion https://github.com/containernetworking/plugins)
echo "Latest CNI Plugins: ${latest_cni}"
if command -v "$HOME/podman/cni/bin/bridge" > /dev/null 2>&1 ; then
    #Using BRIDGE as test example as all appear to have same version string
    current_cni=$("$HOME/podman/cni/bin/bridge" 2>&1)
    current_cni=${current_cni: 19:5}
    echo "Current CNI Plugins are: ${current_cni}"
else
    echo "CNI Plugins are not installed"
    current_cni=""
fi

if [[ ${current_cni} == "${latest_cni}" ]]; then
    echo "CNI Plugins are the latest versions" 
else
    echo "Installing/Upgrading the CNI plugins..."
    wget https://github.com/containernetworking/plugins/releases/download/v"${latest_cni}"/cni-plugins-linux-amd64-v"${latest_cni}".tgz
    tar xf cni-plugins-linux-amd64-v"${latest_cni}".tgz -C "$HOME/podman/cni/bin"
    rm cni-plugins-linux-amd64-v"${latest_cni}".tgz
fi

latest_dnsname=$(lastversion https://github.com/containers/dnsname)
echo "Latest dnsname is: ${latest_dnsname}"
if command -v $HOME/podman/cni/bin/dnsname > /dev/null 2>&1 ; then
    current_dnsname=$("$HOME/podman/cni/bin/dnsname" -v 2>&1 | grep version)
    current_dnsname=${current_dnsname: 9:5}
    echo "Current dnsname is: ${current_dnsname}"
else
    echo "Plugin dnsname is not installed"
    current_dnsname=""
fi

if [[ ${current_dnsname} == "${latest_dnsname}" ]]; then
	echo "dnsname is the latest version"
else
	echo "Installing/Upgrading dnsname..."
	rm -rf "$HOME/podman/builds/dnsname"
    git clone -b v"${latest_dnsname}" --depth 1 https://github.com/containers/dnsname.git "$HOME/podman/builds/dnsname"
    ret=$?
    if [[ "$ret" == 0 ]]; then
      echo "Success, continuing to build dnsname..."
    else
      echo "Failed to git clone dnsname. Exiting..."
      exit 1
    fi

    cd "$HOME/podman/builds/dnsname" || exit 1
    make
    mv "$HOME/podman/builds/dnsname/bin/dnsname" "$HOME/podman/cni/bin"
    cd "$cwd" || exit 1
    pwd
    if [[ -f "$HOME/podman/cni/bin/dnsname" ]]; then
      echo "dnsname build success."
      "$HOME/podman/cni/bin/dnsname"
    else
      echo "dnsname build failed"
      exit 1
    fi    
fi

##NOTE: The version string here is puzzling and might be a bug. Thus this fudge may break
latest_catatonit=$(lastversion https://github.com/openSUSE/catatonit)
echo "Latest catatonit is: ${latest_catatonit}"
if command -v catatonit > /dev/null 2>&1 ; then
    current_catatonit=$(catatonit -V )
    current_catatonit=${current_catatonit: 13:5}
    echo "Current catatonit is: ${current_catatonit}"
else
    echo "catatonit not installed"
    current_catatonit=""
fi
if [[ ${current_catatonit} == "${latest_catatonit}" ]]; then
	echo "CATATONIT is the latest version"
else
	echo "Installing/Upgrading CATATONIT..."
	wget https://github.com/openSUSE/catatonit/releases/download/v"${latest_catatonit}"/catatonit.x86_64
         #--auth-no-challenge --user=$userid --password=$userkey  
	chmod +x catatonit.x86_64
    mv catatonit.x86_64 "$HOME/podman/bin/catatonit"
fi

## END
## May 2025
