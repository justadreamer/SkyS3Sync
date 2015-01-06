//
//  DetailViewController.m
//  S3SyncExample
//
//  Created by Eugene Dorfman on 1/6/15.
//  Copyright (c) 2015 justadreamer. All rights reserved.
//

#import "DetailViewController.h"
#import "DetailViewModel.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface DetailViewController ()
@property (nonatomic,strong) IBOutlet UITextView *textView;
@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    RAC(self.textView,text) = RACObserve(self.viewModel, text);
    RAC(self,title) = RACObserve(self.viewModel, title);
}

@end
