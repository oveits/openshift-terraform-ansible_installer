
# enable root login on AWS CentOS (does not help with the issues, though)
# sudo cp /root/.ssh/authorized_keys /root/.ssh/authorized_keys.bak
# sudo cp /home/centos/.ssh/authorized_keys /root/.ssh/authorized_keys
# sudo sed -i 's/#PermitRootLogin .*$/PermitRootLogin yes/g' /etc/ssh/sshd_config
# sudo systemctl restart sshd.service

# currently following workarounds are needed:
# 1. ssh into the target system and change Docker networking from overlay2 to devicemapper, see 
##### TODO: describe or automate workaround on https://stackoverflow.com/questions/45461307/selinux-is-not-supported-with-the-overlay-graph-driver
# echo 'DOCKER_STORAGE_OPTIONS="--storage-driver devicemapper "' | sudo tee /etc/sysconfig/docker-storage
# echo 'STORAGE_DRIVER=devicemapper' | sudo tee /etc/sysconfig/docker-storage-setup
# sudo systemctl restart docker
#
# 2. systemd-modules-load.service does not start successfully upon glusterfs installation
#    Workaround: re-run the 2_docker* script
#    However, the problem that systemd-modules-load.service does not start, persists. It is just ignored on the second run
#    next troubleshooting steps:
#    - log/2_install_openshift_via_ansible_2_unable_start_systemd-modules-load.log
#    - issue 7734: https://github.com/openshift/openshift-ansible/issues/7734 
#
# issues 1 und 2 RESOLVED by updating the image from "ami-9bf712f4" to "ami-dd3c0f36"

cd `dirname $0`

ansible --version

sleep 10

# preparing inventory:
#cp -pf $DIR/openshift-ansible/inventory/hosts.example  inventory

#INVENTORY=inventory
INVENTORY=inventory.all-in-one

MASTER=`cat terraform.tfstate | grep ec2- | awk -F '"' '{print $4; exit}'`
NODES=`cat terraform.tfstate | grep ec2- | awk -F '"' -v master="$MASTER" ' $0 !~ master { print $4" openshift_node_labels=\"{'\''region'\'': '\''infra'\'', '\''zone'\'': '\''default'\''}\"" }'`
yum install jq -y
export MASTER_PUBLIC_IP=$(cat terraform.tfstate | jq -r '.modules[0].resources | map(select(.primary.attributes."tags.role" == "masters")) | .[0] .primary.attributes."public_ip"')
export MASTER_PRIVATE_IP=$(cat terraform.tfstate | jq -r '.modules[0].resources | map(select(.primary.attributes."tags.role" == "masters")) | .[0] .primary.attributes."private_ip"')
export MASTER_PUBLIC_DNS=$(cat terraform.tfstate | jq -r '.modules[0].resources | map(select(.primary.attributes."tags.role" == "masters")) | .[0] .primary.attributes."public_dns"')
export MASTER_PRIVATE_DNS=$(cat terraform.tfstate | jq -r '.modules[0].resources | map(select(.primary.attributes."tags.role" == "masters")) | .[0] .primary.attributes."private_dns"')

cat inventory | sed "s/^[^ ]* openshift_public_hostname/$MASTER openshift_public_hostname/" > inventory.tmp
cat inventory.tmp | awk '!/openshift_node_labels/' > inventory.tmp2
echo "$NODES" >> inventory.tmp2
mv inventory.tmp2 inventory
#exit

yum install gettext -y
envsubst < ${INVENTORY}.ini > ${INVENTORY}



SKIPINSTALL=true

# commands needed on Centos or Fedora to install ansible client for installing openshift on AWS 
# with project https://github.com/openshift/openshift-ansible
cd `dirname $0`
#pwd
#sudo dnf install -y which || sudo yum install -y which || sudo apt-get install -y which || dnf install -y which || yum install -y which || apt-get install -y which
source ./detect_installer.sh
#source ./.aws_creds 

