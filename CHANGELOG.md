CHANGELOG
=========
## 0.15
added API to work solely with resources in syncDirectory without fallback to originalResourcesDirectory if syncDirectory does not contain the resource in question:

    [[s3SyncManager syncDirectory] URLForResource:withExtension:]

