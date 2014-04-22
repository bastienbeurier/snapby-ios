//
//  TimeUtilities.m
//  snapby-ios
//
//  Created by Bastien Beurier on 7/23/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "TimeUtilities.h"
#import "Constants.h"

#define ONE_MINUTE 60
#define ONE_HOUR (60 * ONE_MINUTE)

@implementation TimeUtilities

+ (NSTimeInterval)getSnapbyAge:(NSString *)dateCreated
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"Universal"]];
    NSDate *snapbyDate = [dateFormatter dateFromString:dateCreated];
    return -[snapbyDate timeIntervalSinceNow];
}

+ (NSArray *)ageToStrings:(NSTimeInterval)age
{
    if (age > 0) {
        NSUInteger hours = ((NSUInteger)age) / ONE_HOUR;
        if (hours > 1) {
            NSArray *result = [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%lu", (unsigned long)hours], NSLocalizedStringFromTable (@"hours", @"Strings", @"comment"), nil];
            if (age > kSnapbyDuration) {
                return [[NSArray alloc] initWithObjects:NSLocalizedStringFromTable (@"expired", @"Strings", @"comment"), nil, nil];
            }
            return result;
        } else if (hours == 1) {
            return [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%lu", (unsigned long)hours], NSLocalizedStringFromTable (@"hour", @"Strings", @"comment"), nil];
        } else {
            NSUInteger minutes = ((NSUInteger)age) / ONE_MINUTE;
            if (minutes > 1) {
                return [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%lu", (unsigned long)minutes], NSLocalizedStringFromTable (@"minutes", @"Strings", @"comment"), nil];
            } else if (minutes == 1) {
                return [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%lu", (unsigned long)minutes], NSLocalizedStringFromTable (@"minute", @"Strings", @"comment"), nil];
            } else {
                return [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%d", 0], NSLocalizedStringFromTable (@"minute", @"Strings", @"comment"), nil];
            }
        }
        
    } else {
        return [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%d", 0], NSLocalizedStringFromTable (@"minute", @"Strings", @"comment"), nil];
    }
}

+ (NSArray *)ageToShortStrings:(NSTimeInterval)age
{
    if (age > 0) {
        NSUInteger hours = ((NSUInteger)age) / ONE_HOUR;
        if (hours >= 1) {
            return [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%lu", (unsigned long)hours], @"h", nil];
        } else {
            NSUInteger minutes = ((NSUInteger)age) / ONE_MINUTE;
            return [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%lu", (unsigned long)minutes], @"min", nil];
        }
        
    } else {
        return [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%d", 0], @"min", nil];
    }
}

@end
