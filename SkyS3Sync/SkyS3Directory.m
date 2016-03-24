//
//  SkyS3Directory.m
//  Pods
//
//  Created by Eugene Dorfman on 1/18/16.
//
//

#import "SkyS3Directory.h"

@implementation SkyS3Directory
- (nonnull instancetype) initWithDirectoryURL:(nonnull NSURL *)directoryURL {
    if (self = [super init]) {
        self.directoryURL = directoryURL;
    }
    return self;
}

- (NSURL *)URLForResourceWithFileName:(NSString *)fileName {
    NSURL *URL = [self.directoryURL URLByAppendingPathComponent:fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[URL path]]) {
        return URL;
    }
    
    return nil;
}

#pragma mark - SkyS3ResourceURLProvider
- (NSURL *)URLForResource:(NSString *)name withExtension:(NSString *)ext {
    NSString *filename = [name stringByAppendingPathExtension:ext];
    return [self URLForResourceWithFileName:filename];
}


@end
