#!/bin/bash


# Check if VPC id was explicetely provided via argument (only needed when creating new vpc)
if [ "$1" == ""  ];
then
  vpc_id=`cat ~/vpc_id`
else
  vpc_id=$1
fi


count=`echo "${vpc_id}" | grep -c 'vpc-'`
if [ "${count}" != "1" ]; then
  aak=`cat ~/.boto | grep aws_access_key_id | awk '{ print $3 }'`
  ask=`cat ~/.boto | grep aws_secret_access_key | awk '{ print $3 }'`
  region=`ec2-metadata -p  | awk -F"." '{ print $2}'`
  i_id=`ec2-metadata -i | awk '{ print $2 }'`
  vpc_id=`ec2-describe-instances -O ${aak} -W ${ask} --region ${region} ${i_id} | grep '^NIC' | grep 'vpc-' | awk '{ print $4 }'`
  echo ${vpc_id} >  ~/vpc_id
fi

echo -n ${vpc_id}
