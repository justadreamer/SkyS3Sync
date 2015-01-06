//
//  AppDelegate.h
//  TestS3
//
//  Created by Eugene Dorfman on 11/25/14.
//  Copyright (c) 2014 justadreamer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SkyS3Sync/SkyS3Sync.h>

#define AD ((AppDelegate *)[[UIApplication sharedApplication] delegate])

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic,readonly) SkyS3SyncManager *s3SyncManager;
@property (strong, nonatomic) UIWindow *window;
@end

