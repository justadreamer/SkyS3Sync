//
//  DetailViewModel.m
//  S3SyncExample
//
//  Created by Eugene Dorfman on 1/6/15.
//  Copyright (c) 2015 justadreamer. All rights reserved.
//

#import "DetailViewModel.h"
#import <SkyS3Sync/SkyS3Sync.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface DetailViewModel()
@property (nonatomic,strong) NSURL *resourceURL;
@end

@implementation DetailViewModel
- (instancetype) initWithResourceURL:(NSURL *)URL {
    if (self = [super init]) {
        @weakify(self);
        RAC(self,resourceURL) = [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:SkyS3SyncDidUpdateResourceNotification object:nil] filter:^BOOL(NSNotification *notification) {
            @strongify(self);
            return [[self.resourceURL lastPathComponent] isEqualToString:notification.userInfo[SkyS3ResourceFileName]];
        }] map:^id(NSNotification *notification) {
            return notification.userInfo[SkyS3ResourceURL];
        }];

        RACSignal *URLSignal = RACObserve(self,resourceURL);
        [[URLSignal filter:^BOOL(NSURL *URL) {
            return URL!=nil;
        }] subscribeNext:^(NSURL *resourceURL) {
            @strongify(self);
            [self updateText];
        }];
        
        RAC(self,title) = [URLSignal map:^id(NSURL *URL) {
            return [URL lastPathComponent];
        }];

        self.resourceURL = URL;
    }

    return self;
}

- (void) updateText {
    NSError *error = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[self.resourceURL path] error:&error];
    if (!attributes || error) {
        NSLog(@"failed to get file attributes: %@",error);
    }
    error = nil;
    NSString *content = [NSString stringWithContentsOfURL:self.resourceURL encoding:NSUTF8StringEncoding error:&error];
    if (!content || error) {
        NSLog(@"failed to get file content: %@",error);
    }

    self.text = [NSString stringWithFormat:@"modified date: %@\ncontents:\n%@",attributes[NSFileModificationDate],content];
}

@end
