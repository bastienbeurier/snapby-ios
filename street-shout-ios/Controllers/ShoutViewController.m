//
//  ShoutViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/23/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "ShoutViewController.h"
#import "Shout.h"
#import "TimeUtilities.h"

@interface ShoutViewController ()

@property (strong, nonatomic) Shout *shout;
@property (weak, nonatomic) IBOutlet UILabel *shoutUsername;
@property (weak, nonatomic) IBOutlet UILabel *shoutContent;
@property (weak, nonatomic) IBOutlet UILabel *shoutStamp;

@end

@implementation ShoutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateUI];
}

- (void)setShout:(Shout *)shout
{
    _shout = shout;
    [self updateUI];
}

- (void)updateUI
{
    if (self.shout) {
        self.shoutUsername.text = self.shout.displayName;
        self.shoutContent.text = self.shout.description;
        self.shoutStamp.text = [TimeUtilities shoutAgeToString:[TimeUtilities getShoutAge:self.shout.created]];
    }
}

@end
