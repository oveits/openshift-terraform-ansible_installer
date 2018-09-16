#!/usr/bin/env bash

cd `dirname $0`
#ls -al

# defines $SUDO and $INSTALLER variables:
source ./detect_installer.sh

# install terraform:
terraform -version || ( echo "terraform not found on the system; installing terraform" && ./install_terraform.sh )
terraform init openshift-terraform-ansible/ec2/

FILES=".aws/credentials terraform.tfvars"

for FILE in $FILES
do
  if [ -r "$FILE" ]; then
    echo "file $FILE found."
  else
    if [ -r "${FILE}.example" ]; then
      cp ${FILE}.example ${FILE} && echo "file $FILE created from example file." || FAILMSG="could not copy file $FILE created from example file"
      if [ "$FAILMSG" != "" ]; then
        echo "$FAILMSG" >&2
	exit 1
      fi
    else
      echo "Could not create file from example file ${FILE}.example; Not found. Exiting..." >&2
      exit 1
    fi
  fi
  
  while true; do
    echo "file `pwd`/$FILE has following content:"
    echo "----------------------"
    cat $FILE
    echo "----------------------"
    read -p "Do you wish to change the content? (yes/no) " yn
    case "$yn" in
        [Yy]* ) vi $FILE;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
  done
done

source ./.aws/credentials
[ "$AWS_ACCESS_KEY_ID" != "" ] && export TF_VAR_aws_access_key=$AWS_ACCESS_KEY_ID || exit 1
[ "$AWS_SECRET_ACCESS_KEY" != "" ] && export TF_VAR_aws_secret_key=$AWS_SECRET_ACCESS_KEY || exit 1
source ./detect_installer.sh && \
which wget 2>/dev/null 1>/dev/null || \
$SUDO $INSTALL -y wget
export TF_VAR_IP_with_full_access=`wget http://ipinfo.io/ip -qO -`

echo "Reviewing Terraform Plan"

DIR=openshift-terraform-ansible/ec2
FILE=$DIR/main.tf

while true; do
  # with user input, we need, the following line, which hangs at the end until we send a return:
  #tee >(terraform plan -out=terraform.plan $DIR) | tee -a terraform.plan.log
  # without user input, this line works better:
  terraform plan $@ -out=terraform.plan $DIR | tee -a terraform.plan.log
  read -p "Change/Apply plan? Note, that this might induce costs with your IaaS provider (change/apply/quit) " yn
  case "$yn" in
      [Cc]* ) echo entering variable file; vi terraform.tfvars; echo entering terraform plan file; vi $FILE;;
      [Aa]* ) terraform apply terraform.plan; break;;
      [Qq]* ) echo "you can edit file $FILE manually and re-run this script at a later time"; break;;
      * ) echo "Please answer change, apply or quit.";;
  esac
done



# install ansible:
#bash install_ansible.sh


