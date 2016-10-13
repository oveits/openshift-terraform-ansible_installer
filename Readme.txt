Installing an OpenShift cluster on Amazon Web Services

# Specify AWS credentials:
cp .aws_creds.example .aws_creds
vi .aws_creds
#
aws_access_key="your_aws_access_key"
aws_secret_key="your_aws_secret_key"

# Apply AWS credentials:
source .aws_creds

# Configure terraform:
export TF_VAR_aws_access_key=$AWS_ACCESS_KEY_ID
export TF_VAR_aws_secret_key=$AWS_SECRET_ACCESS_KEY
export TF_VAR_IP_with_full_access=`wget http://ipinfo.io/ip -qO -`
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars

# Make sure that the key owner has following AWS permission:
- AmazonEC2FullAccess

# In a future version, we want to use dynamic inventories. In this case, following AWS permissions are needed additionaly:
- AmazonElasticCacheReadOnlyAccess
- AmaonRDSReadOnlyAccess

# OV: obsolete for new main.tf with VPC and security rule generation:
## Add SSH secrity rule and run terraform: cut&paste the next set of lines to the Linux command line:
#/d/veits/Vagrant/ubuntu-trusty64-docker-aws-test/addSecurityRule.sh && \

# Review Terraform plan:
terraform plan -out=terraform.plan openshift-terraform-ansible/ec2
# or if you want to log the readable output for later reference:
tee >(terraform plan -out=terraform.plan openshift-terraform-ansible/ec2) | tee -a terraform.plan.log

# Run Terraform plan:
terraform apply terraform.plan

# start CentOS Docker image:
cd .. && \
docker run --name centos -it --rm -v `pwd`:/nfs centos bash

DIR=/nfs/openshift-terraform-ansible_installer
cd $DIR || exit 1

# Retrieve information needed for next step:
$ cat $DIR/terraform.tfstate | grep ec2- | awk -F '"' '{print $4}'
ec2-52-57-51-241.eu-central-1.compute.amazonaws.com
ec2-52-57-112-189.eu-central-1.compute.amazonaws.com

# the first line is the DNS name of the master, all subsequent lines are the DNS names of the nodes
# this information now must be updated in the inventory file:
vi $DIR/inventory

# make sure the username is also correct (coreos, if you do not change the ami)
# in the example above, the last lines must look like follows:
[masters]
ec2-52-57-51-241.eu-central-1.compute.amazonaws.com openshift_public_hostname=master.fuse.osecloud.com

# host group for nodes, includes region info
[nodes]
ec2-52-57-112-189.eu-central-1.compute.amazonaws.com openshift_node_labels="{'region': 'infra', 'zone': 'default'}"

# TODO: how to automate the inventory file
#       either from terraform.py or via dynamic library a la 
#          yum install -y boto && \
#	  source .aws_creds && \
#	  ./openshift-terraform-ansible/ec2/ec2.py; 
#       note that openshift-terraform-ansible/ec2/ec2.ini needs to be updated!

# within the image, run ansible OpenShift installer:
# TODO!!: make sure that the AWS security rule allows internal traffic between nodes and master
bash $DIR/install_ansible_client.sh

# Then, on the master, create the first user "test" with password "changeme": 
sudo htpasswd -b /etc/origin/openshift-passwd test changeme

# On the web client connecting to the service, you need to add following line to the hosts file:
52.57.97.219  master master.fuse.osecloud.com

# where the IP address must be the real public IP of the master and master.fuse.osecloud.com had been defined in the inventory file

########## HOW THIS REPOSITORY WAS CREATED ######################

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

# TODO:
- conduct a e2e test with VPC -> done
- private key handling: e.g. create a directory named .aws, and place credentials file and aws private key there -> done
- automatic detection of IP_with_full_access (myIP) -> done
- replace static ami by map between regions and ami of CentOS 7
- describe how to change permissions of the user, so he can use the script
# TODO: 
- create a git repository for the security rule scripts addSecurity -> not needed for this project, since security rule now is set by terraform
- add addSecurity repository to the openshift-terraform-ansible_installer project as subproject -> not needed for this project, since security rule now is set by terraform
