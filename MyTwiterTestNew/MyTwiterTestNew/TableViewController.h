//
//  TableViewController.h
//  MyTwitterTest
//
//  Created by Alex on 06.03.15.
//  Copyright (c) 2015 Oleksii. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STTwitter.h"

@interface TableViewController : UIViewController

@property (nonatomic, strong) STTwitterAPI *twitter;
@property (strong, nonatomic) ACAccount *account;

@end
