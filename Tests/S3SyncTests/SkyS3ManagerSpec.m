//
//  SkyS3ManagerSpec.m
//  S3SyncTests
//
//  Created by Eugene Dorfman on 1/3/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <Kiwi/Kiwi.h>
#import <SkyS3Sync/SkyS3Sync.h>
#import <Nocilla/Nocilla.h>

@interface SkyS3SyncManager()
@property (nonatomic,assign) BOOL originalResourcesCopied; //exposing internal state of original resources copied or not
- (void) doSync; //exposing synchronous sync method
@end

SPEC_BEGIN(SkyS3ManagerSpec)
describe(@"SkyS3ManagerSpec", ^{
beforeAll(^{
    [[LSNocilla sharedInstance] start];
});
afterAll(^{
    [[LSNocilla sharedInstance] stop];
});
afterEach(^{
    [[LSNocilla sharedInstance] clearStubs];
});


    //documents directory:
    NSURL *documentsDir = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *originalResourcesDir = [documentsDir URLByAppendingPathComponent:@"test_dir"];
    NSURL *defaultSyncDir = [documentsDir URLByAppendingPathComponent:@"SkyS3Sync/"];
    
    void (^delete)(NSURL *) = ^(NSURL *URL) {
        NSString *path = [URL path];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSError *error = nil;
            if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
                fail(@"failed to delete the directory: %@, error: %@",path,error);
            }
        }
    };
    
    void (^write)(NSString *, NSURL *) = ^(NSString *content, NSURL *URL) {
        NSError *error = nil;
        if (![content writeToURL:URL atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            fail(@"failed to write to URL: %@, error: %@",URL,error);
        }
    };
    
    beforeEach(^{
        delete(defaultSyncDir);
        delete(originalResourcesDir);
        
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:[originalResourcesDir path] withIntermediateDirectories:YES attributes:nil error:&error]) {
            fail(@"failed to create directory: %@, error: %@",originalResourcesDir, error);
        }
        
        write(@"test1",[originalResourcesDir URLByAppendingPathComponent:@"test1.txt"]);
        write(@"test2",[originalResourcesDir URLByAppendingPathComponent:@"test2.txt"]);
        write(@"test3",[originalResourcesDir URLByAppendingPathComponent:@"test3.txt"]);
    });
    
    it(@"should create the sync directory at default location", ^{
        
        
        SkyS3SyncManager *manager = [[SkyS3SyncManager alloc]initWithS3AccessKey:@"test_access_key" secretKey:@"test_secret_key" bucketName:@"test_bucket_name" originalResourcesDirectory:originalResourcesDir];
        
        [[@(manager.originalResourcesCopied) should] beNo];
        [manager doSync];
        [[@(manager.originalResourcesCopied) should] beYes];

        [[@([[NSFileManager defaultManager] fileExistsAtPath:[defaultSyncDir path]]) should] beYes];
    });
    
    it(@"should create the sync directory at specified location", ^{
        
    });
});

SPEC_END