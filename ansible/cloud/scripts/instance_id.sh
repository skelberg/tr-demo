#!/bin/bash
set -e

region=$1
vpc_id=$2
name=$3
env=`echo ${name} | awk -F"-" '{ print $1 }'`



## get the instance id(s)
instance_id=`aws ec2 describe-instances  --region ${region} --filters "Name=vpc-id,Values=${vpc_id}" "Name=tag:Name,Values=${name}" "Name=tag:env,Values=${env}"`  
echo "${instance_id}" | jq -r '.Reservations[].Instances[].InstanceId' 

