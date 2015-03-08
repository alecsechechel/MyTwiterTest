//
//  ViewController.m
//  MyTwitter
//
//  Created by Alex on 04.03.15.
//  Copyright (c) 2015 Oleksii. All rights reserved.
//

#import "ViewController.h"
#import "TableViewController.h"
#import "Chameleon.h"
#import <Social/Social.h>
#import "STTwitter.h"
#import "WebViewVC.h"
#import <Accounts/Accounts.h>
#import "Reachability.h"

#define CONSUMER_KEY @"7GjBz4QotE08eACaJMPQevCrF"
#define CONSUMER_SECRET @"82ZnuE9IcJskgNzVZnu4nDqYASdl9VkqfYsv6QgoXFHC0X0QtX"

typedef void (^accountChooserBlock_t)(ACAccount *account, NSString *errorMessage);

@interface ViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) STTwitterAPI *twitter;
@property (nonatomic, weak) STTwitterAPI *weakTwitter;
@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) accountChooserBlock_t accountChooserBlock;
@property (nonatomic, strong) NSArray *iOSAccounts;
@property (nonatomic, strong) NSArray *statuses;
@property (nonatomic, strong) ACAccount* account;

- (IBAction)goTwitter:(UIButton *)sender;


@property (nonatomic, assign) BOOL isLoginUseWeb;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithGradientStyle:UIGradientStyleTopToBottom withFrame:self.view.frame andColors: @[[UIColor flatWhiteColor], [UIColor flatWhiteColorDark]]];
    
    self.isLoginUseWeb = false;
    [self checkLoginInSettings];
}



                                                                                              
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Twitter
- (IBAction)goTwitter:(UIButton *)sender {
    if ([self currentNetworkStatus]) {
        if (self.isLoginUseWeb) {
            [self callTableView];
        } else {
            [self checkMessage:@"" message:@"Хотите использовать account по умолчанию?"];
        }
    } else {
        [self showErrorWithTitle:@"Sorry" message:@"You can't send a tweet right now, make sure your device has an internet connection"];
    }
 }

- (BOOL)checkLoginInSettings {
    [self loginWithiOSAction];
    [self reverseAuthAction];
    if (self.weakTwitter == nil) {
        return true;
    } else {
        return false;
    }
}

- (void)loginWithiOSAction {
    
    __weak typeof(self) weakSelf = self;
    self.accountChooserBlock = ^(ACAccount *account, NSString *errorMessage) {
        account  = [[ACAccount alloc] init];
        NSString *status = nil;
        if(account) {
            status = [NSString stringWithFormat:@"Did select %@", account.username];
            weakSelf.account = account;
            [weakSelf loginWithiOSAccount:account];
        } else {
            status = errorMessage;
        }
    };
    
    [self chooseAccount];
}

- (void)loginWithiOSAccount:(ACAccount *)account {
    
    self.twitter = [STTwitterAPI twitterAPIOSWithAccount:account];
    
    [_twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
        
    } errorBlock:^(NSError *error) {

    }];
    
}

- (void)loginOnTheWebAction {

    self.twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:CONSUMER_KEY
                                                 consumerSecret:CONSUMER_SECRET];
    
    [_twitter postTokenRequest:^(NSURL *url, NSString *oauthToken) {
        WebViewVC *webViewVC = [self.storyboard instantiateViewControllerWithIdentifier:@"WebViewVC"];
        
        [self presentViewController:webViewVC animated:YES completion:^{
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            [webViewVC.webView loadRequest:request];
        }];
    }
    authenticateInsteadOfAuthorize:NO
                        forceLogin:@(YES)
                        screenName:nil
                     oauthCallback:@"myappp://twitter_access_tokens/"
                        errorBlock:^(NSError *error) {
                            NSLog(@"-- error: %@", error);
                            [self showErrorWithTitle:@"Sorry" message:@"You can't send a tweet right now, make sure your device has an internet connection"];
                        }];
}

