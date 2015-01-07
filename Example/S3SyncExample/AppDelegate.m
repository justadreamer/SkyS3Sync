//
//  AppDelegate.m
//  TestS3
//
//  Created by Eugene Dorfman on 11/25/14.
//  Copyright (c) 2014 justadreamer. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property (nonatomic,readwrite,strong) SkyS3SyncManager *s3SyncManager;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSURL *resourcesDirectory = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"test_dir"];

    #include "S3Secrets.h"
    self.s3SyncManager = [[SkyS3SyncManager alloc] initWithS3AccessKey:S3AccessKey
                                                             secretKey:S3SecretKey
                                                            bucketName:S3BucketName
                                            originalResourcesDirectory:resourcesDirectory];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self.s3SyncManager sync];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
