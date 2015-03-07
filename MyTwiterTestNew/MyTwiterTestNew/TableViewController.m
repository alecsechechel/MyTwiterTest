//
//  TableViewController.m
//  MyTwitterTest
//
//  Created by Alex on 06.03.15.
//  Copyright (c) 2015 Oleksii. All rights reserved.
//

#import "TableViewController.h"
#import <Social/Social.h>

@interface TableViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, strong) NSArray *statuses;

- (IBAction)addTwitt:(UIBarButtonItem *)sender;

@end

@implementation TableViewController

@synthesize account = _account;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self getTimelineAction];
    NSLog(@"count is %lu", (unsigned long)self.statuses.count);



}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.statuses count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *indentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:indentifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:indentifier];
    }
    
    NSDictionary *status = [self.statuses objectAtIndex:indexPath.row];
    
    NSString *text = [status valueForKey:@"text"];
    NSString *screenName = [status valueForKeyPath:@"user.screen_name"];
    NSString *dateString = [status valueForKey:@"created_at"];
    
    cell.textLabel.text = text;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@ | %@", screenName, dateString];
    
    return cell;
}

#pragma mark Twitter
- (void)getTimelineAction {
    
        [_twitter getHomeTimelineSinceID:nil
                                   count:20
                            successBlock:^(NSArray *statuses) {
                                
                                NSLog(@"-- statuses: %@", statuses);
                                
                                self.statuses = statuses;
                                
                                [self.tableView reloadData];
                                
                            } errorBlock:^(NSError *error) {
                                NSLog(@"No lines!");
                            }];
}

#pragma mark - Send new Twitt
- (IBAction)addTwitt:(UIBarButtonItem *)sender {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [tweetSheet setInitialText:@""];
        [self presentViewController:tweetSheet animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Sorry"
                                  message:@"You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}
@end
