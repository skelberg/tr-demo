#!/bin/bash

set -e

script_dir=$(dirname "$(readlink -f $0)")
host_list=`${script_dir}/ec2.py --refresh-cache | jq -r '.ec2[]'`
vpc_id=`${script_dir}/../cloud/scripts/what_is_my_vpc_id.sh`
default_line="127.0.0.1   localhost localhost.localdomain"



extra_lines=$(
for ip in ${host_list}; do
  host_info=`${script_dir}/ec2.py --host ${ip}`
  node_name=`echo "${host_info}" | jq -r '.ec2_tag_Name'`
  ec2_id=`echo "${host_info}" | jq -r '.ec2_id'`
  ec2_public_dns_name=`echo "${host_info}" | jq -r '.ec2_public_dns_name'`
  ec2_vpc_id=`echo "${host_info}" | jq -r '.ec2_vpc_id'`
  echo -e "${ip} \t ${node_name} \t # ${ec2_id} \t ${ec2_public_dns_name} \t ${ec2_vpc_id}" 
done
)


if [ "${extra_lines}" == "" ];  then
   echo "oops, no instances found on Amazon. Just to be safe,  quiting here and not updating anyting... "
   exit 1   
fi

sudo sh -c   "echo '${default_line}'  >  /etc/hosts"
sudo sh -c  "echo '${extra_lines}' | grep '${vpc_id}' | sort -k2  >>  /etc/hosts"

## Update /etc/hosts for corresponding environment  if it was provided as an argument
if [ "$1" != "" ]; then
  hosts=`cat /etc/hosts | grep " ${1}-" | awk '{ print $2 }' | grep -v '\-ans-'`
  for i in ${hosts}; do
    ansible-playbook -i ${script_dir}/ec2 -l ${i} ${script_dir}/../playbooks/common.yml  -t hosts
  done
fi
