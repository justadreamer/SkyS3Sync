
#SkyS3SyncManager


A simple resource manager that allows to remotely update app's resources via Amazon S3.  Basically the manager hosts a local mirror of the Amazon S3 bucket.

##Integration

SkyS3SyncManager class is not a singleton (to allow f.e. for syncing several S3 buckets each with its own separate manager).  Thus it is best to create a 'sticky' instance belonging to an object which has a significantly long life-time.  For the simplest use case it can be your application delegate object.  Below is a suggested integration snippet (taken from the Example):

AppDelegate.h:

```objective-c

	#define AD ((AppDelegate *)[[UIApplication sharedApplication] delegate])

	@interface AppDelegate : UIResponder <UIApplicationDelegate>
	@property (nonatomic,readonly) SkyS3SyncManager *s3SyncManager;
	@property (strong, nonatomic) UIWindow *window;
	@end

```

AppDelegate.m:

```objective-c

	@interface AppDelegate ()
	@property (nonatomic,readwrite,strong) SkyS3SyncManager *s3SyncManager;
	@end
	
	@implementation AppDelegate
	
	
	- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	    NSURL *resourcesDirectory = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"test_dir"];
	
	    #include "S3Secrets.h"
	    self.s3SyncManager = [[SkyS3SyncManager alloc] initWithS3AccessKey:S3AccessKey
	                                                             secretKey:S3SecretKey
	                                                            bucketName:S3BucketName
	                                            originalResourcesDirectory:resourcesDirectory];
	
	    return YES;
	}
	
	- (void)applicationDidBecomeActive:(UIApplication *)application {
	    [self.s3SyncManager sync];
	}
	
	@end

```