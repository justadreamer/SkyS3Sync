#!/bin/bash

DIR=$1
BUCKET=$2
MANIFEST=S3Sync.manifest

if [[ $# -ne 2 ]]; then
  echo "Usage: s3sync local_dir bucket_name"
  exit 1
fi
echo "Syncing dir=$1 into s3 bucket=$2"

rm $DIR/$MANIFEST
s3cmd --delete-removed sync $DIR/ s3://$BUCKET
s3cmd --list-md5 ls s3://craigs-test | grep -v manifest | awk '{print $5 " " $4 " " $1 "'T'" $2}' | sed s/s3:\\/\\/$BUCKET\\///g > $DIR/$MANIFEST
s3cmd put $DIR/$MANIFEST s3://$BUCKET
echo "Manifest: "
cat $DIR/$MANIFEST