#!/usr/bin/env bash
#
# Creating and running a Docker Image with IMAGESCRIPT saved in image and RUNSCRIPT executed every time
# the container is mapping the working directory to /app
#

BASEIMAGE="hashicorp/terraform:light"
CONTAINERNAME=terraform_bash_wget
IMAGENAME="oveits/terraform_bash_wget"
TAG="latest"
PUSH=true
IMAGESCRIPT="apk add --update bash && apk add --update wget && rm -rf /var/cache/apk/*"
RUNSCRIPT="bash 1_create_aws_resources.sh $@"

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


