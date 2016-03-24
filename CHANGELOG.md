CHANGELOG
=========
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

