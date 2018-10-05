#!/usr/bin/env bash

# 1. read key_path from .aws/credentials or from terraform.tfvars:
source ./.aws/credentials
if [ $? != "0" ]; then
  echo "you need to create file openshift-ansible-scripts/.aws/credentials with content like follows:
export AWS_ACCESS_KEY_ID='AKIASTUFF'
export AWS_SECRET_ACCESS_KEY='STUFF'
export ec2_vpc_subnet='vpc-a6e13ecf'
# see also https://github.com/openshift/openshift-ansible/blob/master/README_AWS.md
"
  exit 1
fi

[ "$KEY_PATH" != "" ] && key_path=$KEY_PATH || grep "^key_path" terraform.tfvars | sed 's/ //g' > /tmp/key_path.sh
#echo KEY_PATH=$KEY_PATH
#grep "^key_path" terraform.tfvars | sed 's/ //g' > /tmp/key_path.sh
#echo key_path=$key_path
rm /tmp/key_path.sh 2>/dev/null
[ "$key_path" == "" ] && grep "^key_path" terraform.tfvars | sed 's/ //g' > /tmp/key_path.sh
#if [ $? -eq 0 ]; then
if [ "$key_path" == "" ]; then
if [ -r /tmp/key_path.sh ]; then
  source /tmp/key_path.sh && rm -f /tmp/key_path.sh
else
  read -p "Could not read key_path from terraform.tfvars; Please enter path manually (q for quit):" key_path
    case "$key_path" in
        [q]* ) exit 1;;
        * ) echo "key_path = $key_path";;
    esac
fi
fi

if [ "$key_path" == "" ]; then
  echo "Could not determine AWS Key Path! Exiting...!" >&2
  exit 1
fi

if ! chmod 400 "$key_path"; then
  echo "Could not find file $key_path or could not set correct user permissions"
fi
