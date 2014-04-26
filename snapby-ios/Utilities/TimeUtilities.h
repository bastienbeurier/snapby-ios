//
//  TimeUtilities.h
//  snapby-ios
//
//  Created by Bastien Beurier on 7/23/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimeUtilities : NSObject

+ (NSTimeInterval)getSnapbyAge:(NSString *)dateCreated;

+ (NSString *)ageToString:(NSTimeInterval)age;

+ (NSString *)ageToShortString:(NSTimeInterval)age;

@end
