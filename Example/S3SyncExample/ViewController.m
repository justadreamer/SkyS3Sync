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
@property (nonatomic,strong) SkyS3SyncManager *s3SyncManager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL *resourcesDirectory = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"test_dir"];
    self.s3SyncManager = [[SkyS3SyncManager alloc] initWithS3AccessKey:@""
                                                             secretKey:@""
                                                            bucketName:@""
                                            originalResourcesDirectory:resourcesDirectory];
    [self.s3SyncManager sync];
}

@end
