#!/bin/bash
set -e

aak=`cat ~/.boto | grep aws_access_key_id | awk '{ print $3 }'`
ask=`cat ~/.boto | grep aws_secret_access_key | awk '{ print $3 }'`
region=$1
vpc_id=$2
environment=$3
az=$4


## First check if there is already a  subnet tagged for the environment
do_reserve=no
subnets_json=`aws ec2 describe-subnets  --region ${region} --filters "Name=vpc-id,Values=${vpc_id}" "Name=tag:env,Values=${environment}" | jq  '.Subnets[]'`
if [ "${subnets_json}" == "" ]; then ## and if not, find a free subnet group
    do_reserve=yes   
    for i in {13..32};  do
        subnets_json=`aws ec2 describe-subnets  --region ${region} --filters "Name=vpc-id,Values=${vpc_id}" "Name=tag:env,Values=''" "Name=tag:groupNumber,Values=${i}" | jq -r '.Subnets[]'`
        if [ "${subnets_json}" != "" ]; then
            break
        fi 
    done
fi


if [ "${do_reserve}" == "yes" ]; then
    subnet_ids=`echo "${subnets_json}" | jq -r '.SubnetId'`
    result=`aws ec2 create-tags --region ${region} --resources ${subnet_ids}  --tags "Key=env,Value=${environment}" "Key=Name,Value=${environment}"`
fi

if [ "${az}" != "" ]; then
    return_subnet=`echo "${subnets_json}" | jq -r ". | select(.AvailabilityZone==\"${region}${az}\") | .SubnetId"`
else
    return_subnet=`echo -n  "${subnets_json}" | jq -r ".SubnetId" |  tr '\n' ',' `
fi
echo   "${return_subnet}"


