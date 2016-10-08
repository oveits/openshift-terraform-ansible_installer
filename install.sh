#!/usr/bin/env bash

if [ ! -d /mnt/nfs/openshift-terraform-ansible_installer ]; then
   [ -d /mnt/nfs ] || sudo mkdir /mnt/nfs
   sudo mount -t nfs -o 'vers=3,nolock,udp' LAPTOP-P5GHOHB7:/D/NFS /mnt/nfs
fi 

#docker rm centos 2>/dev/null
docker rm centos-terraform 2>/dev/null

cd `dirname $0`/..
DIR=`pwd`
#docker run -it --rm --name centos -v `pwd`:/nfs centos bash -c '/nfs/openshift-terraform-ansible_installer/install_wizard.sh'
docker run -it --rm --name centos-terraform -v `pwd`:/nfs oveits/centos-terraform bash -c '/nfs/openshift-terraform-ansible_installer/install_wizard.sh'
