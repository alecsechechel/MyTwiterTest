//
//  WebViewVC.m
//  STTwitterDemoIOS
//
//  Created by Nicolas Seriot on 06/08/14.
//  Copyright (c) 2014 Nicolas Seriot. All rights reserved.
//

#import "WebViewVC.h"

@interface WebViewVC ()

@end

@implementation WebViewVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

@end