# 1. read key_path from .aws/credentials or from terraform.tfvars:
source ./read_key_file.sh 
#source ./.aws/credentials
#if [ $? != "0" ]; then
#  echo "you need to create file openshift-ansible-scripts/.aws/credentials with content like follows:
#export AWS_ACCESS_KEY_ID='AKIASTUFF'
#export AWS_SECRET_ACCESS_KEY='STUFF'
#export ec2_vpc_subnet='vpc-a6e13ecf'
## see also https://github.com/openshift/openshift-ansible/blob/master/README_AWS.md
#"
#  exit 1
#fi
#
#[ "$KEY_PATH" != "" ] && key_path=$KEY_PATH || grep "^key_path" terraform.tfvars | sed 's/ //g' > /tmp/key_path.sh
##echo KEY_PATH=$KEY_PATH
##grep "^key_path" terraform.tfvars | sed 's/ //g' > /tmp/key_path.sh 
##echo key_path=$key_path
#rm /tmp/key_path.sh 2>/dev/null
#[ "$key_path" == "" ] && grep "^key_path" terraform.tfvars | sed 's/ //g' > /tmp/key_path.sh 
##if [ $? -eq 0 ]; then
#if [ -r /tmp/key_path.sh ]; then
#  source /tmp/key_path.sh && rm -f /tmp/key_path.sh
#else
#  read -p "Could not read key_path from terraform.tfvars; Please enter path manually (q for quit):" key_path
#    case "$key_path" in
#        [q]* ) exit 1;;
#        * ) echo "key_path = $key_path";;
#    esac
#fi
#
#if [ "$key_path" == "" ]; then
#  echo "Could not determine AWS Key Path! Exiting...!" >&2
#  exit 1
#fi
#
#if ! chmod 400 "$key_path"; then
#  echo "Could not find file $key_path or could not set correct user permissions" 
#fi
# end 1. read key_path from .aws/credentials or from terraform.tfvars

#which sudo && SUDO=sudo 2>/dev/null
#which yum && INSTALLER=yum 2>/dev/null
#which dnf && INSTALLER=dnf 2>/dev/null
#which apt-get && INSTALLER=apt-get && apt-get update 2>/dev/null

# for CentOS, (which is using yum as installer) the epel-release repo is needed: see http://stackoverflow.com/questions/32048021/yum-what-is-the-message-no-package-ansible-available
#echo $INSTALL 

if [ "$SKIPINSTALL" == ""  ]; then
  echo $INSTALL | grep -q yum && $INSTALL epel-release
  $INSTALL ansible-2.1.0.0  || $INSTALL ansible
  $INSTALL pyOpenSSL python-cryptography python-boto pyOpenSSL
  $INSTALL git
fi

echo "$INSTALL" | grep -q "apt-get"
if [ $? -eq 0 ]; then
  # ubuntu: ansible installation from source needed because `apt-get install ansible` installs version 2.0.0, which is too old
  git clone git://github.com/ansible/ansible.git --recursive
  cd ./ansible
  source ./hacking/env-setup
  ansible --version
else
  $INSTALL ansible
fi
#exit

#git clone https://github.com/openshift/openshift-ansible 
#  cd openshift-ansible && \
#  bin/cluster list aws ''
#  cd ..

DIR=.
#DIR=/app
#DIR=/nfs/openshift-terraform-ansible_installer
#DIR=/nfs
cd $DIR || exit 1

# openshift-terraform-ansible: Prep your environment:
# 1. read key_path from terraform.tfvars:
grep "^key_path" terraform.tfvars | sed 's/ //g' > /tmp/key_path.sh 
#[ $? -eq 0 -a -r /tmp/key_path.sh] && 
source /tmp/key_path.sh && rm /tmp/key_path.sh
chmod 400 $key_path && \
#cp /nfs/veits/PC/PKI/AWS/AWS_SSH_Key.pem ~/AWS_SSH_Key.pem && chmod 600 ~/AWS_SSH_Key.pem && \
export ANSIBLE_HOST_KEY_CHECKING=False && \

