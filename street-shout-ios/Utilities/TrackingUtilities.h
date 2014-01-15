//
//  TrackingUtilities.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/14/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Mixpanel.h"
#import "User.h"

@interface TrackingUtilities : NSObject

+ (void)identifyWithMixpanel:(User *)user isSigningUp:(BOOL)isSigningUp;

+ (void)trackCreateShoutImage:(BOOL)image textLength:(NSUInteger)length;

+ (void)trackAppOpened;

+ (void)trackSignUpWithSource:(NSString *)source;

+ (void)trackDisplayShout:(Shout *)source withSource:(NSString *)source

@end
