//
//  AFStreetShoutAPIClient.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "AFStreetShoutAPIClient.h"
#import "AFJSONRequestOperation.h"

static NSString * const kAFStreetShoutAPIBaseURLString = @"http://street-shout.herokuapp.com/";

@implementation AFStreetShoutAPIClient

+ (AFStreetShoutAPIClient *)sharedClient {
    static AFStreetShoutAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[AFStreetShoutAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kAFStreetShoutAPIBaseURLString]];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

+ (void)pullShoutsInZone {
    //TODO: change endpoint
    [[AFStreetShoutAPIClient sharedClient] getPath:@"global_feed_shouts" parameters:nil success:^(AFHTTPRequestOperation *operation, id JSON) {
        NSLog(@"Json response: %@", (NSString *) JSON);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"ERROR!!!");
        //TODO: implement
    }];
}

@end
