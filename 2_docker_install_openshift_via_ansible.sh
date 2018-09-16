#!/usr/bin/env bash
#
# Creating and running a Docker Image with IMAGESCRIPT saved in image and RUNSCRIPT executed every time
# the container is mapping the working directory to /app
#

#BASEIMAGE=centos:6
BASEIMAGE=centos:7
CONTAINERNAME=centos_ansible
IMAGENAME="oveits/centos_ansible"
TAG="latest"
PUSH=true

# latest ansible:
#IMAGESCRIPT="yum install -y epel-release; yum -y update; yum install -y bash; yum install -y wget; yum install -y openssh-clients; yum install -y ansible; yum install -y pyOpenSSL; yum install -y python-cryptography; yum install -y python-boto; yum install -y git"

# ansible v2.3.2:
IMAGESCRIPT="yum install -y epel-release; yum -y update; yum install -y bash; yum install -y wget; yum install -y openssh-clients; echo yum install -y ansible-2.4.2.0-2.el7.noarch; yum install -y pyOpenSSL; yum install -y python-cryptography; yum install -y python-boto; yum install -y git; echo curl -O http://cbs.centos.org/kojifiles/packages/ansible/2.3.2.0/2.el7/noarch/ansible-2.3.2.0-2.el7.noarch.rpm && yum localinstall -y ansible-2.3.2.0-2.el7.noarch.rpm"

# ansible v.2.2 (requires python 2.6, which requires centos:6 base image): (DOES NOT WORK. USE oveits/centos_ansible:2016-11 instead!)
#IMAGESCRIPT="yum install -y epel-release; yum -y update; yum install -y bash; yum install -y wget; yum install -y openssh-clients; yum install -y pyOpenSSL; curl -O http://mirror.centos.org/centos/6/os/x86_64/Packages/python-2.6.6-66.el6_8.x86_64.rpm && yum localinstall -y python-2.6.6-66.el6_8.x86_64.rpm; yum install -y python-cryptography; yum install -y git; curl -O http://cbs.centos.org/kojifiles/packages/ansible/2.2.0.0/3.el6/noarch/ansible-2.2.0.0-3.el6.noarch.rpm && yum localinstall -y ansible-2.2.0.0-3.el6.noarch.rpm"
RUNSCRIPT="bash 2_install_openshift_via_ansible.sh"

CURDIR=${PWD##*/}

cd `dirname $0`/..
DIR=`pwd`

# Create Docker image, if it does not exist
FOUND_IMAGE=`docker images | grep ${IMAGENAME} | grep $TAG`
if [ "$FOUND_IMAGE" == "" ]; then
   echo "docker image ${IMAGENAME} not found. It will be created now. For removing, run 'docker rmi ${IMAGENAME}'."

   # remove container, if it exists:
   docker rm ${CONTAINERNAME} 2>/dev/null 1>/dev/null

   # create container:
   docker run -it --name ${CONTAINERNAME} --entrypoint="sh" -v `pwd`:/app ${BASEIMAGE} -c "cd /app/${CURDIR}; ${IMAGESCRIPT}"

   # save container as image:
   docker commit ${CONTAINERNAME} ${IMAGENAME}

   # save image to Docker hub:
   [ "$PUSH" == "true" ] && docker login && docker push ${IMAGENAME}:${TAG}

   # remove container:
   docker rm ${CONTAINERNAME} 2>/dev/null 1>/dev/null
fi

# remove container, if it exists:
docker rm ${CONTAINERNAME} 2>/dev/null 1>/dev/null

# start container from image:
docker run -it --rm --name ${CONTAINERNAME} --entrypoint="sh" -v `pwd`:/app ${IMAGENAME} -c "cd /app/${CURDIR}; ${RUNSCRIPT}"


