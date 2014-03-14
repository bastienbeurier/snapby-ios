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
    if(!PRODUCTION)
        return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    //Alias to merge mixpanel people id before signup and street shout id after sign up
    if (isSigningUp) {
        [mixpanel createAlias:[NSString stringWithFormat:@"%lu", (unsigned long)user.identifier] forDistinctID:mixpanel.distinctId];
    }
    
    [mixpanel identify:[NSString stringWithFormat:@"%lu", (unsigned long)user.identifier]];
    
    [mixpanel.people set:@{@"Username": user.username, @"Email": user.email}];
}

+ (void)trackCreateShout
{
    if(!PRODUCTION)
        return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel track:@"Create shout"];
    
    [mixpanel.people increment:@"Create shout count" by:[NSNumber numberWithInt:1]];
}

+ (void)trackAppOpened
{
    if(!PRODUCTION)
        return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    NSString *signedInParam = [SessionUtilities isSignedIn] ? @"Yes" : @"No";
    
    [mixpanel track:@"Open app" properties:@{@"Signed in": signedInParam}];
    
    [mixpanel.people increment:@"Open app count" by:[NSNumber numberWithInt:1]];
}

+ (void)trackSignUpWithSource:(NSString *)source
{
    if(!PRODUCTION)
        return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel track:@"Sign up" properties:@{@"Source": source}];
}

+ (void)trackDisplayShout:(Shout *)shout withSource:(NSString *)source
{
    if(!PRODUCTION)
        return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
//    NSString *imageParam = shout.image ? @"Yes" : @"No";
    
//    [mixpanel track:@"Display shout" properties:@{@"Source": source, @"Image": imageParam}];
    
    [mixpanel.people increment:@"Display shout count" by:[NSNumber numberWithInt:1]];
}

@end
