//
//  DetailViewModel.h
//  S3SyncExample
//
//  Created by Eugene Dorfman on 1/6/15.
//  Copyright (c) 2015 justadreamer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DetailViewModel : NSObject
@property (nonatomic,strong) NSString *title;
@property (nonatomic,strong) NSString *text;

- (instancetype) initWithResourceURL:(NSURL *)URL NS_DESIGNATED_INITIALIZER;

@end
