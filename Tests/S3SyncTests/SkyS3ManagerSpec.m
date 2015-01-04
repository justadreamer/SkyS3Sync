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
#import "Functions.h"

@interface SkyS3SyncManager()
@property (nonatomic,assign) BOOL originalResourcesCopied; //exposing internal state of original resources copied or not
- (void) doSync; //exposing synchronous sync method

+ (NSDate *) modificationDateForURL:(NSURL *)URL;
@end

SPEC_BEGIN(SkyS3SyncManagerSpec)
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
    
    __block SkyS3SyncManager *manager;
    
    beforeEach(^{
        delete(defaultSyncDir);
        delete(originalResourcesDir);
        
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:[originalResourcesDir path] withIntermediateDirectories:YES attributes:nil error:&error]) {
            fail(@"failed to create directory: %@, error: %@",originalResourcesDir, error);
        }
        
        writeFile(@"test1",[originalResourcesDir URLByAppendingPathComponent:@"test1.txt"]);
        writeFile(@"test2",[originalResourcesDir URLByAppendingPathComponent:@"test2.txt"]);
        writeFile(@"test3",[originalResourcesDir URLByAppendingPathComponent:@"test3.txt"]);
        
        manager = [[SkyS3SyncManager alloc]initWithS3AccessKey:@"test_access_key" secretKey:@"test_secret_key" bucketName:@"test_bucket_name" originalResourcesDirectory:originalResourcesDir];
    });
    
    it(@"should create the sync directory at default location", ^{
        [[@(manager.originalResourcesCopied) should] beNo];
        [manager doSync];
        [[@(manager.originalResourcesCopied) should] beYes];

        [[@([[NSFileManager defaultManager] fileExistsAtPath:[defaultSyncDir path]]) should] beYes];
    });
    
    it(@"should create the sync directory at specified location", ^{
        NSString *different = @"DifferentSyncDir";
        NSURL *differentSyncDir = [documentsDir URLByAppendingPathComponent:different];
        [[theValue([[NSFileManager defaultManager] fileExistsAtPath:[differentSyncDir path]]) should] beNo];
        
        manager.syncDirectoryName = different;
        [[@(manager.originalResourcesCopied) should] beNo];
        [manager doSync];
        [[@(manager.originalResourcesCopied) should] beYes];
        
        
        [[@([[NSFileManager defaultManager] fileExistsAtPath:[differentSyncDir path]]) should] beYes];

        delete(differentSyncDir);
    });
    
    it(@"should copy the resources into the sync directory at specified location", ^{
        NSArray *syncResources = contentsOfDirectory(defaultSyncDir);
        [syncResources shouldBeNil];

        [manager doSync];

        syncResources = contentsOfDirectory(defaultSyncDir);
        [syncResources shouldNotBeNil];
        NSArray *originalResources = contentsOfDirectory(originalResourcesDir);
        [[syncResources should] haveCountOf:[originalResources count]];
    });
    
    it(@"should not copy the same resources if the sync resources content is the same as original, even if original ones are newer", ^{
        [manager doSync];//copy the resources ones
        NSURL *test1URL = [originalResourcesDir URLByAppendingPathComponent:@"test1.txt"];
        NSDate *dateOriginal1 = [SkyS3SyncManager modificationDateForURL:test1URL];
        [NSThread sleepForTimeInterval:1]; //needed sot that the dates are different

        writeFile(@"test1",test1URL);
        NSDate *dateOriginal2 = [SkyS3SyncManager modificationDateForURL:test1URL];
        [[dateOriginal2 shouldNot] equal:dateOriginal1];
        [[theValue([dateOriginal2 timeIntervalSinceDate:dateOriginal1]) should] beGreaterThan:theValue(0)];

        manager.originalResourcesCopied = NO;
        [manager doSync];//copy the resources again
        
        NSDate *dateSynced = [SkyS3SyncManager modificationDateForURL:[defaultSyncDir URLByAppendingPathComponent:@"test1.txt"]];

        [[dateOriginal1 should] equal:dateSynced];
    });
    
    it (@"should copy the resources if the content has been modified and the modification date is either same or newer", ^{
        [manager doSync];
        NSURL *originalURL = [originalResourcesDir URLByAppendingPathComponent:@"test1.txt"];
        NSURL *syncedURL = [defaultSyncDir URLByAppendingPathComponent:@"test1.txt"];

        NSDate *dateOriginal1 = [SkyS3SyncManager modificationDateForURL:originalURL];
        NSString *modifiedContent = @"test1_modified";
        NSString *syncedContent1 = readFile(syncedURL);
        NSString *originalContent = readFile(originalURL);
        [[syncedContent1 shouldNot] equal:modifiedContent];
        [[syncedContent1 should] equal:originalContent];

        writeFile(modifiedContent,originalURL);
        
        
        NSDate *dateOriginal2 = [SkyS3SyncManager modificationDateForURL:originalURL];
        [[dateOriginal1 should] equal:dateOriginal2];
        
        manager.originalResourcesCopied = NO;
        [manager doSync];//copy the resources again

        NSDate *dateSynced = [SkyS3SyncManager modificationDateForURL:syncedURL];
        [[dateSynced should] equal:dateOriginal1];

        NSString *syncedContent2 = readFile(syncedURL);
        [[syncedContent2 should] equal:modifiedContent];
    });
    
    it (@"should not copy the resources if the content differs, but the modification date of the synced is newer than original", ^{
        [manager doSync];
        NSURL *originalURL = [originalResourcesDir URLByAppendingPathComponent:@"test1.txt"];
        NSURL *syncedURL = [defaultSyncDir URLByAppendingPathComponent:@"test1.txt"];
        
        NSDate *dateSynced1 = [SkyS3SyncManager modificationDateForURL:syncedURL];
        NSString *modifiedContent = @"test1_modified";

        NSString *originalContent = readFile(originalURL);
        NSString *syncedContent1 = readFile(syncedURL);

        [[originalContent should] equal:syncedContent1];
        [NSThread sleepForTimeInterval:1];
        
        writeFile(modifiedContent,syncedURL);
        manager.originalResourcesCopied = NO;
        [manager sync];

        NSDate *dateSynced2 = [SkyS3SyncManager modificationDateForURL:syncedURL];
        NSString *syncedContent2 = readFile(syncedURL);

        [[theValue([dateSynced2 timeIntervalSinceDate:dateSynced1]) should] beGreaterThan:theValue(0)];
        [[syncedContent2 should] equal:modifiedContent];
    });
    
    it (@"should copy the file from resources if it did not exist before in the sync directory", ^{
        
    });
    
    it (@"should update the resource if Amazon offers a newer resource with updated md5", ^{
        NSURL *xmlURL = [[NSBundle bundleForClass:self.class] URLForResource:@"list-bucket" withExtension:@"xml"]
        ;

        stubRequest(@"GET", @"https://test_bucket.s3.amazonaws.com/").
        andReturn(200).
        withHeader(@"Content-Type",@"application/xml").
        withBody(readFile(xmlURL));

        [manager doSync];
        
        
    });
    
    it (@"should not update the resource if Amazon offers a newer resource with the same md5", ^{
        
    });

});

SPEC_END