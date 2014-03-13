//
//  Shout.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Shout : NSObject

+ (NSArray *)rawShoutsToInstances:(NSArray *)rawShouts;
+ (Shout *)rawShoutToInstance:(id)rawShout;

@property (nonatomic) NSUInteger identifier;
@property (nonatomic) NSUInteger userId;
@property (nonatomic) double lat;
@property (nonatomic) double lng;
@property (strong, nonatomic) NSString *description;
@property (strong, nonatomic) NSString *created;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *image;
@property (nonatomic) BOOL removed;
@property (nonatomic) BOOL anonymous;

@end
