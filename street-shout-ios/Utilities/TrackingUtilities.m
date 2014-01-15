//
//  TrackingUtilities.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/14/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "TrackingUtilities.h"
#import "SessionUtilities.h"
#import "Shout.h"

@implementation TrackingUtilities

+ (void)identifyWithMixpanel:(User *)user isSigningUp:(BOOL)isSigningUp
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    //Alias to merge mixpanel people id before signup and street shout id after sign up
    if (isSigningUp) {
        [mixpanel createAlias:[NSString stringWithFormat:@"%d", user.identifier] forDistinctID:mixpanel.distinctId];
    }
    
    [mixpanel identify:[NSString stringWithFormat:@"%d", user.identifier]];
    
    [mixpanel.people set:@{@"Name": user.username, @"Email": user.email}];
}

+ (void)trackCreateShoutImage:(BOOL)image textLength:(NSUInteger)length
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    NSString *imageParam = image ? @"Yes" : @"No";
        
    [mixpanel track:@"Create shout" properties:@{@"Image": imageParam, @"Text length": [NSNumber numberWithInt:length]}];
    
    [mixpanel.people increment:@"Create shout count" by:[NSNumber numberWithInt:1]];
}

+ (void)trackAppOpened
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    NSString *loggedInParam = [SessionUtilities loggedIn] ? @"Yes" : @"No";
    
    [mixpanel track:@"Open app" properties:@{@"Signed in": loggedInParam}];
    
    [mixpanel.people increment:@"Open app count" by:[NSNumber numberWithInt:1]];
}

+ (void)trackSignUpWithSource:(NSString *)source
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel track:@"Sign up" properties:@{@"Source": source}];
}

+ (void)trackDisplayShout:(Shout *)shout withSource:(NSString *)source
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    NSString *imageParam = shout.image ? @"Yes" : @"No";
    
    [mixpanel track:@"Display shout" properties:@{@"Source": source, @"Image": imageParam}];
    
    [mixpanel.people increment:@"Display shout count" by:[NSNumber numberWithInt:1]];
}

@end
