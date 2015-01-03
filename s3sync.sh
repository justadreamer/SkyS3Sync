#!/bin/bash

DIR=$1
BUCKET=$2
MANIFEST=S3Sync.manifest

if [[ $# -ne 2 ]]; then
  echo "Usage: s3sync local_dir bucket_name"
  exit 1
fi
echo "Syncing dir=$1 into s3 bucket=$2"

#create new manifest
rm $DIR/$MANIFEST

#sync the directory to S3
s3cmd --delete-removed sync $DIR/ s3://$BUCKET
#get the md5 sums into the temporary manifest
s3cmd --list-md5 ls s3://craigs-test | grep -v manifest | awk '{print $5 " " $4}' | sed s/s3:\\/\\/$BUCKET\\///g > /tmp/$MANIFEST

#need to add current modified dates into manifest
#stat -f "%Sm" -t "%Y-%d-%mT%TZ%z" FILE
touch $DIR/$MANIFEST
cp /tmp/$MANIFEST $DIR/$MANIFEST

#upload the manifest to S3:
s3cmd put $DIR/$MANIFEST s3://$BUCKET

echo "Manifest: "
cat $DIR/$MANIFEST