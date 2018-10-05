#!/usr/bin/env bash

# preparing inventory:
if [ ! -r terraform.tfstate ]; then
  echo "$0: cannot read terraform.tfstate! Exiting..." >&2
  exit 1
fi

exit 

MASTER=`cat terraform.tfstate | grep ec2- | awk -F '"' '{print $4; exit}'`
NODES=`cat terraform.tfstate | grep ec2- | awk -F '"' -v master="$MASTER" ' $0 !~ master { print $4" openshift_node_labels=\"{'region': 'infra', 'zone': 'default'}\"" }'`

cat inventory | sed "s/^[^ ]* openshift_public_hostname/$MASTER openshift_public_hostname/" > inventory.tmp
cat inventory.tmp | awk '!/openshift_node_labels/' > inventory.tmp2
echo "$NODES" >> inventory.tmp2
mv inventory.tmp2 inventory
