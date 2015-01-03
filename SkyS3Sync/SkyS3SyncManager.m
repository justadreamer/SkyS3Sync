//
//  SkyS3SyncManager.m
//  TestS3
//
//  Created by Eugene Dorfman on 11/28/14.
//  Copyright (c) 2014 justadreamer. All rights reserved.
//

#import "SkyS3SyncManager.h"

#import <AFAmazonS3Manager/AFAmazonS3Manager.h>
#import <ObjectiveSugar/ObjectiveSugar.h>
#import <AFOnoResponseSerializer/AFOnoResponseSerializer.h>
#import <Ono/Ono.h>
#import <libextobjc/extobjc.h>
#import <FileMD5Hash/FileHash.h>

#import "SkyS3ManifestData.h"

@interface SkyS3SyncManager ()
/**
 *  Amazon S3 Access Key
 */
@property (nonatomic,strong) NSString *S3AccessKey;

/**
 *  Amazon S3 Secret Key
 */
@property (nonatomic,strong) NSString *S3SecretKey;

/**
 *  a name of the S3 bucket to sync the resources from
 */
@property (nonatomic,strong) NSString *S3BucketName;

/**
 *  local directory containing original versions of resources to be used as a starting point over which the synced
 *  versions will be downloaded
 */
@property (nonatomic,strong) NSURL *originalResourcesDirectory;

/**
 *  This property is set when we start syncing to not start a new sync while the current is in progress
 */
@property (atomic,assign) BOOL syncInProgress;

/**
 *  Copying of original resources makes sense once at the start of the application, so we set this flag to not copy it again
 */
@property (atomic,assign) BOOL originalResourcesCopied;


@property (nonatomic,strong) AFAmazonS3Manager *amazonS3Manager;

/**
 *  By default the sync directory is auto-created in an internal location.  You can specify your own directory
 *  with this property, however make sure this directory exists.
 */
@property (nonatomic,strong) NSURL *syncDirectoryURL;
@end

@implementation SkyS3SyncManager

#pragma mark - public methods:
- (instancetype) initWithS3AccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey bucketName:(NSString *)bucketName originalResourcesDirectory:(NSURL *)originalResourcesDirectory {
    if (self = [super init]) {
        self.S3AccessKey = accessKey;
        self.S3SecretKey = secretKey;
        self.S3BucketName = bucketName;
        self.originalResourcesDirectory = originalResourcesDirectory;
    }
    return self;
}
#pragma mark - SkyResourceProvider
- (NSURL *)URLForResource:(NSString *)name withExtension:(NSString *)ext {
    NSString *resourceFileName = [name stringByAppendingPathExtension:ext];
    return [NSURL URLWithString:resourceFileName relativeToURL:self.syncDirectoryURL];
}

#pragma mark - lazy initializers

- (NSURL *)syncDirectoryURL {
    if (!_syncDirectoryURL) {
        NSURL *baseURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
        NSString *syncDirectoryName = self.syncDirectoryName;
        if ([syncDirectoryName characterAtIndex:syncDirectoryName.length-1]!='/') {
             syncDirectoryName = [syncDirectoryName stringByAppendingString:@"/"];
        }

        _syncDirectoryURL = [NSURL URLWithString:syncDirectoryName relativeToURL:baseURL];
        if (![[NSFileManager defaultManager] fileExistsAtPath:[_syncDirectoryURL path]]) {
            NSError *error = nil;
            if (![[NSFileManager defaultManager] createDirectoryAtURL:_syncDirectoryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
                [self log:@"SkyS3SyncManager: failed to create directory at URL: %@, with error: %@",_syncDirectoryURL, error];
                _syncDirectoryURL = nil;
            }
        }
    }
    return _syncDirectoryURL;
}

- (NSString *)syncDirectoryName {
    if (!_syncDirectoryName) {
        _syncDirectoryName = @"SkyS3Sync";
    }
    return _syncDirectoryName;
}

- (AFAmazonS3Manager *)amazonS3Manager {
    if (!_amazonS3Manager) {
        _amazonS3Manager = [[AFAmazonS3Manager alloc] initWithAccessKeyID:self.S3AccessKey secret:self.S3SecretKey];
        _amazonS3Manager.requestSerializer.bucket = self.S3BucketName;
        _amazonS3Manager.responseSerializer = [AFOnoResponseSerializer serializer];
        _amazonS3Manager.completionQueue = dispatch_queue_create("AmazonS3Completion", DISPATCH_QUEUE_CONCURRENT);
    }
    return _amazonS3Manager;
}

#pragma mark - actual sync

- (void) sync {
    NSAssert(self.S3AccessKey, @"S3AccessKey not set");
    NSAssert(self.S3SecretKey, @"S3SecretKey not set");
    NSAssert(self.S3BucketName, @"S3BucketName not set");
    NSAssert(self.originalResourcesDirectory, @"originalResourcesDirectory not set");

    if (!self.syncInProgress) {
        self.syncInProgress = YES;
        @weakify(self)
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
            @strongify(self)
            [self doOriginalResourcesCopying];
            [self doSync];
        });
    }

}

