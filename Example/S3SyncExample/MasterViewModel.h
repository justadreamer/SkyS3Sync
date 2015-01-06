//
//  MasterViewModel.h
//  S3SyncExample
//
//  Created by Eugene Dorfman on 1/6/15.
//  Copyright (c) 2015 justadreamer. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DetailViewModel;
@interface MasterViewModel : NSObject
@property (nonatomic,readonly) NSArray *resources;
- (DetailViewModel *)detailViewModelForResourceAtIndex:(NSUInteger)index;
- (void) refresh;
@end
