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
#import "LocationUtilities.h"

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
        } else {
            [self.shoutImageView setHidden:YES];
        }
        
        self.shoutUsername.text = self.shout.displayName;
        self.shoutContent.text = self.shout.description;
        self.shoutStamp.text = [TimeUtilities shoutAgeToString:[TimeUtilities getShoutAge:self.shout.created]];
        
        MKUserLocation *myLocation = [self.shoutVCDelegate getMyLocation];
        
        if (myLocation && myLocation.coordinate.longitude != 0 && myLocation.coordinate.latitude != 0) {
            self.shoutStamp.text = [self.shoutStamp.text stringByAppendingFormat:@", %@", [LocationUtilities formattedDistanceLat1:myLocation.coordinate.latitude lng1:myLocation.coordinate.longitude lat2:self.shout.lat lng2:self.shout.lng]];
        }
    }
}

- (IBAction)shoutImageClicked:(UITapGestureRecognizer *)sender {    
    [self.shoutVCDelegate displayShoutImage:self.shoutImageView.image];
}

@end
