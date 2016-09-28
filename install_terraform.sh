#!/usr/bin/env bash
# install terraform
# see also https://hub.docker.com/r/hashicorp/terraform/~/dockerfile/

TERRAFORM_VERSION=0.7.4
TERRAFORM_SHA256SUM=8950ab77430d0ec04dc315f0d2d0433421221357b112d44aa33ed53cbf5838f6

which sudo && SUDO=sudo
which curl && CURLWASINSTALLED=true

which apt-get && $SUDO apt-get update && \
                 $SUDO apt-get install -y curl

which apk && apk add --update curl

curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
#sha256sum --check --status terraform_${TERRAFORM_VERSION}_SHA256SUMS && \  
# I could not find any file like terraform_${TERRAFORM_VERSION}_SHA256SUMS on the git repository https://github.com/hashicorp/docker-hub-images
# replaced by:
echo "$TERRAFORM_SHA256SUM  terraform_${TERRAFORM_VERSION}_linux_amd64.zip" | sha256sum --check --status && \
$SUDO unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin && \
rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip 

#[ "$CURLWASINSTALLED" != "true" ] && which apt-get && $SUDO apt-get remove -y curl
#[ "$CURLWASINSTALLED" != "true" ] && which apk && apk del curl 

