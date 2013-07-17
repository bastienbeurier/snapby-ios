//
//  MapRequestHandler.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "MapRequestHandler.h"
#import "AFStreetShoutAPIClient.h"

@implementation MapRequestHandler

+ (void)pullShoutsInZone {
    [AFStreetShoutAPIClient pullShoutsInZone];
}

@end
