#!/bin/bash

DIR=$1
BUCKET=$2
if [ ! -z $3 ] 
then
  CONFIG="-c `ls ~/.s3cfg_$3`"
else
  CONFIG=""
fi

if [[ $# -lt 2 ]]; then
  echo "Usage: s3sync local_dir bucket_name"
  exit 1
fi
echo "Syncing dir=$1 into s3 bucket=$2"

#sync the directory to S3
s3cmd --delete-removed sync $DIR/ s3://$BUCKET $CONFIG

#show the md5 sums
s3cmd --list-md5 ls s3://$BUCKET $CONFIG