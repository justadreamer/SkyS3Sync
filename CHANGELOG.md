CHANGELOG
=========

1.0.2
remove previous temporary file to avoid sync collisions
----

1.0.1
use coordinated writing when copy files
----

0.31
allow to obtain the resource from the sync directory without any extension
----

0.29
separated AFAmazonS3Manager objects for loading list and individual resources
----

0.28
added ‘nonnull’ and ‘nullable’ qualifiers to SkyS3SyncManager
removed legacy test. S3SyncTests project updated to new swift syntax
----

0.27
don’t check is original resources copied in URLForResourceWithFileName: method
----

0.26
3 attempts to load list or resource before failing
----

0.25
SkyS3Error is passed in all fail download notifications
----

0.24
fail load resource notification contains bucket name
----

0.23
notifications when resource loading fails
----

0.22
sync queue changed priority to DEFAULT, otherwise sometimes resources do not sync
----

0.21
added Mac OS X 10.10 as a deployment target
----

0.20
migrate to git@gitlab.postindustria.com:ios/skys3sync.git
----

0.19
----
reverted the change of 0.16, since replace API does not work when we are copying the files from resource bundle

0.18
----
should not crash when requesting URL for nil filename or ext

0.17
----
consistent URL behaviors:

- syncdirectory URLs are not valid until originalResourcesCopied, returning an URL to original resource before all original resources are copied, for consistency
- consistent URLs in notifications - always pointing to a syncDir URL (f.e. didUpdate etc.)
- consistent URL forming using [dirURL URLByAppendingPathComponent:]
- unit tests corrected and improved

0.16
----
When copying resources and file happens to already exist, we use NSFileManager's "replace" API
to overwrite it without data loss, instead of first calling "remove", and then "copy"

0.15
----
added API to work solely with resources in syncDirectory without fallback to originalResourcesDirectory if syncDirectory does not contain the resource in question:

    [[s3SyncManager syncDirectory] URLForResource:withExtension:]