- (void)chooseAccount {
    
    static ACAccountStore* accountStore;
    static ACAccountType* accountType;
    
    accountStore = [ACAccountStore new];
    accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    __weak typeof (self) weakSelf = self;
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        __strong typeof(self) self = weakSelf;
        
        if (granted) {
            NSLog(@"Work");
            self.iOSAccounts = [accountStore accountsWithAccountType:accountType];

            if([_iOSAccounts count] == 1) {
                ACAccount *account = [_iOSAccounts lastObject];
                _accountChooserBlock(account, nil);
            } else {
                UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Select an account:"
                                                                delegate:self
                                                       cancelButtonTitle:@"Cancel"
                                                  destructiveButtonTitle:nil otherButtonTitles:nil];
                for(ACAccount *account in _iOSAccounts) {
                    [as addButtonWithTitle:[NSString stringWithFormat:@"@%@", account.username]];
                }
                [as showInView:self.view.window];
            }
        }
    }];
}

- (void)reverseAuthAction {
    
    STTwitterAPI *twitter = [STTwitterAPI twitterAPIWithOAuthConsumerName:nil consumerKey:CONSUMER_KEY consumerSecret:CONSUMER_SECRET];
    
    __weak typeof(self) weakSelf = self;
    
    [twitter postReverseOAuthTokenRequest:^(NSString *authenticationHeader) {
        
        self.accountChooserBlock = ^(ACAccount *account, NSString *errorMessage) {
            
            if(account == nil) {
                return;
            }
            
            STTwitterAPI *twitterAPIOS = [STTwitterAPI twitterAPIOSWithAccount:account];
            
            [twitterAPIOS verifyCredentialsWithSuccessBlock:^(NSString *username) {
                
                [twitterAPIOS postReverseAuthAccessTokenWithAuthenticationHeader:authenticationHeader successBlock:^(NSString *oAuthToken, NSString *oAuthTokenSecret, NSString *userID, NSString *screenName) {
                    weakSelf.twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:CONSUMER_KEY consumerSecret:CONSUMER_SECRET oauthToken:oAuthToken oauthTokenSecret:oAuthTokenSecret];
                    
                    weakSelf.account = account;
                    
                } errorBlock:^(NSError *error) {

                }];
                
            } errorBlock:^(NSError *error) {

            }];
            
        };
        
        [self chooseAccount];
        
    } errorBlock:^(NSError *error) {

    }];
}

- (void)setOAuthToken:(NSString *)token oauthVerifier:(NSString *)verifier {
    
    [self dismissViewControllerAnimated:YES completion:^{ }];
    
    [_twitter postAccessTokenRequestWithPIN:verifier successBlock:^(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName) {
        self.isLoginUseWeb = true;
    } errorBlock:^(NSError *error) {
        
    }];
}


- (void)showErrorWithTitle:(NSString *)title message:(NSString *)msg {
    UIAlertView *alertView = [[UIAlertView alloc]
                            initWithTitle:title
                            message:msg
                            delegate:nil
                            cancelButtonTitle:@"OK"
                            otherButtonTitles:nil];
    [alertView show];

}

- (void)checkMessage:(NSString *)title message:(NSString *)msg {
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:title
                              message:msg
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:@"NO",nil];
    [alertView show];
    
}

#pragma mark - Next Screen

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (([[segue identifier] isEqualToString:@"goTimeLine"]) && (self.account.username != nil)) {

        TableViewController *vc = [segue destinationViewController];
        vc.twitter = self.twitter;
        vc.account = self.account;
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    // OK
    if (buttonIndex == 0) {
        if (self.account.username != nil) {
            [self callTableView];
        }
    } else {
        [self loginOnTheWebAction];
        
    }
}

#pragma mark Call screen
-(void)callTableView{
    
    NSString * storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
    TableViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"table"];
    vc.twitter = self.twitter;
    vc.account = self.account;

    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark Internet
- (BOOL)currentNetworkStatus{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    return networkStatus != NotReachable;
}

@end
