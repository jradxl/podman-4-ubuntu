#!/bin/bash

echo "I use RYE to manage my Python environment. If not RYE is not installed I try PIPX to install LASTVERSION"

if [[ $(rye version) ]]; then
   echo "Found RYE, so upgrading RYE and installing LASTVERSION..."
   rye self update
   #rye uninstall lastversion
   #Forcing to ensure latest version of LASTVERSION
   rye install --force lastversion
   lastversion --version
else
  echo "RYE not installed. Installing PIPX as root"
  sudo apt update && sudo apt upgrade && sudo apt install pipx
  pipx ensurepath
  pipx install lastversion
  $HOME/.local/bin/lastversion --version
  echo "You will need to logout/in to update PATH"
  echo "This install script will then continue"
  exit 0
fi

#Check for a few to see if install script should run.
pkgs='wget curl git libsystemd-dev'
install=false
for pkg in $pkgs; do
  status="$(dpkg-query -W --showformat='${db:Status-Status}' "$pkg" 2>&1)"
  #echo "$status"
  if [[ ! $? == 0 ]] || [[ ! "$status" == installed ]]; then
    install=true
    break
  fi
done
if "$install"; then
 ./install-deps-as-root.sh
fi

if command -v lastversion > /dev/null 2>&1 ; then
    lastversion --version
else
    echo "Please run the script, install-deps-as-root.sh first..."
    exit 1
fi

if command -v go > /dev/null 2>&1 ; then
    echo "Good! Golang is installed: $(go version)"
else
    echo "Please install GOLANG first..."
    exit 1
fi

if ! [[ ":$PATH:" == *":$HOME/podman/bin:"* ]]; then
  echo "You must add $HOME/podman/bin to the head of your PATH before I will continue this install."
  #export PATH=$HOME/podman/bin:$PATH
  exit 1
fi

mkdir -p "$HOME/podman/bin"
cwd=$(pwd)

#***For testing, uncomment if needed.
#rm -rf "$HOME/podman"
#rm -rf catatonit*
#rm -rf conmon*
#rm -rf crun*
#rm -rf fuse-overlay*
#rm -rf runc*
#rm -rf slirp4netns*
#***End testing

mkdir -p "$HOME/podman/cni/bin"


#=== Start Checks and Installtion Processing.... ===###

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

##
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
if [[ ${current_runc} == "${latest_runc}" ]]; then
	echo "RUNC is the latest version"
else
	echo "Installing/Upgrading RUNC..."
	wget https://github.com/opencontainers/runc/releases/download/v"${latest_runc}"/runc.amd64
        #--auth-no-challenge --user=$userid --password=$userkey
	chmod +x runc.amd64
    mv runc.amd64 "$HOME/podman/bin/runc"
fi

latest_crun=$(lastversion https://github.com/containers/crun)
echo "Latest crun is: ${latest_crun}"
if command -v crun > /dev/null 2>&1 ; then
    current_crun=$(crun --version | grep "crun version" )
    current_crun=${current_crun: 13}
    echo "Current crun is: ${current_crun}"
else
    echo "crun not installed"
    current_crun=""
fi
if [[ ${current_crun} == "${latest_crun}" ]]; then
	echo "CRUN is the latest version"
else
	echo "Installing/Upgrading CRUN..."
	wget https://github.com/containers/crun/releases/download/"${latest_crun}"/crun-"${latest_crun}"-linux-amd64
	chmod +x crun-"${latest_crun}"-linux-amd64
    mv crun-"${latest_crun}"-linux-amd64 "$HOME/podman/bin/crun"
fi

##NOTE: The version string here is puzzling and might be a bug. Thus this fudge may break
latest_catatonit=$(lastversion https://github.com/openSUSE/catatonit)_catatonit
echo "Latest catatonit is: ${latest_catatonit}"
if command -v catatonit > /dev/null 2>&1 ; then
    current_catatonit=$(catatonit -V )
    current_catatonit=${current_catatonit: 13}
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

##NOTE: The version string here is puzzling and might be a bug. Thus this fudge may break
latest_fuseoverlayfs=$(lastversion https://github.com/containers/fuse-overlayfs)-dev
echo "Latest fuseoverlayfs is: ${latest_fuseoverlayfs}"
if command -v fuse-overlayfs > /dev/null 2>&1 ; then
    current_fuseoverlayfs=$(fuse-overlayfs --version | grep fuse-overlayfs)
    current_fuseoverlayfs=${current_fuseoverlayfs: 24}
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

latest_conmon=$(lastversion https://github.com/containers/conmon)
echo "Latest CONMON is: ${latest_conmon}"
if command -v conmon > /dev/null 2>&1 ; then
    current_conmon=$(conmon --version | grep conmon)
    current_conmon=${current_conmon: 15}
    echo "Current CONMON is: ${current_conmon}"
else
    echo "CONMON not installed"  
    current_conmon=""
fi
if [[ ${current_conmon} == "${latest_conmon}" ]]; then
    echo "CONMON is the latest version"
else
    echo "Installing/Upgrading CONMON..."
    wget https://github.com/containers/conmon/releases/download/v"${latest_conmon}"/conmon.amd64
         #--auth-no-challenge --user=$userid --password=$userkey 
    chmod +x conmon.amd64
    mv conmon.amd64 "$HOME/podman/bin/conmon"
fi

latest_podman=$(lastversion https://github.com/containers/podman)
echo "Latest PODMAN is: ${latest_podman}"
if command -v podman > /dev/null 2>&1 ; then
    current_podman=$(podman --version | grep podman)
    current_podman=${current_podman: 15}
    echo "Current PODMAN is: ${current_podman}"
else
    echo "PODMAN not installed"
    current_podman=""
fi
if [[ ${current_podman} == "${latest_podman}" ]]; then
    echo "PODMAN is the latest version"
else
    echo "Installing/Upgrading PODMAN..."
    rm -rf "$HOME/podman/builds/podman"
    git clone -b v"${latest_podman}" --depth 1 https://github.com/containers/podman.git "$HOME/podman/builds/podman"    
    cd "$HOME/podman/builds/podman" || exit 1
    make BUILDTAGS="systemd seccomp"
    make install PREFIX="$HOME/podman"
    #Not included in make install, and no versioning. Copy always!
    if [[ -f "$HOME/podman/builds/podman/bin/rootlessport" ]]; then
        cp "$HOME/podman/builds/podman/bin/rootlessport" "$HOME/podman/bin"
    fi
    cd "$cwd" || exit 1
fi

if [[ -f ./copy-files.sh ]]; then
    ./copy-files.sh
fi

exit 0
