//
//  TrackingUtilities.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/14/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "TrackingUtilities.h"

@implementation TrackingUtilities

+ (void)identifyWithMixpanel:(User *)user
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel identify:[NSString stringWithFormat:@"%d", user.identifier]];
    
    [mixpanel.people set:@{@"Name": user.username, @"Email": user.email}];
    [mixpanel.people increment:@"Sign in count" by:[NSNumber numberWithInt:1]];
}

+ (void)trackCreateShoutImage:(BOOL)image textLength:(NSUInteger)length
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    NSString *imageParam = nil;
    if (image) {
        imageParam = @"Yes";
    } else {
        imageParam = @"No";
    }
        
    [mixpanel track:@"Create shout" properties:@{@"Image": imageParam, @"textLength": [NSNumber numberWithInt:length]}];
    
    [mixpanel.people increment:@"Create shout count" by:[NSNumber numberWithInt:1]];
}

@end
