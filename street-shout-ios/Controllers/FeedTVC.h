//
//  FeedTVC.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/19/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FeedTVC : UITableViewController

@property (nonatomic, strong) NSArray *shouts;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
