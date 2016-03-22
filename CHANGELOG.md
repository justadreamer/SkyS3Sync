CHANGELOG
=========
## 0.16
When copying resources and file happens to already exist, we use NSFileManager's "replace" API
to overwrite it without data loss, instead of first calling "remove", and then "copy"

## 0.15
added API to work solely with resources in syncDirectory without fallback to originalResourcesDirectory if syncDirectory does not contain the resource in question:

    [[s3SyncManager syncDirectory] URLForResource:withExtension:]

