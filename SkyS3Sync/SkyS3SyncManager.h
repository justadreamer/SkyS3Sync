//
//  SkyS3SyncManager.h
//  TestS3
//
//  Created by Eugene Dorfman on 11/28/14.
//  Copyright (c) 2014 justadreamer. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  A simple protocol that allows to inject either SkyS3SyncManger or NSBundle instance as a 
 *  provider of some stored resource
 */
@protocol SkyResourceProvider
/**
 *  To get a URL of the particular resource of the latest synced version
 *
 *  @param name filename of the resource
 *  @param ext  extension of the resource
 *
 *  @return a URL to the particular resource
 */
- (NSURL *)URLForResource:(NSString *)name withExtension:(NSString *)ext;
@end


/**
 *  A simple S3 syncing service, which syncs the contents of the S3BucketName to 
 *  an internal local directory
 */
@interface SkyS3SyncManager : NSObject<SkyResourceProvider>

/**
 *  by default the sync directory name is SkyS3Sync, and it is stored under Documents, you can specify an arbitrary name for it (in case f.e. of name 
 *  collission, or if you are working with several instances of SkyS3SyncManager
 */
@property (nonatomic,strong) NSString *syncDirectoryName;

/**
 *  Designated initializer
 *
 *  @param accessKey                  Amazon S3 Access Key
 *  @param secretKey                  Amazon S3 Secret Key
 *  @param bucketName                 Amazon S3 Bucket Name
 *  @param originalResourcesDirectory URL of the local directory, which contains original versions of resources to be used as startig poit over which the synced 
 *   versions will be downloaded
 *
 *  @return returns a fully initialized SkyS3SyncManager
 */
- (instancetype) initWithS3AccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey bucketName:(NSString *)bucketName originalResourcesDirectory:(NSURL *)originalResourcesDirectory NS_DESIGNATED_INITIALIZER;

- (instancetype) init NS_UNAVAILABLE;

/**
 *  To be called from AppDelegate's applicationDidBecomeActive: method to check if anything has been updated on S3
 *  and sync down any updated files.
 */
- (void) sync;

@end