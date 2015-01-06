//
//  MasterViewModel.m
//  S3SyncExample
//
//  Created by Eugene Dorfman on 1/6/15.
//  Copyright (c) 2015 justadreamer. All rights reserved.
//

#import "MasterViewModel.h"
#import "AppDelegate.h"
#import <SkyS3Sync/SkyS3Sync.h>
#import "DetailViewModel.h"

@interface MasterViewModel()
@property (nonatomic,strong,readwrite) NSArray *resources;
@end

@implementation MasterViewModel
- (instancetype) init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourcesDidUpdate:) name:SkyS3SyncDidUpdateResourceNotification object:[AD s3SyncManager]];
        [self fillResources];
    }
    return self;
}

- (void) fillResources {
    NSError *error = nil;
    self.resources = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[AD s3SyncManager].syncDirectoryURL includingPropertiesForKeys:nil options:0 error:&error];
    if (!self.resources || error) {
        NSLog(@"failed to get contents of directory: %@",error);
    }
}

- (void) resourcesDidUpdate:(NSNotification *)notification {
    //in case any new resources have been added
    [self fillResources];
}

- (DetailViewModel *)detailViewModelForResourceAtIndex:(NSUInteger)index {
    return [[DetailViewModel alloc] initWithResourceURL:self.resources[index]];
}

- (void) refresh {
    [[AD s3SyncManager] sync];
}

@end
