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

// iTunesConnect (must be consistent with the one in Facebook Developper) 
#define APP_ID 734887535

#define UA_DEVICE_TOKEN_PROD_PREF @"UA Device Token Production"
#define UA_DEVICE_TOKEN_DEV_PREF @"UA Device Token Development"
#define DISTANCE_UNIT_PREF @"Distance Unit"
#define USER_NAME_PREF @"Username preference"
#define USER_EMAIL_PREF @"User model email preference"
#define USER_ID_PREF @"User model id preference"
#define USERNAME_PREF @"User model username preference"
#define USER_CONNECT_PREF @"FB connect preference"
#define USER_AUTH_TOKEN_PREF @"User authentication token preference"
#define USER_BLACKLISTED @"Is user blacklisted?"

@interface Constants : NSObject

@end

// API Version
static NSString * const kApiVersion = @"2";

//Development
static NSString * const kDevAFStreetShoutAPIBaseURLString = @"http://dev-street-shout.herokuapp.com/";
static NSString * const kDevTestFlightAppToken = @"c4904202-ba89-449a-bc2f-f53e231f1319";

//Production
static NSString * const kProdTestFlightAppToken = @"6439e169-aaac-47f0-a879-206a8c7b6347";
static NSString * const kProdAFStreetShoutAPIBaseURLString = @"http://street-shout.herokuapp.com/";
static NSString * const kProdShoutBaseURLString = @"http://shouthereandnow.com/";

//Shout duration in seconds
static const NSUInteger kShoutDuration = 4 * 60 * 60;
static const NSUInteger kShoutDurationHours = 4;
static const NSUInteger kShoutMaxLength = 140;
static const NSUInteger kMaxUsernameLength = 20;
static const NSUInteger kMaxShoutDescriptionLength = 140;
static const NSUInteger kShoutRadius = 300;
static const NSUInteger kShoutImageSize = 400;

static const NSUInteger kDistanceWhenRedirectedFromCreateShout = 250;
static const NSUInteger kDistanceWhenMyLocationButtonClicked = 2000;
static const NSUInteger kDistanceWhenDisplayShout = 200;
static const NSUInteger kDistanceAtStartup = 6000;

//Initialize map on Paris, with max zoom out
static const double kMapInitialLatitude = 48.856541;
static const double kMapInitialLongitude = 2.352401;
static const NSUInteger kMapInitialSpan = 180;

//Design
static const double kDropShadowX = 2.0;
static const double kDropShadowY = 2.0;

//Mixpanel token
static NSString * const kProdMixPanelToken = @"24dc482a232028564063bd3dd7e84e93";
static NSString * const kDevMixPanelToken = @"468e53159f354365149b1a46a7ecdec3";

