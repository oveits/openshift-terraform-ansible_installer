
# commands needed on Centos or Fedora to install ansible client for installing openshift on AWS 
# with project https://github.com/openshift/openshift-ansible
cd `dirname $0`
sudo dnf install -y which || sudo yum install -y which || sudo apt-get install -y which || dnf install -y which || yum install -y which || apt-get install -y which
source ./.aws_creds 
if [ $? != "0" ]; then
  echo "you need to create file openshift-ansible-scripts/.aws_creds with content like follows:
export AWS_ACCESS_KEY_ID='AKIASTUFF'
export AWS_SECRET_ACCESS_KEY='STUFF'
export ec2_vpc_subnet='vpc-a6e13ecf'
# see also https://github.com/openshift/openshift-ansible/blob/master/README_AWS.md
"
  exit 1
fi

which sudo && SUDO=sudo 2>/dev/null
which yum && INSTALLER=yum 2>/dev/null
which dnf && INSTALLER=dnf 2>/dev/null
which apt-get && INSTALLER=apt-get && apt-get update 2>/dev/null

# for CentOS, (which is using yum as installer) the epel-release repo is needed: see http://stackoverflow.com/questions/32048021/yum-what-is-the-message-no-package-ansible-available
echo $INSTALLER | grep -q yum && $SUDO $INSTALLER install -y epel-release
$SUDO $INSTALLER install -y ansible-2.1.0.0  || $SUDO $INSTALLER install -y ansible
$SUDO $INSTALLER install -y pyOpenSSL python-cryptography python-boto pyOpenSSL

$SUDO $INSTALLER install -y git

if [ $INSTALLER == "apt-get" ]; then
  # ubuntu: ansible installation from source needed because `apt-get install ansible` installs version 2.0.0, which is too old
  git clone git://github.com/ansible/ansible.git --recursive
  cd ./ansible
  source ./hacking/env-setup
  ansible --version
else
  $SUDO $INSTALLER install -y ansible
fi

#git clone https://github.com/openshift/openshift-ansible 
#  cd openshift-ansible && \
#  bin/cluster list aws ''
#  cd ..

DIR=/nfs/openshift-terraform-ansible_installer
cd $DIR || exit 1

# openshift-terraform-ansible: Prep your environment:
cp /nfs/veits/PC/PKI/AWS/AWS_SSH_Key.pem ~/AWS_SSH_Key.pem && chmod 600 ~/AWS_SSH_Key.pem && \
ansible-playbook -i $DIR/terraform.py/terraform.py --private-key=~/AWS_SSH_Key.pem $DIR/openshift-terraform-ansible/ec2/ansible/ose3-prep-nodes.yml && \
ansible-playbook -i $DIR/inventory --become --private-key=~/AWS_SSH_Key.pem $DIR/openshift-ansible/playbooks/byo/config.yml

# for dynamic libraries, boto3 is needed:
$SUDO $INSTALLER install -y boto3

