//
//  TrackingUtilities.m
//  snapby-ios
//
//  Created by Bastien Beurier on 1/14/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import "TrackingUtilities.h"
#import "SessionUtilities.h"
#import "Snapby.h"

@implementation TrackingUtilities

+ (void)identifyWithMixpanel:(User *)user isSigningUp:(BOOL)isSigningUp
{
    if(!PRODUCTION)
        return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    //Alias to merge mixpanel people id before signup and snapby id after sign up
    if (isSigningUp) {
        [mixpanel createAlias:[NSString stringWithFormat:@"%lu", (unsigned long)user.identifier] forDistinctID:mixpanel.distinctId];
    }
    
    [mixpanel identify:[NSString stringWithFormat:@"%lu", (unsigned long)user.identifier]];
    
    [mixpanel.people set:@{@"Username": user.username, @"Email": user.email}];
}

+ (void)trackCreateSnapby
{
    if(!PRODUCTION)
        return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    [mixpanel track:@"Create snapby"];
    
    [mixpanel.people increment:@"Create snapby count" by:[NSNumber numberWithInt:1]];
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

+ (void)trackDisplaySnapby:(Snapby *)snapby withSource:(NSString *)source
{
    if(!PRODUCTION)
        return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
//    NSString *imageParam = snapby.image ? @"Yes" : @"No";
    
//    [mixpanel track:@"Display snapby" properties:@{@"Source": source, @"Image": imageParam}];
    
    [mixpanel.people increment:@"Display snapby count" by:[NSNumber numberWithInt:1]];
}

@end
