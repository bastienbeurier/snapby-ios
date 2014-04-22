//
//  Constants.h
//  snapby-ios
//
//  Created by Bastien Beurier on 7/23/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import <Foundation/Foundation.h>

// iTunesConnect (must be consistent with the one in Facebook Developper) 
#define APP_ID 807530715943166

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
#define NOTIFICATION_SNAPBY_ID_PREF @"Notification snapby identifier"
#define PROFILE_PICTURE_PREF @"Profile picture preference"

#define FOLLOWERS_LIST NSLocalizedStringFromTable (@"followers", @"Strings", @"comment")
#define FOLLOWING_LIST NSLocalizedStringFromTable (@"following", @"Strings", @"comment")
#define SUGGESTED_FRIENDS_LIST NSLocalizedStringFromTable (@"suggested_friends", @"Strings", @"comment")

@interface Constants : NSObject

@end

// API Version
static NSString * const kApiVersion = @"1";

//Development
static NSString * const kDevAFSnapbyAPIBaseURLString = @"http://dev-snapby-web.herokuapp.com";
static NSString * const kDevTestFlightAppToken = @"c4904202-ba89-449a-bc2f-f53e231f1319";
static NSString * const kDevSnapbyImageBaseURL = @"http://s3.amazonaws.com/snapby_development/original/image_";
static NSString * const kDevSnapbyThumbBaseURL = @"http://s3.amazonaws.com/snapby_development/small/image_";
static NSString * const kDevProfilePicsBaseURL = @"http://s3.amazonaws.com/snapby_profile_pics_dev/thumb/profile_";
static NSString * const kDevBigProfilePicsBaseURL = @"http://s3.amazonaws.com/snapby_profile_pics_dev/original/profile_";

//Production
static NSString * const kProdTestFlightAppToken = @"fb996d52-77ad-4dd7-bdbf-e4069ea0ced5";
static NSString * const kProdAFSnapbyAPIBaseURLString = @"http://snapby-web.herokuapp.com/";
static NSString * const kProdSnapbyBaseURLString = @"http://www.snapby.co/";
static NSString * const kProdSnapbyImageBaseURL = @"http://s3.amazonaws.com/snapby_production/original/image_";
static NSString * const kProdSnapbyThumbBaseURL = @"http://s3.amazonaws.com/snapby_production/small/image_";
static NSString * const kProdProfilePicsBaseURL = @"http://s3.amazonaws.com/snapby_profile_pics/thumb/profile_";
static NSString * const kProdBigProfilePicsBaseURL = @"http://s3.amazonaws.com/snapby_profile_pics/original/profile_";


//Snapby duration in seconds
static const NSUInteger kSnapbyDuration = 4 * 60 * 60;
static const NSUInteger kSnapbyDurationHours = 4;
static const NSUInteger kSnapbyMaxLength = 140;
static const NSUInteger kMaxUsernameLength = 20;
static const NSUInteger kMaxSnapbyDescriptionLength = 140;
static const NSUInteger kSnapbyRadius = 300;
static const NSUInteger kSnapbyImageHeight = 600;

static const NSUInteger kDistanceAtStartup = 600;

static const NSUInteger kDistanceBeforeUpdateLocation = 50;

static const NSUInteger kCameraHeight = 426;
static const NSUInteger kCellProfilePictureSize = 50;

//Design
static const double kDropShadowX = 2.0;
static const double kDropShadowY = 2.0;

//Snapby annotation
static const double kSnapbyAnnotationOffsetX = 0;
static const double kSnapbyAnnotationOffsetY = 0;

//Mixpanel token
static NSString * const kProdMixPanelToken = @"781f8a3090780f2afbb8a260a58911c4";
static NSString * const kDevMixPanelToken = @"293023eb15e4681ca1aa4c81d3a6ce19";

