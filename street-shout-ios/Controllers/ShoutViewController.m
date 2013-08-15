//
//  ShoutViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/23/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "ShoutViewController.h"
#import "TimeUtilities.h"
#import "Constants.h"
#import "UIImageView+AFNetworking.h"

@interface ShoutViewController ()

@property (weak, nonatomic) IBOutlet UILabel *shoutUsername;
@property (weak, nonatomic) IBOutlet UILabel *shoutContent;
@property (weak, nonatomic) IBOutlet UILabel *shoutStamp;
@property (weak, nonatomic) IBOutlet UIImageView *shoutImageView;

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
        if (self.shout.image) {
            NSURL *url = [NSURL URLWithString:[self.shout.image stringByAppendingFormat:@"--%d", kShoutImageSize]];
            [self.shoutImageView setImageWithURL:url placeholderImage:nil];
            [self.shoutImageView setHidden:NO];
            self.shoutImageView.userInteractionEnabled = YES;
        } else {
            [self.shoutImageView setHidden:YES];
            self.shoutImageView.userInteractionEnabled = NO;
        }
        
        self.shoutUsername.text = self.shout.displayName;
        self.shoutContent.text = self.shout.description;
        self.shoutStamp.text = [TimeUtilities shoutAgeToString:[TimeUtilities getShoutAge:self.shout.created]];
    }
}

- (IBAction)shoutImageClicked:(UITapGestureRecognizer *)sender {
    NSLog(@"Is this called");
    
    [self.shoutVCDelegate displayShoutImage:self.shoutImageView.image];
}

@end
