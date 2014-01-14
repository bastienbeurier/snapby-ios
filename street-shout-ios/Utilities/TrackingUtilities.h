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

+ (void)identifyWithMixpanel:(User *)user;

+ (void)trackCreateShoutImage:(BOOL)image textLength:(NSUInteger)length;

@end
