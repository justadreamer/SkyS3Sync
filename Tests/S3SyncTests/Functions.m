//
//  Functions.m
//  S3SyncTests
//
//  Created by Eugene Dorfman on 1/4/15.
//
//

#import <Foundation/Foundation.h>
#import <Kiwi/Kiwi.h>

void createDir(NSURL *URL) {
    NSError *error = nil;
    NSString *path = [URL path];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
            fail(@"failed to create directory: %@, error: %@",path,error);
        }
    }
}

void delete(NSURL *URL) {
    NSString *path = [URL path];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
            fail(@"failed to delete the directory: %@, error: %@",path,error);
        }
    }
};

void writeFile(NSString *content, NSURL *URL) {
    NSError *error = nil;
    if (![content writeToURL:URL atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        fail(@"failed to write to URL: %@, error: %@",URL,error);
    }
};

NSString *readFile(NSURL *URL) {
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&error];
    if (!content || error) {
        fail(@"faield to read URL: %@, error: %@",URL,error);
    }
    return content;
};

NSArray *contentsOfDirectory(NSURL *URL) {
    NSError *error = nil;
    NSArray *resources = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:URL includingPropertiesForKeys:nil options:0 error:&error];
    return resources;
};
