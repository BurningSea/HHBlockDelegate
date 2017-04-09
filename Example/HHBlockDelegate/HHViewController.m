//
//  HHViewController.m
//  HHBlockDelegate
//
//  Created by Howie He on 04/09/2017.
//  Copyright (c) 2017 Howie He. All rights reserved.
//

#import "HHViewController.h"
#import <HHBlockDelegate/HHBlockDelegate.h>

@interface HHViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) id<UITableViewDataSource> dataSource;

@end

@implementation HHViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    id block1 = ^(id test, UITableView *tableView, NSInteger section){
        return (NSInteger)4;
    };
    
    self.tableView.dataSource = self.dataSource = BlockDelegate(UITableViewDataSource, (@{NSStringFromSelector(@selector(tableView:numberOfRowsInSection:)):block1, NSStringFromSelector(@selector(tableView:cellForRowAtIndexPath:)):^(id test, UITableView *tableView, NSIndexPath *indexPath){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
        cell.textLabel.text = [NSString stringWithFormat:@"%@", indexPath];
        return cell;
    }}));
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
