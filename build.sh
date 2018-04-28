#!/bin/bash
set -x

# Installing dependencies
yum install -y git iptables make "Development Tools" yum-utils device-mapper-persistent-data lvm2 patch
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

yum install docker-ce -y

# Start docker in the background
/usr/bin/dockerd >/dev/null &

# Cloning main docker repo
git clone --depth=1 https://github.com/docker/docker.git
cd docker

# Just using VNDR didn't work for me
# So I'm doing the same thing manually

cd vendor/github.com/docker/libnetwork/
wget https://github.com/docker/libnetwork/pull/2103.patch
patch -b < 2103.patch 

# Building docker
# This may require up to 100G of free disk space
# And take up to 30 minutes to complete
make build
make binary

