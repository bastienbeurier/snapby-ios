//
//  GeneralUtilities.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 8/14/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GeneralUtilities : NSObject

+ (NSString *)getDeviceID;

+ (NSUInteger)currentDateInMilliseconds;

+ (NSString *)getUADeviceToken;

@end
