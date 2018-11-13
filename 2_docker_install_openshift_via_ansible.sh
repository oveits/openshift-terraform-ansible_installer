#!/usr/bin/env bash
#
# Creating and running a Docker Image with IMAGESCRIPT saved in image and RUNSCRIPT executed every time
# the container is mapping the working directory to /app
#

PULL=true
BASEIMAGE=centos:7
CONTAINERNAME=centos_ansible
IMAGENAME="oveits/centos_ansible"
TAG="latest"
PUSH=true
## latest versions:
#IMAGESCRIPT="yum install -y epel-release; yum -y update; yum install -y bash; yum install -y wget; yum install -y openssh-clients; yum install -y ansible; yum install -y pyOpenSSL; yum install -y python-cryptography; yum install -y python-boto; yum install -y git; yum install -y jq"

## if latest versions do not work, try  ansible 2.6.r54 (installed via RPM and disable updates):
IMAGESCRIPT="yum install -y epel-release; yum -y update; yum install -y bash; yum install -y wget; yum install -y openssh-clients; yum remove -y ansible; curl -O http://cbs.centos.org/kojifiles/packages/ansible/2.6.5/1.el7/noarch/ansible-2.6.5-1.el7.noarch.rpm && yum -y --enablerepo=epel install ansible-2.6.5-1.el7.noarch.rpm && cat /etc/yum.conf | grep -v -q 'exclude=ansible' && echo 'exclude=ansible' >> /etc/yum.conf; yum install -y pyOpenSSL; yum install -y python-cryptography; yum install -y python-boto; yum install -y python-lxml-3.2.1-4.el7.x86_64; yum install -y java-1.8.0-openjdk-headless; yum install -y patch; yum install -y httpd-tools; yum install -y git; yum install -y python-passlib-1.6.5-2.el7.noarch"
## if latest versions do not work, try  ansible 2.6.4:
#IMAGESCRIPT="yum install -y epel-release; yum -y update; yum install -y bash; yum install -y wget; yum install -y openssh-clients; yum install -y ansible-2.6.4-1.el7.noarch; yum install -y pyOpenSSL; yum install -y python-cryptography; yum install -y python-boto; yum install -y python-lxml-3.2.1-4.el7.x86_64; yum install -y java-1.8.0-openjdk-headless; yum install -y patch; yum install -y httpd-tools; yum install -y git"

RUNSCRIPT="bash 2_install_openshift_via_ansible.sh $@"

CURDIR=${PWD##*/}

cd `dirname $0`/..
DIR=`pwd`

# Create Docker image, if it does not exist
FOUND_IMAGE=`docker images | grep ${IMAGENAME} | grep $TAG`
# if not found locally, try to pull it from the Docker Repo:
[ $? != 0 ] && [ "$PULL" == true ] && docker pull ${IMAGENAME}:$TAG && FOUND_IMAGE=`docker images | grep ${IMAGENAME} | grep $TAG`

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

# for interactive tests:
#docker run -it --rm --name ${CONTAINERNAME} --entrypoint="bash" -v `pwd`:/app ${IMAGENAME} -c "cd /app/${CURDIR}; echo \"Try running ${RUNSCRIPT}\"; bash"