ansible-playbook -i $DIR/terraform.py/terraform.py --private-key=${key_path} $DIR/openshift-terraform-ansible/ec2/ansible/ose3-prep-nodes.yml && \

#echo "stopping here" && \
#exit 1
#cp -R $DIR/openshift-ansible/roles /etc/ansible/ && \
#cp -p $DIR/openshift-ansible/ansible.cfg.example $DIR/ansible.cfg.example && \
#cp -pf $DIR/openshift-ansible/ansible.cfg.example $DIR/openshift-ansible/ansible.cfg && \
#cp -pf $DIR/openshift-ansible/playbooks/ansible.cfg.example $DIR/openshift-ansible/ansible.cfg && \
#export ANSIBLE_CONFIG=$DIR/openshift-ansible/ansible.cfg.example && \
#export ANSIBLE_CONFIG=$DIR/ansible.cfg.example && \
export ANSIBLE_CONFIG=$DIR/openshift-ansible/ansible.cfg && \
#cat $ANSIBLE_CONFIG | grep role && \
#ansible-playbook -i $DIR/${INVENTORY} --become --tag="always" --private-key=${key_path} $DIR/openshift-ansible/playbooks/byo/config.yml

#ansible-playbook -i $DIR/${INVENTORY} --become --private-key=${key_path} $DIR/openshift-ansible/playbooks/byo/config.yml | tee $DIR/log/2_install_openshift_via_ansible.log

# temporarily added for quicker feedback on current failures:
# ansible-playbook -i $DIR/${INVENTORY} --become --private-key=${key_path} $DIR/openshift-ansible/playbooks/openshift-master/additional_config.yml

ansible-playbook -i $DIR/${INVENTORY} --become --private-key=${key_path} $DIR/openshift-ansible/playbooks/prerequisites.yml -vvv | tee $DIR/log/2_install_openshift_via_ansible.log
echo "ssh -t -i ${key_path}  centos@${MASTER_PUBLIC_IP} <<EOSSHCOMMAND397459 ..."
# ansible-playbook -i $DIR/${INVENTORY} --become --private-key=${key_path} $DIR/openshift-ansible/playbooks/openshift-master/config.yml -vvv 
ssh -o "StrictHostKeyChecking=no" -t -i ${key_path}  centos@${MASTER_PUBLIC_IP} <<EOSSHCOMMAND397459
sudo mkdir -p /etc/origin/master/
sudo touch /etc/origin/master/htpasswd
sudo chmod 600 /etc/origin/master/htpasswd
EOSSHCOMMAND397459

#exit

# has caused "Timeout (32s) waiting for privilege escalation prompt":
# ansible-playbook -i $DIR/${INVENTORY} --become --become-method=su --private-key=${key_path} $DIR/openshift-ansible/playbooks/deploy_cluster.yml -vvvvv | tee -a $DIR/log/2_install_openshift_via_ansible.log
ansible-playbook -i $DIR/${INVENTORY} --become --private-key=${key_path} $DIR/openshift-ansible/playbooks/deploy_cluster.yml -vvvvv | tee -a $DIR/log/2_install_openshift_via_ansible.log
# in the moment, the playbook fails on first run, therefore, let us try again:
#[ $? != 0 ] && "echo retrying..." && ansible-playbook -i $DIR/${INVENTORY} --become --private-key=${key_path} $DIR/openshift-ansible/playbooks/deploy_cluster.yml -vvvvv | tee -a $DIR/log/2_install_openshift_via_ansible.log

