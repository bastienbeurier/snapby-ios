//
//  TimeUtilities.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/23/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "TimeUtilities.h"
#import "Constants.h"

#define ONE_MINUTE 60
#define ONE_HOUR (60 * ONE_MINUTE)

@implementation TimeUtilities

+ (NSTimeInterval)getShoutAge:(NSString *)dateCreated
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"Universal"]];
    NSDate *shoutDate = [dateFormatter dateFromString:dateCreated];
    return -[shoutDate timeIntervalSinceNow];
}

+ (NSArray *)ageToShortStrings:(NSTimeInterval)age
{
    if (age > 0) {
        NSUInteger hours = ((NSUInteger)age) / ONE_HOUR;
        if (hours >= 1) {
            return [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%d", hours], @"h", nil];
        } else {
            NSUInteger minutes = ((NSUInteger)age) / ONE_MINUTE;
            return [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%d", minutes], @"min", nil];
        }
        
    } else {
        return [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%d", 0], @"min", nil];
    }
}

@end
