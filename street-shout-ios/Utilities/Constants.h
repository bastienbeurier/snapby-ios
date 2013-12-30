//
//  Constants.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/23/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TOKEN_VENDING_MACHINE_URL @"http://shouttvm.elasticbeanstalk.com"
#define USE_SSL NO
#define ACCESS_KEY_ID @"USED-ONLY-FOR-TESTING"  // Leave this value as is.
#define SECRET_KEY @"USED-ONLY-FOR-TESTING"  // Leave this value as is.
#define S3_URL @"street-shout1.s3.amazonaws.com/"
#define S3_BUCKET @"street-shout1"

#define UA_DEVICE_TOKEN_PROD_PREF @"UA Device Token Production"
#define UA_DEVICE_TOKEN_DEV_PREF @"UA Device Token Development"
#define NOTIFICATION_RADIUS_PREF @"Notification Radius"
#define DISTANCE_UNIT_PREF @"Distance Unit"
#define USER_NAME_PREF @"Username preference"

@interface Constants : NSObject

@end

//Shout duration in seconds
static const NSUInteger kShoutDuration = 4 * 60 * 60;
static const NSUInteger kShoutDurationHours = 4;
static const NSUInteger kShoutMaxLength = 140;
static const NSUInteger kCreateShoutDistance = 1000;
static const NSUInteger kMaxUsernameLength = 20;
static const NSUInteger kMaxShoutDescriptionLength = 140;
static const NSUInteger kShoutRadius = 300;
static const NSUInteger kShoutImageSize = 400;

static const NSUInteger kDefaultNotificationRadiusIndex = 3;

static const NSUInteger kDistanceWhenShoutClickedFromMapOrFeed = 6000;
static const NSUInteger kDistanceWhenShoutClickedFromNotif = 6000;
static const NSUInteger kDistanceWhenRedirectedFromCreateShout = 250;
static const NSUInteger kDistanceWhenMyLocationButtonClicked = 2000;
static const NSUInteger kDistanceWhenShoutZoomed = 200;
static const NSUInteger kDistanceAtStartup = 6000;

//Initialize map on Paris, with max zoom out
static const double kMapInitialLatitude = 48.856541;
static const double kMapInitialLongitude = 2.352401;
static const NSUInteger kMapInitialSpan = 180;

//Design
static const double kDropShadowX = 2.0;
static const double kDropShadowY = 2.0;

//Development
static NSString * const kDevAFStreetShoutAPIBaseURLString = @"http://dev-street-shout.herokuapp.com/";
static NSString * const kDevTestFlightAppToken = @"71154ced-9c90-4a19-9715-c74a2f8e57ee";

//Production
static NSString * const kProdTestFlightAppToken = @"fb996d52-77ad-4dd7-bdbf-e4069ea0ced5"; //Street Shout
//static NSString * const kProdTestFlightAppToken = @"6439e169-aaac-47f0-a879-206a8c7b6347" //Shout
static NSString * const kProdAFStreetShoutAPIBaseURLString = @"http://street-shout.herokuapp.com/";

static NSString * const kApiVersion = @"1.0";
