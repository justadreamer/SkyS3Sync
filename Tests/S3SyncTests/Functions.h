//
//  Functions.h
//  S3SyncTests
//
//  Created by Eugene Dorfman on 1/4/15.
//
//

#ifndef S3SyncTests_Functions_h
#define S3SyncTests_Functions_h

void createDir(NSURL *);

void delete(NSURL *);

void writeFile(NSString *, NSURL *);

NSString *readFile(NSURL *);

NSArray *contentsOfDirectory(NSURL *);

#endif
