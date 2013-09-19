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

+ (NSString *)shoutAgeToString:(NSTimeInterval)age
{
    if (age > 0) {
        NSUInteger hours = ((NSUInteger)age) / ONE_HOUR;
        if (hours > 1) {
            NSString *result = [NSString stringWithFormat:@"%d %@", hours, NSLocalizedStringFromTable (@"hours_ago", @"Strings", @"comment")];
            if (age > kShoutDuration) {
                return [result stringByAppendingString:NSLocalizedStringFromTable (@"shout_expired", @"Strings", @"comment")];
            }
            return result;
        } else if (hours == 1) {
            return [NSString stringWithFormat:@"%d %@", hours, NSLocalizedStringFromTable (@"hour_ago", @"Strings", @"comment")];
        } else {
            NSUInteger minutes = ((NSUInteger)age) / ONE_MINUTE;
            if (minutes > 1) {
                return [NSString stringWithFormat:@"%d %@", minutes, NSLocalizedStringFromTable (@"minutes_ago", @"Strings", @"comment")];;
            } else if (minutes == 1) {
                return [NSString stringWithFormat:@"%d %@", minutes, NSLocalizedStringFromTable (@"minute_ago", @"Strings", @"comment")];;
            } else {
                return NSLocalizedStringFromTable (@"just_now", @"Strings", @"comment");
            }
        }
        
    } else {
        return NSLocalizedStringFromTable (@"just_now", @"Strings", @"comment");
    }
}

@end