##roles_path = $DIR/openshift-ansible/roles/openshift_facts && \
##cp $DIR/openshift-ansible/utils/etc/ansible.cfg /etc/ansible/ansible.cfg
#export ANSIBLE_CONFIG=$DIR/openshift-ansible/utils/etc/ansible.cfg
#ls -l $ANSIBLE_CONFIG 2>&1
#grep role_path $ANSIBLE_CONFIG 2>&1
##cat /etc/ansible/ansible.cfg
#echo "pwd=`pwd`"
#ansible-playbook -i $DIR/${INVENTORY} --become --private-key=${key_path} $DIR/openshift-ansible/playbooks/byo/config.yml
##ansible-playbook -i $DIR/${INVENTORY} --tags "always" --become --private-key=${key_path} $DIR/openshift-ansible/playbooks/byo/config.yml

# for dynamic libraries, boto3 is needed:
# see https://www.centos.org/forums/viewtopic.php?t=16608: clean all needed; otherwise boto3 not found
echo $INSTALL | grep -q yum && $SUDO yum clean all 
# see http://stackoverflow.com/questions/2481287/how-do-i-install-boto
#$SUDO $INSTALLER install -y boto3
[ "$SKIPINSTALL" == "" ] && $INSTALL python-boto

# create an OpenShift user 'test' with random password:
# random password generation from http://www.howtogeek.com/howto/30184/10-ways-to-generate-a-random-password-from-the-command-line/
TESTPASSWD=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c6`
#MASTERIP=`cat ./terraform.tfstate | grep '"public_ip"' | awk -F '"' '{print $4; exit}'`
MASTERIP=$MASTER_PUBLIC_IP
#MASTERDNS=`cat ./${INVENTORY} | grep ec2- | awk -F '=' '{print $2; exit}'`
MASTERDNS=$MASTER_PUBLIC_DNS
SSHUSER=`cat ./${INVENTORY} | grep 'ansible_ssh_user=' | awk -F '=' '{print $2;exit}'`

#ssh -t -i ~/AWS_SSH_Key.pem ${SSHUSER}@${MASTERIP} sudo htpasswd -b /etc/origin/openshift-passwd test $TESTPASSWD && \
echo "ssh -t -i ${key_path}  ${SSHUSER}@${MASTERIP} sudo htpasswd -cb /etc/origin/openshift-passwd test $TESTPASSWD"
#ssh -t -i ${key_path}  ${SSHUSER}@${MASTERIP} sudo htpasswd -cb /etc/origin/openshift-passwd test $TESTPASSWD && \
ssh -t -i ${key_path}  ${SSHUSER}@${MASTERIP} <<EOSSHCOMMAND
#sudo mkdir /etc/origin
#sudo htpasswd -cb /etc/origin/openshift-passwd test $TESTPASSWD
sudo htpasswd -b /etc/origin/master/htpasswd test $TESTPASSWD
EOSSHCOMMAND

[ $? == 0 ] && SUCCESS=true || SUCCESS=false

if [ "$SUCCESS" == "true" ]; then
   echo "######################################################################"
   echo '# OpenShift successfully installed!'
   echo "# Try adding $MASTERDNS to your hosts file with IP address $MASTERIP"
   echo "# and use a browser to connect to https://${MASTERDNS}:8443"
   echo "# Log in as user 'test' with password '$TESTPASSWD'"
   echo "#"
   echo "# New users can be added by connecting to the master via"
   echo "#   ssh -t -i ${key_path} ${SSHUSER}@${MASTERIP}"
   echo "# and there:"
   echo "#   sudo htpasswd -b /etc/origin/openshift-passwd test $TESTPASSWD"
   echo "######################################################################"
else
   echo "######################################################################"
   echo '# Could not create test user on OpenShift Master!!!'
   echo "# Try connecting to the OpenShift master via:"
   echo "#   ssh -t -i ${key_path} ${SSHUSER}@${MASTERIP}"
   echo "# and try adding the user manually via:"
   echo "#   sudo htpasswd -b /etc/origin/openshift-passwd test $TESTPASSWD"
   echo "######################################################################"
fi

