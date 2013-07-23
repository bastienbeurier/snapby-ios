//
//  TimeUtilities.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/23/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimeUtilities : NSObject

+ (NSTimeInterval)getShoutAge:(NSString *)dateCreated;

+ (NSString *)shoutAgeToString:(NSTimeInterval)age;

@end
