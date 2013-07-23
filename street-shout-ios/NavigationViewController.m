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

@interface NavigationViewController ()

@property (nonatomic, weak) FeedTVC *feedTVC;

@property (nonatomic, weak) MapViewController *mapViewController;

@end

@implementation NavigationViewController

- (void)pullShoutsInZone:(NSArray *)mapBounds
{
    self.feedTVC.shouts = @[];
    [self.feedTVC.activityIndicator startAnimating];
    [MapRequestHandler pullShoutsInZone:mapBounds AndExecute:^(NSArray *shouts) {
        [self.feedTVC.activityIndicator stopAnimating];
        self.mapViewController.shouts = shouts;
        self.feedTVC.shouts = shouts;
    }];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"mapViewController"]) {
        self.mapViewController = (MapViewController *) [segue destinationViewController];
        self.mapViewController.mapVCdelegate = self;
    }
    
    if ([segueName isEqualToString: @"feedTVC"]) {
        self.feedTVC = (FeedTVC *) [(UINavigationController *)[segue destinationViewController] viewControllers][0];
    }
}

@end
