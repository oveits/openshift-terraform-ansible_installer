
# this file describes how I have prepared the current repository by following the instructions in https://github.com/christian-posta/openshift-terraform-ansible
# 1) downloading following repositories:
#    openshift-terraform-ansible
#    openshift-ansible
#    terraform.py
# 2) installing terraform

which sudo && SUDO=sudo

# install git
$SUDO apt-get update; $SUDO apt-get install -y git

# install terraform
source install_terraform.sh && \

# install ansible
source install_ansible.sh && \

# download openshift-terraform-ansible repository
git clone https://github.com/christian-posta/openshift-terraform-ansible && \
#
# download https://github.com/openshift/openshift-ansible
git clone https://github.com/openshift/openshift-ansible && \
#
# 
git clone https://github.com/CiscoCloud/terraform.py 

# Configure terraform:
vi openshift-terraform-ansible/ec2/main.tf
- add aws_access_key, aws_secret_key, keypair, master_instance_type, node_instance_type, ws_availability_zone, aws_region, aws_ami, num_nodes, key_path

# add SSH secrity rule:
/d/veits/Vagrant/ubuntu-trusty64-docker-aws-test/addSecurityRule.sh
# TODO: describe how to change permissions of the user, so he can use the script
# TODO: create a git repository for the security rule scripts
# TODO: add repository to the openshift-terraform-ansible_installer project as subproject

# run terraform:
terraform plan openshift-terraform-ansible/ec2 && \
echo "execute? (y/n) && read a && [ "$a" == "y" -o "$a" == "yes] && \
terraform apply openshift-terraform-ansible/ec2

# start CentOS Docker image:
docker run --name centos -it --rm -v `pwd`:/nfs centos bash

Edit inventory file (check username, update public DNS names)
TODO: how to automate the inventory file
      either from terraform.py or via dynamic library a la 
        yum install -y boto && source .aws_creds && ./openshift-terraform-ansible/ec2/ec2.py; 
      note that openshift-terraform-ansible/ec2/ec2.ini needs to be updated!

# within the image, run ansible OpenShift installer:
# TODO!!: make sure that the AWS security rule allows internal traffic between nodes and master
/nfs/openshift-terraform-ansible_installer/install_ansible_client.sh


