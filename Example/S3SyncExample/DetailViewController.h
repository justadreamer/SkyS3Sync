//
//  DetailViewController.h
//  S3SyncExample
//
//  Created by Eugene Dorfman on 1/6/15.
//  Copyright (c) 2015 justadreamer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewModel;
@interface DetailViewController : UIViewController
@property (nonatomic,strong) DetailViewModel *viewModel;
@end
