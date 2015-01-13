//
//  MasterViewController.m
//  S3SyncExample
//
//  Created by Eugene Dorfman on 1/6/15.
//  Copyright (c) 2015 justadreamer. All rights reserved.
//

#import "MasterViewController.h"
#import "MasterViewModel.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "DetailViewController.h"

@interface MasterViewController ()
@property (nonatomic,strong) MasterViewModel *viewModel;
@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.viewModel = [[MasterViewModel alloc] init];

    @weakify(self);
    [RACObserve(self, viewModel.resources) subscribeNext:^(id x) {
        @strongify(self);
        NSIndexPath *selectedRow = self.tableView.indexPathForSelectedRow;
        [self.tableView reloadData];
        if (selectedRow && selectedRow.row < [self tableView:self.tableView numberOfRowsInSection:0]) {
            [self.tableView selectRowAtIndexPath:selectedRow animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.resources.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.textLabel.text = [self.viewModel.resources[indexPath.row] lastPathComponent];
    
    return cell;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *destination = [segue destinationViewController];
    DetailViewController *detail = (DetailViewController *)destination;
    if ([destination isKindOfClass:[UINavigationController class]]) {
        detail = (DetailViewController *)[(UINavigationController *)destination topViewController];
    }
    detail.viewModel = [self.viewModel detailViewModelForResourceAtIndex:self.tableView.indexPathForSelectedRow.row];
}

- (IBAction)refresh:(id)sender {
    [self.viewModel refresh];
}

@end
