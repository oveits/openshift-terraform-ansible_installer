#!/usr/bin/env bash
# install ansible
# see also https://hub.docker.com/r/williamyeh/ansible/~/dockerfile/

which sudo && SUDO=sudo

echo "===> Adding Ansible's prerequisites..."   && \
    $SUDO apt-get update -y            && \
    $SUDO DEBIAN_FRONTEND=noninteractive  \
        $SUDO apt-get install --no-install-recommends -y -q  \
                build-essential                        \
                python-pip python-dev python-yaml      \
                libxml2-dev libxslt1-dev zlib1g-dev    \
                git                                 && \
    $SUDO pip install --upgrade pyyaml jinja2 pycrypto    && \
    \
    \
    echo "===> Downloading Ansible's source tree..."            && \
    [ -d ansible ] && mv ansible ansible_`date +"%Y-%m-%d-%H-%M"` 
    [ -d ansible ] || \
    git clone git://github.com/ansible/ansible.git --recursive  && \
    \
    \
    echo "===> Compiling Ansible..."      && \
    cd ansible                            && \
    $SUDO bash -c 'source ./hacking/env-setup'  && \
    \
    \
    echo "===> Moving useful Ansible stuff to /opt/ansible ..."  && \
    cd .. && \
    $SUDO mkdir -p /opt/ansible                && \
    $SUDO mv ansible/bin   /opt/ansible/bin   && \
    $SUDO mv ansible/lib   /opt/ansible/lib   && \
    $SUDO mv ansible/docs  /opt/ansible/docs  && \
    $SUDO rm -rf ansible                      && \
    \
    \
    echo "===> Installing handy tools (not absolutely required)..."  && \
    $SUDO apt-get install -y sshpass openssh-client  && \
    \
    \
    echo "===> Clean up..."                                         && \
    $SUDO apt-get remove -y --auto-remove \
            build-essential python-pip python-dev git               && \
    $SUDO apt-get clean                                                   && \
    $SUDO rm -rf /var/lib/apt/lists/*                                     && \
    \
    \
    echo "===> Adding hosts for convenience..."  && \
    $SUDO mkdir -p /etc/ansible                        && \
    $SUDO echo 'localhost' | $SUDO tee /etc/ansible/hosts > /dev/null

export PATH=/opt/ansible/bin:$PATH
export PYTHONPATH=/opt/ansible/lib:$PYTHONPATH
export MANPATH=/opt/ansible/docs/man:$MANPATH

#[ "${GIT_WAS_INSTALLED}" != "true" ] && which apt-get && $SUDO apt-get remove -y git
#[ "${GIT_WAS_INSTALLED}" != "true" ] && which apk && apk del curl 

