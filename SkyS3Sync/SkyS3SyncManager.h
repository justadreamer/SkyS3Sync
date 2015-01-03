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
@property (nonatomic,strong) NSURL *localDirectoryURL;

/**
 *  A singleton access point
 *
 *  @return an instance of SkyS3SyncManager
 */
+ (instancetype) sharedInstance;

/**
 *  To be called from AppDelegate's applicationDidBecomeActive: method to check if anything has been updated on S3
 *  and sync down any updated files.
 */
- (void) sync;

@end
