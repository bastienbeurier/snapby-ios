//
//  Constants.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/23/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PRODUCTION NO
#define TOKEN_VENDING_MACHINE_URL @"http://shouttvm.elasticbeanstalk.com"
#define USE_SSL NO
#define ACCESS_KEY_ID @"USED-ONLY-FOR-TESTING"  // Leave this value as is.
#define SECRET_KEY @"USED-ONLY-FOR-TESTING"  // Leave this value as is.
#define S3_URL @"street-shout1.s3.amazonaws.com/"
#define S3_BUCKET @"street-shout1"

@interface Constants : NSObject

@end

//Shout duration in seconds
static const NSUInteger kShoutDuration = 24 * 60 * 60;
static const NSUInteger kShoutMaxLength = 140;
static const NSUInteger kCreateShoutDistance = 1000;
static const NSUInteger kMaxUsernameLength = 20;
static const NSUInteger kMaxShoutDescriptionLength = 140;
static const NSUInteger kShoutRadius = 300;
static const NSUInteger kShoutImageSize = 400;

//Development
static NSString * const kDevAFStreetShoutAPIBaseURLString = @"http://dev-street-shout.herokuapp.com/";
static NSString * const kDevTestFlightAppToken = @"219c5385-e018-41ab-9daa-8d92e8727896";

//Production
static NSString * const kProdTestFlightAppToken = @"6439e169-aaac-47f0-a879-206a8c7b6347";
static NSString * const kProdAFStreetShoutAPIBaseURLString = @"http://street-shout.herokuapp.com/";
