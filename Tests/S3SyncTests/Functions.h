//
//  Functions.h
//  S3SyncTests
//
//  Created by Eugene Dorfman on 1/4/15.
//
//

#ifndef S3SyncTests_Functions_h
#define S3SyncTests_Functions_h

extern void (^delete)(NSURL *);

extern void (^writeFile)(NSString *, NSURL *);

extern NSString *(^readFile)(NSURL *);

extern NSArray *(^contentsOfDirectory)(NSURL *);

#endif
