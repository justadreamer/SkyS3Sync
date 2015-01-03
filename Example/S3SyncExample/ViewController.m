//
//  ViewController.m
//  TestS3
//
//  Created by Eugene Dorfman on 11/25/14.
//  Copyright (c) 2014 justadreamer. All rights reserved.
//

#import "ViewController.h"

#import "SkyS3Sync.h"
#import "SkyS3SyncManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [SkyS3SyncManager sharedInstance].S3AccessKey = @"AKIAJPQLN7ROAD4Z5AQQ";
    [SkyS3SyncManager sharedInstance].S3SecretKey = @"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";
    [SkyS3SyncManager sharedInstance].S3BucketName = @"craigs-test";
    [SkyS3SyncManager sharedInstance].localDirectoryURL = [[NSBundle mainBundle] resourceURL];
    [[SkyS3SyncManager sharedInstance] sync];
}

@end
