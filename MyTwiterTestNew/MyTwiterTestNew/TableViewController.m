//
//  TableViewController.m
//  MyTwitterTest
//
//  Created by Alex on 06.03.15.
//  Copyright (c) 2015 Oleksii. All rights reserved.
//

#import "TableViewController.h"
#import <Social/Social.h>
#import "TweetComposeViewController.h"
#import "TweetComposeViewController.h"
#import "Chameleon.h"
#import "MCSwipeTableViewCell.h"

@interface TableViewController () <UITableViewDataSource, UITableViewDelegate,TweetComposeViewControllerDelegate, MCSwipeTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, strong) NSArray *statuses;

@property (nonatomic, strong) MCSwipeTableViewCell *cellToDelete;
@property (nonatomic, strong) NSString* statusId;
@property (nonatomic, strong) NSString* textTweet;
@property (nonatomic, strong) UIRefreshControl* refreshControl;

- (IBAction)addTwitt:(UIBarButtonItem *)sender;

@end

@implementation TableViewController

@synthesize account = _account;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self getTimelineAction];
    [self setupRefreshControl];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Refresh Control
- (void)setupRefreshControl {
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor flatWhiteColor];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self
                            action:@selector(getTimelineAction)
                  forControlEvents:UIControlEventValueChanged];
}

-(void)refreshing {
    if (self.refreshControl) {
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MMM d, h:mm a"];
        NSString *title = [NSString stringWithFormat:@"Last update: %@", [formatter stringFromDate:[NSDate date]]];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                    forKey:NSForegroundColorAttributeName];
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
        self.refreshControl.attributedTitle = attributedTitle;
        
        [self.refreshControl endRefreshing];
    }
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.statuses count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *indentifier = @"Cell";
    MCSwipeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:indentifier];
    
    if(cell == nil) {
        cell = [[MCSwipeTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:indentifier];
    }
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    NSDictionary *status = [self.statuses objectAtIndex:indexPath.row];
    
    NSString *text = [status valueForKey:@"text"];
    NSString *screenName = [status valueForKeyPath:@"user.screen_name"];
    NSString *dateString = [status valueForKey:@"created_at"];

    if ([screenName isEqualToString:self.account.username]) {
        cell.backgroundColor = [UIColor flatWhiteColor];
        cell.number = [NSString stringWithFormat:@"%@", [status valueForKey:@"id"]];
        [self configureCell:cell forRowAtIndex: 1];
    } else {
        cell.backgroundColor = [UIColor clearColor];
    }
    
    cell.textLabel.text = text;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@ | %@", screenName, dateString];
    
    return cell;
}

- (void)configureCell:(MCSwipeTableViewCell *)cell forRowAtIndex:(NSInteger)indexPathRow {
    
    UIView *crossView = [self viewWithImageName:@"cross"];
    UIColor *redColor = [UIColor colorWithRed:232.0 / 255.0 green:61.0 / 255.0 blue:14.0 / 255.0 alpha:1.0];
    
    UIView *editView = [self viewWithImageName:@"edit"];
    UIColor *yellowColor = [UIColor colorWithRed:254.0 / 255.0 green:217.0 / 255.0 blue:56.0 / 255.0 alpha:1.0];
   
    [cell setDefaultColor:self.tableView.backgroundView.backgroundColor];
    
    [cell setDelegate:self];
    if (indexPathRow == 1) {
        //edit
        [cell setSwipeGestureWithView:editView color:yellowColor mode:MCSwipeTableViewCellModeExit state:MCSwipeTableViewCellState1 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
            [self editTwitt];
        }];

        //delete
        [cell setSwipeGestureWithView:crossView color:redColor mode:MCSwipeTableViewCellModeExit state:MCSwipeTableViewCellState3 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
            
            _cellToDelete = cell;
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete?"
                                                                message:@"Are you sure your want to delete this twitt?"
                                                               delegate:self
                                                      cancelButtonTitle:@"No"
                                                      otherButtonTitles:@"Yes", nil];
            [alertView show];
        }];
    }
    
}

- (void)swipeTableViewCellDidStartSwiping:(MCSwipeTableViewCell *)cell {
    self.statusId = cell.number;
    self.textTweet = cell.textLabel.text;
}

#pragma mark - Utils

- (void)reload:(id)sender {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (UIView *)viewWithImageName:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    return imageView;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    // No
    if (buttonIndex == 0) {
        [_cellToDelete swipeToOriginWithCompletion:^{
            NSLog(@"Swiped back");
        }];
        _cellToDelete = nil;
    } else {
        [self deleteTwitt];
    }
}

#pragma mark Twitter
- (void)getTimelineAction {
    
        [_twitter getHomeTimelineSinceID:nil
                                   count:20
                            successBlock:^(NSArray *statuses) {
                                
                                self.statuses = statuses;
                                [self.tableView reloadData];
                                [self refreshing];
                                
                            } errorBlock:^(NSError *error) {

                            }];
}

- (void)deleteTwitt{
    NSString * url = [[NSString alloc] initWithFormat:@"https://api.twitter.com/1.1/statuses/destroy/%@.json", self.statusId];
    
    SLRequest *sendTweet  = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                               requestMethod:SLRequestMethodPOST
                                                         URL:[NSURL URLWithString:url]
                                                  parameters: nil];
    sendTweet.account = self.account;
    [sendTweet performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if ([urlResponse statusCode] == 200) {
            [self getTimelineAction];
        }
        else {
            [self getTimelineAction];
        }
    }];
}

- (void)editTwitt {
    
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
        {
            SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            [tweetSheet setInitialText:self.textTweet];
            [self presentViewController:tweetSheet animated:YES completion:nil];
            
            [tweetSheet setCompletionHandler:^(SLComposeViewControllerResult result) {
                switch (result) {
                    case SLComposeViewControllerResultCancelled:
                        [self getTimelineAction];
                        break;
                    case SLComposeViewControllerResultDone:
                        [self deleteTwitt];
                        [self getTimelineAction];
                        break;
                    default:
                        break;
                }
                
                [self dismissViewControllerAnimated:YES completion:nil];
                
            }];
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

#pragma mark - Send new Twitt
- (IBAction)addTwitt:(UIBarButtonItem *)sender {
    
    TweetComposeViewController *tweetComposeViewController = [[TweetComposeViewController alloc] init];
    tweetComposeViewController.account = self.account;
    tweetComposeViewController.tweetComposeDelegate = self;
    [self presentViewController:tweetComposeViewController animated:YES completion:nil];
}

#pragma mark - Compose Tweet

- (void)composeTweet
{
    TweetComposeViewController *tweetComposeViewController = [[TweetComposeViewController alloc] init];
    tweetComposeViewController.account = self.account;
    tweetComposeViewController.tweetComposeDelegate = self;
    [self presentViewController:tweetComposeViewController animated:YES completion:nil];
    
}

- (void)tweetComposeViewController:(TweetComposeViewController *)controller didFinishWithResult:(TweetComposeResult)result {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self getTimelineAction];
}
@end
