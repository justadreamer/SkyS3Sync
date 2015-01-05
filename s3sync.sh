#!/bin/bash

DIR=$1
BUCKET=$2

if [[ $# -ne 2 ]]; then
  echo "Usage: s3sync local_dir bucket_name"
  exit 1
fi
echo "Syncing dir=$1 into s3 bucket=$2"

#sync the directory to S3
s3cmd --delete-removed sync $DIR/ s3://$BUCKET
#get the md5 sums into the temporary manifest
s3cmd --list-md5 ls s3://craigs-test