- (void) doOriginalResourcesCopying {
    if (self.originalResourcesCopied) {
        return;
    }

    NSError *error = nil;
    NSArray *resources = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.originalResourcesDirectory includingPropertiesForKeys:@[NSURLIsDirectoryKey,NSURLContentModificationDateKey] options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    if (!resources || error) {
        [self log:@"Failed to get directory contents: %@ error: %@",self.originalResourcesDirectory, error];
    }
    
    [[[resources reject:^BOOL(NSURL *URL) { //first we filter out any directories - we work only with files
        id value;
        NSError *error = nil;
        if (![URL getResourceValue:&value forKey:NSURLIsDirectoryKey error:&error]) {
            [self log:@"error getting NSURLIsDirectoryKey from URL: %@ error: %@",URL,error];
            return NO;
        }
        return [value boolValue];
    }] reject:^BOOL(NSURL *srcURL) { //then for each resource we decide whether it needs to be copied over - we reject those that have the same modification date
        NSURL *dstURL = [self dstURLForSrcURL:srcURL];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[dstURL path]]) {
            //getting src modification date:
            NSDate *srcDate = [self modificationDateForURL:srcURL];
            //getting dst modification date:
            NSDate *dstDate = [self modificationDateForURL:dstURL];
            
            //comparing dates
            if (srcDate && dstDate) {
                //if dates are equal or srcDate is older then we don't copy a resource over
                if ([srcDate timeIntervalSinceDate:dstDate] <= 0) {
                    return YES;
                } else {
                    //src file is newer - was modified later, let's compare the md5 to check if the content is really modified
                    NSString *srcMD5 = [self md5ForURL:srcURL];
                    NSString *dstMD5 = [self md5ForURL:dstURL];
                    return [srcMD5 isEqualToString:dstMD5];
                }
            }
        }
        return NO;
    }] each:^(NSURL *srcURL) { //then each of the picked resources gets copiedls
        NSURL *dstURL = [self dstURLForSrcURL:srcURL];
        NSError *error = nil;
        if (![[NSFileManager defaultManager] copyItemAtURL:srcURL toURL:dstURL error:&error]) {
            [self log:@"Failed to copy: %@ to %@ error: %@",srcURL,dstURL,error];
        }
    }];
    
    self.originalResourcesCopied = YES;
}

- (void) doSync {
    __typeof(self) __weak weakSelf = self;
    [self.amazonS3Manager getBucket:@"/" success:^(id responseObject) {
        ONOXMLDocument *document = responseObject;
        [weakSelf log:@"document=%@",document];
        NSMutableArray *remoteFiles = [NSMutableArray array];
        [document enumerateElementsWithXPath:@"/*/*" usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
            if ([element.tag isEqualToString:@"Contents"]) {
                SkyS3ManifestData *manifestData = [[SkyS3ManifestData alloc] init];
                [element.children each:^(ONOXMLElement *child) {
                    if ([child.tag isEqualToString:@"Key"]) {
                        manifestData.name = [child stringValue];
                    } else if ([child.tag isEqualToString:@"LastModified"]) {
                        manifestData.lastModifiedDate = [child dateValue];
                    } else if ([child.tag isEqualToString:@"Etag"]) {
                        manifestData.etag = [child stringValue];
                    }
                }];
                [remoteFiles addObject:manifestData];
            }
        }];
        weakSelf.syncInProgress = NO;
    } failure:^(NSError *error) {
        [weakSelf log:@"error = %@", error];
        weakSelf.syncInProgress = NO;
    }];
}

#pragma mark - logging

- (void) log:(NSString *)format,... {
    #ifdef DEBUG
        va_list args;
        va_start(args, format);
        NSString *contents = [[NSString alloc] initWithFormat:[@"SkyS3SyncManager: " stringByAppendingString:format] arguments:args];
        NSLog(@"%@",contents);
        va_end(args);
    #endif
}

#pragma mark - auxiliary functions

- (NSDate *) modificationDateForURL:(NSURL *)URL {
    NSError *error = nil;
    NSDate *date = nil;
    if (![URL getResourceValue:&date forKey:NSURLContentModificationDateKey error:&error]) {
        [self log:@"error getting NSURLContentModificationDateKey from URL: %@ error: %@",URL,error];
    }
    return date;
}

- (NSURL *)dstURLForSrcURL:(NSURL *)srcURL {
    return [self.syncDirectoryURL URLByAppendingPathComponent:[srcURL lastPathComponent]];
}

- (NSString *)md5ForURL:(NSURL *)URL {
    return [FileHash md5HashOfFileAtPath:[URL path]];
}

@end
