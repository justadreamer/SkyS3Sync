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
#import <Ono/Ono.h>
#import <SkyS3Sync/SkyS3ResourceData.h>
#import <FileMD5Hash/FileHash.h>

void(*hit)(NSString *,void(^)(void)) = it;
//#define it(x,y)

@interface SkyS3SyncManager()
@property (nonatomic,assign) BOOL originalResourcesCopied;
@property (atomic,assign) BOOL syncInProgress;

- (void) doSync;
- (void) doOriginalResourcesCopying;
+ (NSDate *) modificationDateForURL:(NSURL *)URL;
- (NSArray *) remoteResourcesFromBucketListXML:(ONOXMLDocument *)document;
- (void) postDidRemoveNotificationWithResourceFileName:(NSString *)resourceFileName andURL:(NSURL *)resourceURL;
- (void) postDidUpdateNotificationWithResourceFileName:(NSString *)resourceFileName  andURL:(NSURL *)resourceURL;
- (void) postDidCopyOriginalNotificationWithResourceFileName:(NSString *)resource andURL:(NSURL *)resourceURL;
@end

SPEC_BEGIN(SkyS3SyncManagerSpec)
describe(@"SkyS3ManagerSpec", ^{

    //common variables:
    NSURL *documentsDir = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *originalResourcesDir = [documentsDir URLByAppendingPathComponent:@"test_dir"];
    NSURL *defaultSyncDir = [documentsDir URLByAppendingPathComponent:@"SkyS3Sync/"];
    
    __block SkyS3SyncManager *manager;

    beforeAll(^{
        [[LSNocilla sharedInstance] start];
    });

    afterAll(^{
        [[LSNocilla sharedInstance] stop];
    });

    void(^clearStubs)(void) = ^{
        [[LSNocilla sharedInstance] clearStubs];
    };

    afterEach(^{
        clearStubs();
        delete(defaultSyncDir);
        delete(originalResourcesDir);
    });
    
    void(^stub404)(void) = ^{
        stubRequest(@"GET", @".*".regex).
        andFailWithError([NSError errorWithDomain:@"'This is OK - deliberately done for tests'" code:404 userInfo:@{}]);
    };
    
    
    beforeEach(^{
        manager = [[SkyS3SyncManager alloc]initWithS3AccessKey:@"test_access_key" secretKey:@"test_secret_key" bucketName:@"test_bucket_name" originalResourcesDirectory:originalResourcesDir];

        delete(defaultSyncDir);
        delete(originalResourcesDir);

        createDir(originalResourcesDir);

        writeFile(@"test1",[originalResourcesDir URLByAppendingPathComponent:@"test1.txt"]);
        writeFile(@"test2",[originalResourcesDir URLByAppendingPathComponent:@"test2.txt"]);
        writeFile(@"test3",[originalResourcesDir URLByAppendingPathComponent:@"test3.txt"]);

        clearStubs();
    });
    
    it (@"should create the sync directory at default location", (^{
        stub404();

        [[theValue(manager.originalResourcesCopied) should] beNo];
        
        [manager sync];
        [NSThread sleepForTimeInterval:1];
        [[theValue(manager.originalResourcesCopied) shouldEventually] beYes];
        [[expectFutureValue(theValue(manager.syncInProgress)) shouldEventually] beNo];

        [[theValue([[NSFileManager defaultManager] fileExistsAtPath:[defaultSyncDir path]]) should] beYes];
    }));
    
    it (@"should create the sync directory at specified location", (^{
        stub404();
        
        NSString *different = @"DifferentSyncDir";
        NSURL *differentSyncDir = [documentsDir URLByAppendingPathComponent:different];
        [[theValue([[NSFileManager defaultManager] fileExistsAtPath:[differentSyncDir path]]) should] beNo];
        
        manager.syncDirectoryName = different;
        [[@(manager.originalResourcesCopied) should] beNo];
        [manager doSync];
        [[@(manager.originalResourcesCopied) should] beYes];
        [[expectFutureValue(theValue(manager.syncInProgress)) shouldEventually] beNo];
        
        
        [[@([[NSFileManager defaultManager] fileExistsAtPath:[differentSyncDir path]]) should] beYes];

        delete(differentSyncDir);
    }));
    
    it (@"should copy the resources into the sync directory at specified location", (^{
        stub404();
        NSArray *syncResources = contentsOfDirectory(defaultSyncDir);
        [syncResources shouldBeNil];

        [manager doSync];
        [[expectFutureValue(theValue(manager.syncInProgress)) shouldEventually] beNo];

        syncResources = contentsOfDirectory(defaultSyncDir);
        [syncResources shouldNotBeNil];
        NSArray *originalResources = contentsOfDirectory(originalResourcesDir);
        [[syncResources should] haveCountOf:[originalResources count]];
    }));
    
    it (@"should not copy the same resources if the sync resources content is the same as original, even if original ones are newer", (^{
        stub404();
        [manager doSync];//copy the resources ones
        [[expectFutureValue(theValue(manager.originalResourcesCopied)) shouldEventually] beYes];
        [[expectFutureValue(theValue(manager.syncInProgress)) shouldEventually] beNo];

        NSURL *test1URL = [originalResourcesDir URLByAppendingPathComponent:@"test1.txt"];
        NSDate *dateOriginal1 = [SkyS3SyncManager modificationDateForURL:test1URL];
        [NSThread sleepForTimeInterval:1]; //needed spot that the dates are different

        writeFile(@"test1",test1URL);
        NSDate *dateOriginal2 = [SkyS3SyncManager modificationDateForURL:test1URL];
        [[dateOriginal2 shouldNot] equal:dateOriginal1];
        [[theValue([dateOriginal2 timeIntervalSinceDate:dateOriginal1]) should] beGreaterThan:theValue(0)];

        manager.originalResourcesCopied = NO;
        
        [[[NSNotificationCenter defaultCenter] should] receive:@selector(postNotificationName:object:) withArguments:SkyS3SyncDidFinishSyncNotification,manager,nil];
        [manager doSync];//copy the resources again
        [[expectFutureValue(theValue(manager.originalResourcesCopied)) shouldEventually] beYes];
        [[expectFutureValue(theValue(manager.syncInProgress)) shouldEventually] beNo];
        
        NSDate *dateSynced = [SkyS3SyncManager modificationDateForURL:[defaultSyncDir URLByAppendingPathComponent:@"test1.txt"]];

        [[dateOriginal1 should] equal:dateSynced];
    }));
    
    it (@"should copy the resources if the content has been modified and the modification date is either same or newer", (^{
        stub404();
        [manager doSync];

        NSURL *originalURL = [originalResourcesDir URLByAppendingPathComponent:@"test1.txt"];
        NSURL *syncedURL = [defaultSyncDir URLByAppendingPathComponent:@"test1.txt"];

        NSString *modifiedContent = @"test1_modified";
        NSString *syncedContent1 = readFile(syncedURL);
        NSString *originalContent = readFile(originalURL);
        [[syncedContent1 shouldNot] equal:modifiedContent];
        [[syncedContent1 should] equal:originalContent];

        writeFile(modifiedContent,originalURL);

        NSDate *dateOriginal2 = [SkyS3SyncManager modificationDateForURL:originalURL];
        
        manager.originalResourcesCopied = NO;
        [manager doSync];//copy the resources again
        [[expectFutureValue(theValue(manager.syncInProgress)) shouldEventually] beNo];

        NSDate *dateSynced = [SkyS3SyncManager modificationDateForURL:syncedURL];
        [[dateSynced should] equal:dateOriginal2];

        NSString *syncedContent2 = readFile(syncedURL);
        [[syncedContent2 should] equal:modifiedContent];
    }));
    
    it (@"should not copy the resources if the content differs, but the modification date of the synced is newer than original", (^{
        stub404();
        [manager doSync];
        [[expectFutureValue(theValue(manager.syncInProgress)) shouldEventually] beNo];
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
        [manager doSync];
        
        [[expectFutureValue(theValue(manager.syncInProgress)) shouldEventually] beNo];
        
        NSDate *dateSynced2 = [SkyS3SyncManager modificationDateForURL:syncedURL];
        NSString *syncedContent2 = readFile(syncedURL);

        [[theValue([dateSynced2 timeIntervalSinceDate:dateSynced1]) should] beGreaterThan:theValue(0)];
        [[syncedContent2 should] equal:modifiedContent];
    }));
    
    it (@"should copy the file from resources if it did not exist before in the sync directory", (^{
        stub404();
        [manager doSync];
        NSString *test4 = @"test4.txt";
        NSURL *test4URLOriginal = [originalResourcesDir URLByAppendingPathComponent:test4];
        writeFile(@"test4",test4URLOriginal);

        manager.originalResourcesCopied = NO;
        [manager doSync];

        NSURL *test4URLSync = [defaultSyncDir URLByAppendingPathComponent:test4];
        [[theValue([[NSFileManager defaultManager] fileExistsAtPath:[test4URLSync path]]) should] beYes];
        [[expectFutureValue(theValue(manager.syncInProgress)) shouldEventually] beNo];

        delete(test4URLOriginal);
        delete(test4URLSync);
    }));
    
    it (@"should get the remote resources from the Amazon S3 List Bucket xml", (^{
        NSURL *xmlURL = [[NSBundle bundleForClass:self.class] URLForResource:@"list-bucket" withExtension:@"xml"]
        ;
        NSError *error = nil;
        ONOXMLDocument *document = [ONOXMLDocument XMLDocumentWithString:readFile(xmlURL) encoding:NSUTF8StringEncoding error:&error];
        if (!document || error) {
            fail(@"failed to create XML document: %@",error);
        }
        
        NSArray *remoteResources = [manager remoteResourcesFromBucketListXML:document];
        [[remoteResources should] beNonNil];
        [[remoteResources should] haveCountOfAtLeast:1];
        
        SkyS3ResourceData *resource = [remoteResources firstObject];
        [[resource.etag should] beNonNil];
        [[resource.lastModifiedDate should] beNonNil];
        [[theValue([resource.lastModifiedDate timeIntervalSinceNow]) should] beGreaterThan:theValue(0)];
        [[resource.name should] equal:@"test1.txt"];
    }));
    
    it (@"should update the local resource if Amazon offers a newer resource with a different md5", (^{
        stub404();
        [[manager shouldEventually] receive:@selector(postDidCopyOriginalNotificationWithResourceFileName:andURL:) withCount:1 arguments:@"test1.txt",[defaultSyncDir URLByAppendingPathComponent:@"test1.txt"]];
        [[manager shouldEventually] receive:@selector(postDidUpdateNotificationWithResourceFileName:andURL:) withCount:1 arguments:@"test1.txt",[defaultSyncDir URLByAppendingPathComponent:@"test1.txt"]];
        
        [manager doSync]; //to copy test1
        [[expectFutureValue(theValue(manager.syncInProgress)) shouldEventually] beNo];
        NSURL *test1URL = [defaultSyncDir URLByAppendingPathComponent:@"test1.txt"];
        NSDate *date1 = [SkyS3SyncManager modificationDateForURL:test1URL];
        [[date1 should] beNonNil];
        
        //stubbing requests:

        NSURL *xmlURL = [[NSBundle bundleForClass:self.class] URLForResource:@"list-bucket" withExtension:@"xml"]
        ;
        
        clearStubs();
        
        stubRequest(@"GET", @"https://test_bucket_name.s3.amazonaws.com/").
        andReturn(200).
        withHeader(@"Content-Type",@"application/xml").
        withBody(readFile(xmlURL));

        stubRequest(@"GET", @"https://test_bucket_name.s3.amazonaws.com/test1.txt").
        andReturn(200).
        withHeader(@"Content-Type",@"text/plain").
        withBody(@"test1_amazon");

        [NSThread sleepForTimeInterval:1];//so that the updated resource is 1 second newer

        [[[NSNotificationCenter defaultCenter] should] receive:@selector(postNotificationName:object:) withArguments:SkyS3SyncDidFinishSyncNotification,manager,nil];
        [manager doSync];
        [[[FileHash md5HashOfFileAtPath:[test1URL path]] should] equal:@"5a105e8b9d40e1329780d62ea2265d8a"];
        [[expectFutureValue([FileHash md5HashOfFileAtPath:[test1URL path]]) shouldEventually] equal:@"d6df2932f01bdc0485ea502f86d10968"];
        [[expectFutureValue(theValue(manager.syncInProgress)) shouldEventually] beNo];

        NSDate *date2 = [SkyS3SyncManager modificationDateForURL:test1URL];
        [[theValue([date2 timeIntervalSinceDate:date1]) should] beGreaterThan:theValue(0)];
    }));
    
    it (@"should not update the local resource if Amazon offers a newer resource but with the same md5", (^{
        stub404();
        [manager doSync]; //to copy test1
        [[expectFutureValue(theValue(manager.syncInProgress)) shouldEventually] beNo];

        NSURL *test1URL = [defaultSyncDir URLByAppendingPathComponent:@"test1.txt"];
        NSDate *date1 = [SkyS3SyncManager modificationDateForURL:test1URL];
        [[date1 should] beNonNil];

        //stubbing requests:
        NSURL *xmlURL = [[NSBundle bundleForClass:self.class] URLForResource:@"list-bucket-same-md5" withExtension:@"xml"]
        ;
        stubRequest(@"GET", @"https://test_bucket_name.s3.amazonaws.com/").
        andReturn(200).
        withHeader(@"Content-Type",@"application/xml").
        withBody(readFile(xmlURL));

        [NSThread sleepForTimeInterval:1]; //so that in case the resource updates it is 1 second newer

        [[[NSNotificationCenter defaultCenter] should] receive:@selector(postNotificationName:object:) withArguments:SkyS3SyncDidFinishSyncNotification,manager,nil];
        [manager doSync];
        [[[FileHash md5HashOfFileAtPath:[test1URL path]] should] equal:@"5a105e8b9d40e1329780d62ea2265d8a"];
        [[expectFutureValue([FileHash md5HashOfFileAtPath:[test1URL path]]) shouldEventually] equal:@"5a105e8b9d40e1329780d62ea2265d8a"];
        [[expectFutureValue(theValue(manager.syncInProgress)) shouldEventually] beNo];
        NSDate *date2 = [SkyS3SyncManager modificationDateForURL:test1URL];
        [[date2 should] equal:date1];
    }));
    
    it (@"should update the local resource if Amazon offers an older resource but with a different md5", (^{
        stub404();
        [manager doSync]; //to copy test1
        [[expectFutureValue(theValue(manager.syncInProgress)) shouldEventually] beNo];
        
        NSURL *test1URL = [defaultSyncDir URLByAppendingPathComponent:@"test1.txt"];
        NSDate *date1 = [SkyS3SyncManager modificationDateForURL:test1URL];
        [[date1 should] beNonNil];
        
        //stubbing requests:
        NSURL *xmlURL = [[NSBundle bundleForClass:self.class] URLForResource:@"list-bucket-older-different-md5" withExtension:@"xml"]
        ;
        clearStubs();
        stubRequest(@"GET", @"https://test_bucket_name.s3.amazonaws.com/").
        andReturn(200).
        withHeader(@"Content-Type",@"application/xml").
        withBody(readFile(xmlURL));
        
        stubRequest(@"GET", @"https://test_bucket_name.s3.amazonaws.com/test1.txt").
        andReturn(200).
        withHeader(@"Content-Type",@"text/plain").
        withBody(@"test1_amazon");
        
        [NSThread sleepForTimeInterval:1]; //so that in case the resource updates it is 1 second newer
        
        [[[NSNotificationCenter defaultCenter] should] receive:@selector(postNotificationName:object:) withArguments:SkyS3SyncDidFinishSyncNotification,manager,nil];
        [manager doSync];
        [[[FileHash md5HashOfFileAtPath:[test1URL path]] should] equal:@"5a105e8b9d40e1329780d62ea2265d8a"];
        [[expectFutureValue([FileHash md5HashOfFileAtPath:[test1URL path]]) shouldEventually] equal:@"d6df2932f01bdc0485ea502f86d10968"];
        [[expectFutureValue(theValue(manager.syncInProgress)) shouldEventually] beNo];
        NSDate *date2 = [SkyS3SyncManager modificationDateForURL:test1URL];
        [[theValue([date2 timeIntervalSinceDate:date1]) should] beGreaterThan:theValue(0)];
    }));

    it (@"should download the resource from Amazon if it did not exist locally", (^{
        [[manager should] receive:@selector(postDidCopyOriginalNotificationWithResourceFileName:andURL:) withCount:1 arguments:@"test1.txt",[defaultSyncDir URLByAppendingPathComponent:@"test1.txt"]];
        [[manager should] receive:@selector(postDidUpdateNotificationWithResourceFileName:andURL:) withCount:1 arguments:@"test1.txt",[defaultSyncDir URLByAppendingPathComponent:@"test1.txt"]];
        [[manager should] receive:@selector(postDidUpdateNotificationWithResourceFileName:andURL:) withArguments:@"test4.txt",[defaultSyncDir URLByAppendingPathComponent:@"test4.txt"]];

        NSURL *xmlURL = [[NSBundle bundleForClass:self.class] URLForResource:@"list-bucket-test4" withExtension:@"xml"]
        ;

        stubRequest(@"GET", @"https://test_bucket_name.s3.amazonaws.com/").
        andReturn(200).
        withHeader(@"Content-Type",@"application/xml").
        withBody(readFile(xmlURL));
        
        stubRequest(@"GET", @"https://test_bucket_name.s3.amazonaws.com/test1.txt").
        andReturn(200).
        withHeader(@"Content-Type",@"text/plain").
        withBody(@"test1_amazon");
        
        stubRequest(@"GET", @"https://test_bucket_name.s3.amazonaws.com/test4.txt").
        andReturn(200).
        withHeader(@"Content-Type",@"text/plain").
        withBody(@"test4_amazon");
        
        NSURL *test1URL = [defaultSyncDir URLByAppendingPathComponent:@"test1.txt"];
        NSURL *test4URL = [defaultSyncDir URLByAppendingPathComponent:@"test4.txt"];
        
        NSURL *test1SyncURL = [[manager syncDirectory] URLForResource:@"test1" withExtension:@"txt"];
        [[test1SyncURL should] beNil];
        
        [[[NSNotificationCenter defaultCenter] should] receive:@selector(postNotificationName:object:) withArguments:SkyS3SyncDidFinishSyncNotification,manager,nil];
        manager.syncInProgress = YES;
        [manager doSync];
        [[[FileHash md5HashOfFileAtPath:[test1URL path]] should] equal:@"5a105e8b9d40e1329780d62ea2265d8a"];
        //first there is no test4:
        [[theValue([[NSFileManager defaultManager] fileExistsAtPath:[test4URL path]]) should] beNo];

        //downloading test1 update:
        [[expectFutureValue([FileHash md5HashOfFileAtPath:[test1URL path]]) shouldEventually] equal:@"d6df2932f01bdc0485ea502f86d10968"];

        //downloading test4 update:
        [[expectFutureValue(theValue([[NSFileManager defaultManager] fileExistsAtPath:[test4URL path]])) shouldEventually] beYes];
        [[expectFutureValue([FileHash md5HashOfFileAtPath:[test4URL path]]) shouldEventually] equal:@"919e96498e0dcc4eba488ee97cdd753b"];
        [[expectFutureValue(theValue(manager.syncInProgress)) shouldEventually] beNo];
        
        test1SyncURL = [[manager syncDirectory] URLForResource:@"test1" withExtension:@"txt"];
        [[test1SyncURL should] beNonNil];
        delete(test4URL);
    }));
    
    it(@"should not sync with Amazon if remoteSyncEnabled is set to NO", (^{
        [[[LSNocilla sharedInstance] shouldNot] receive:@selector(responseForRequest:)];
        manager.remoteSyncEnabled = NO;
        [manager doSync]; //to copy test1
        [[theValue(manager.syncInProgress) should] beYes];
        [NSThread sleepForTimeInterval:1]; //so that in case the resource updates it is 1 second newer

        [[expectFutureValue(theValue(manager.syncInProgress)) shouldEventually] beNo];
        NSURL *test1URL = [defaultSyncDir URLByAppendingPathComponent:@"test1.txt"];
        NSDate *date1 = [SkyS3SyncManager modificationDateForURL:test1URL];
        [[date1 should] beNonNil];
    }));
     
    it (@"should remove legacy local resources if it was removed from Amazon", (^{
        [[[NSNotificationCenter defaultCenter] shouldEventually] receive:@selector(postNotificationName:object:userInfo:)
                                                           withArguments:SkyS3SyncDidCopyOriginalResourceNotification,manager,@{SkyS3ResourceFileName:@"test1.txt",SkyS3ResourceURL:[defaultSyncDir URLByAppendingPathComponent:@"test1.txt"]},nil];
        [[[NSNotificationCenter defaultCenter] shouldEventually] receive:@selector(postNotificationName:object:userInfo:)
                                                           withArguments:SkyS3SyncDidUpdateResourceNotification,manager,@{SkyS3ResourceFileName:@"test1.txt",SkyS3ResourceURL:[defaultSyncDir URLByAppendingPathComponent:@"test1.txt"]},nil];
        [[manager should] receive:@selector(postDidCopyOriginalNotificationWithResourceFileName:andURL:) withCount:1 arguments:@"test2.txt",[defaultSyncDir URLByAppendingPathComponent:@"test2.txt"]]; // update only from original
        [[manager should] receive:@selector(postDidCopyOriginalNotificationWithResourceFileName:andURL:) withCount:1 arguments:@"test3.txt",[defaultSyncDir URLByAppendingPathComponent:@"test3.txt"]]; // update only from original
        [[[NSNotificationCenter defaultCenter] shouldEventually] receive:@selector(postNotificationName:object:userInfo:)
                                                               withArguments:SkyS3SyncDidRemoveResourceNotification,manager,@{SkyS3ResourceFileName:@"test2.txt",SkyS3ResourceURL:[defaultSyncDir URLByAppendingPathComponent:@"test2.txt"]},nil];
        [[[NSNotificationCenter defaultCenter] shouldEventually] receive:@selector(postNotificationName:object:userInfo:)
                                                               withArguments:SkyS3SyncDidRemoveResourceNotification,manager,@{SkyS3ResourceFileName:@"test3.txt",SkyS3ResourceURL:[defaultSyncDir URLByAppendingPathComponent:@"test3.txt"]},nil];

        manager.remoteSyncEnabled = NO;
        [manager doOriginalResourcesCopying];

        NSArray *syncResources = contentsOfDirectory(defaultSyncDir);
        [[syncResources should] haveCountOf:3];
        
        // stubbing requests:
        // whould be great to have response delay for this stubs,
        // so we could also test updates from original notifications with their userInfo dicts for deleted resources ('test2.txt' & 'test3.txt') the same way as we do for 'test1.txt'
        clearStubs();
        
        NSURL *xmlURL = [[NSBundle bundleForClass:self.class] URLForResource:@"list-bucket" withExtension:@"xml"];
        stubRequest(@"GET", @"https://test_bucket_name.s3.amazonaws.com/").
        andReturn(200).
        withHeader(@"Content-Type",@"application/xml").
        withBody(readFile(xmlURL));
        
        stubRequest(@"GET", @"https://test_bucket_name.s3.amazonaws.com/test1.txt").
        andReturn(200).
        withHeader(@"Content-Type",@"text/plain").
        withBody(@"test1_amazon");
        
        manager.remoteSyncEnabled = YES;
        [manager doSync];
        
        [NSThread sleepForTimeInterval:1];//so that the updated resource is 1 second newer
        
        syncResources = contentsOfDirectory(defaultSyncDir);
        [[syncResources should] haveCountOf:1];
        NSString* recoucePath = [(NSURL*)[syncResources firstObject] path];
        [[recoucePath should] endWithString:@"test1.txt"];
        
        // this files can still be accessed from the original resource directory
        NSURL* test2URL = [manager URLForResource:@"test2" withExtension:@"txt"];
        [[test2URL shouldNotAfterWait] beNil];
        NSURL* test3URL = [manager URLForResource:@"test3" withExtension:@"txt"];
        [[test3URL shouldNotAfterWait] beNil];
        
        //but should not be present in the syncDirectory
        test2URL = [[manager syncDirectory] URLForResource:@"test2" withExtension:@"txt"];
        [[test2URL shouldAfterWait] beNil];
        test3URL = [[manager syncDirectory] URLForResource:@"test3" withExtension:@"txt"];
        [[test3URL shouldAfterWait] beNil];
    }));

    it(@"should copy original resources just once, after that only update", (^{
        stub404();
        
        NSDictionary* userInfo = @{SkyS3ResourceFileName:@"test1.txt", SkyS3ResourceURL:[defaultSyncDir URLByAppendingPathComponent:@"test1.txt"]};
        [[[NSNotificationCenter defaultCenter] shouldEventually] receive:@selector(postNotificationName:object:userInfo:) withArguments:SkyS3SyncDidCopyOriginalResourceNotification,manager,userInfo,nil];
        [[[NSNotificationCenter defaultCenter] shouldEventually] receive:@selector(postNotificationName:object:userInfo:) withArguments:SkyS3SyncDidUpdateResourceNotification,manager,userInfo,nil];
        [manager sync];//copy the resources once
        [NSThread sleepForTimeInterval:1];//needed spot that the dates are different
        writeFile(@"test1 updated",[originalResourcesDir URLByAppendingPathComponent:@"test1.txt"]);
        manager.originalResourcesCopied = NO;
        [manager doSync];//try to copy resources again, it would update already copied resources
    }));
    
    it(@"should return URLs within sync directory after original resource copying is finished", (^{
        //original resources copying should be on background thread, and should not happen faster
        //than the execution continues on the main thread
        manager.remoteSyncEnabled = NO;//do not sync with Amazon
        [manager sync];
        [NSThread sleepForTimeInterval:1];
        
        NSURL *test1URL = [manager URLForResource:@"test1" withExtension:@"txt"];
        [[theValue(manager.originalResourcesCopied) shouldEventually] beTrue]; //the resources should have not yet been copied
        
        NSURL *originalTest1URL = [defaultSyncDir  URLByAppendingPathComponent:@"test1.txt"];
        
        [[[test1URL absoluteString] should] equal:[originalTest1URL absoluteString]];
    }));
    
    it(@"should not crash when requesting URL for nil filename or ext", (^{
        NSURL *fileURL = [manager URLForResource:nil withExtension:nil];
        [[fileURL should] beNil];
        
        fileURL = [manager URLForResource:@"asdf" withExtension:nil];
        [[fileURL should] beNil];
        
        fileURL = [[manager syncDirectory] URLForResource:nil withExtension:nil];
        [[fileURL should] beNil];
        
        fileURL = [[manager syncDirectory] URLForResource:@"asdf" withExtension:nil];
        [[fileURL should] beNil];
    }));
    
    it(@"should send SkyS3SyncDidFailToListBucket when bucket list request fails", (^{
        NSString *URLString = @"https://test_bucket_name.s3.amazonaws.com/";
        NSURL *URL = [NSURL URLWithString:URLString];

        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:404 userInfo:@{NSURLErrorFailingURLErrorKey:URL, NSURLErrorFailingURLStringErrorKey:URLString}];
        
        [[[NSNotificationCenter defaultCenter] shouldEventually] receive:@selector(postNotificationName:object:userInfo:) withArguments:SkyS3SyncDidFailToListBucket,manager, @{SkyS3BucketName:@"test_bucket_name", SkyS3Error:error},nil];
        
        stubRequest(@"GET", URLString)
        .andFailWithError(error);
        [manager sync];
    }));
    
    it(@"should send SkyS3SyncDidFailToDownloadResource when resource download fails", (^{
        NSString *URLString = @"https://test_bucket_name.s3.amazonaws.com/test1.txt";
        NSURL *URL = [NSURL URLWithString:URLString];

        [[[NSNotificationCenter defaultCenter] shouldEventually] receive:@selector(postNotificationName:object:userInfo:) withArguments:SkyS3SyncDidFailToDownloadResource, manager, @{SkyS3ResourceFileName:@"test1.txt", SkyS3BucketName:@"test_bucket_name", SkyS3Error: [NSError errorWithDomain:NSURLErrorDomain code:404 userInfo:@{NSURLErrorFailingURLStringErrorKey: URLString, NSURLErrorFailingURLErrorKey: URL}]},nil];
        
        NSURL *xmlURL = [[NSBundle bundleForClass:self.class] URLForResource:@"list-bucket" withExtension:@"xml"]
        ;
        
        stubRequest(@"GET", @"https://test_bucket_name.s3.amazonaws.com/").
        andReturn(200).
        withHeader(@"Content-Type",@"application/xml").
        withBody(readFile(xmlURL));
        
        stubRequest(@"GET", URLString).
        andFailWithError([NSError errorWithDomain:NSURLErrorDomain code:404 userInfo:nil]);
        
        [manager sync];
    }));
});

SPEC_END
