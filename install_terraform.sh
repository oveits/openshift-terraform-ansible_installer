#!/usr/bin/env bash
# install terraform
# see also https://hub.docker.com/r/hashicorp/terraform/~/dockerfile/

TERRAFORM_VERSION=0.7.4
TERRAFORM_SHA256SUM=8950ab77430d0ec04dc315f0d2d0433421221357b112d44aa33ed53cbf5838f6


# terraform already installed?
terraform --version 2>/dev/null 1>/dev/null | grep $TERRAFORM_VERSION 2>/dev/null 1>/dev/null && INSTALLED=true

if [ "$INSTALLED" == "true" ]; then
  echo "terraform version $TERRAFORM_VERSION is already installed!"
else
  echo "terraform will be installed!"
  
  if [ "$INSTALL" == "" ] && [ -r detect_installer.sh ]; then
    source detect_installer.sh || exit 1
  else
    # detect sudo:
    sudo echo test 2>/dev/null && SUDO=sudo
    
    # detect installer:
    INSTALL=
    $SUDO apt-get update 2>/dev/null && INSTALL="$SUDO apt-get install -y"
    [ "$INSTALL" == "" ] && $SUDO yum --version 2>/dev/null && INSTALL="$SUDO yum install -y"
    [ "$INSTALL" == "" ] && $SUDO apk update 2>/dev/null && INSTALL="$SUDO apk add" 2>/dev/null
    [ "$INSTALL" == "" ] && echo "No installer found! Exiting..." && exit 1
  fi
  
  curl --version 2>/dev/null 1>/dev/null || $INSTALL curl 
  unzip -hh 2>/dev/null 1>/dev/null || $INSTALL unzip
  which echo 2>/dev/null 1>/dev/null || $INSTALL which
  
  curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  echo "$TERRAFORM_SHA256SUM  terraform_${TERRAFORM_VERSION}_linux_amd64.zip" | sha256sum --check --status && \
  $SUDO unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin && \
  rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip 
  
  #[ "$CURLWASINSTALLED" != "true" ] && which apt-get && $SUDO apt-get remove -y curl
  #[ "$CURLWASINSTALLED" != "true" ] && which apk && apk del curl 
fi

terraform --version 
