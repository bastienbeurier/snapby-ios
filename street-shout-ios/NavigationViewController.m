//
//  NavigationViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/16/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "NavigationViewController.h"
#import "MapRequestHandler.h"
#import "LocationUtilities.h"
#import "Shout.h"
#import "FeedTVC.h"
#import "ShoutViewController.h"

@interface NavigationViewController ()

@property (nonatomic, weak) UINavigationController *navigationController;
@property (nonatomic, weak) FeedTVC *feedTVC;
@property (nonatomic, weak) MapViewController *mapViewController;

@end

@implementation NavigationViewController 

- (void)pullShoutsInZone:(NSArray *)mapBounds
{
    self.feedTVC.shouts = @[];
    [self.feedTVC.activityIndicator startAnimating];
    
    [MapRequestHandler pullShoutsInZone:mapBounds AndExecute:^(NSArray *shouts) {
        self.mapViewController.shouts = shouts;
        [self.feedTVC.activityIndicator stopAnimating];
        self.feedTVC.shouts = shouts;
    }];
}

- (void)shoutSelectedOnMap:(Shout *)shout
{
    if ([[self.navigationController topViewController] isKindOfClass:[ShoutViewController class]]) {
        ((ShoutViewController *)[self.navigationController topViewController]).shout = shout;
    } else {
        [self.feedTVC performSegueWithIdentifier:@"Show Shout" sender:shout];
    }
}

- (void)shoutDeselectedOnMap
{
    if ([[self.navigationController topViewController] isKindOfClass:[ShoutViewController class]]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)shoutSelectedInFeed:(Shout *)shout
{
    self.mapViewController.preventShoutDeselection = YES;
    [self.mapViewController animateMapToLatitude:shout.lat Longitude:shout.lng WithDistance:1000];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"mapViewController"]) {
        self.mapViewController = (MapViewController *) [segue destinationViewController];
        self.mapViewController.mapVCdelegate = self;
    }
    
    if ([segueName isEqualToString: @"navigationController"]) {
        self.navigationController = (UINavigationController *)[segue destinationViewController];
        self.feedTVC = (FeedTVC *) [self.navigationController topViewController];
        self.feedTVC.feedTVCdelegate = self;
    }
}

@end
