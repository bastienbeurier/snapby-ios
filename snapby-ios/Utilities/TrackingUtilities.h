//
//  TrackingUtilities.h
//  snapby-ios
//
//  Created by Bastien Beurier on 1/14/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Mixpanel.h"
#import "User.h"
#import "Snapby.h"

@interface TrackingUtilities : NSObject

+ (void)identifyWithMixpanel:(User *)user isSigningUp:(BOOL)isSigningUp;

+ (void)trackCreateSnapby;

+ (void)trackAppOpened;

+ (void)trackSignUpWithSource:(NSString *)source;

+ (void)trackDisplaySnapby:(Snapby *)source withSource:(NSString *)source;

@end
