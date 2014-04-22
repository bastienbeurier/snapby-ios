//
//  MapRequestHandler.m
//  snapby-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "MapRequestHandler.h"
#import "AFSnapbyAPIClient.h"
#import "Constants.h"


@interface MapRequestHandler()

@property (strong) NSTimer *timer;
@property (strong) NSDate *lastRequestDate;

@end


@implementation MapRequestHandler

- (void)addMapRequest:(NSArray *)cornersCoordinates AndExecuteSuccess:(void(^)(NSArray *snapbies))successBlock failure:(void(^)())failureBlock
{
    // Delay for opening (the user is not yet navigating)
    NSTimeInterval requestDelay = 0;
    
    if (self.timer){
        [self.timer invalidate];
        self.timer = nil;
        
        // Delay for navigation
        requestDelay = kRequestDelay;
    }

    NSDate *thisRequestDate = [NSDate date];
    self.lastRequestDate = thisRequestDate;
    
    NSDictionary *parameters = @{@"cornersCoordinates": cornersCoordinates,
                                @"successBlock": successBlock,
                                @"failureBlock": failureBlock,
                                 @"thisRequestDate": thisRequestDate};
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:requestDelay
                                             target:self
                                           selector:@selector(timerFired:)
                                           userInfo:parameters
                                            repeats:NO];
}
             
- (void)timerFired:(NSTimer *)timer
{
    NSDictionary *parameters = [timer userInfo];
    
    NSArray *cornersCoordinates = [parameters valueForKeyPath:@"cornersCoordinates"];
    void(^successBlock)(NSArray *snapbies) = [parameters valueForKeyPath:@"successBlock"];
    void(^failureBlock)() = [parameters valueForKeyPath:@"failureBlock"];
    NSDate *thisRequestDate = [parameters valueForKeyPath:@"thisRequestDate"];

    // We check that the request is the last one before sending
    void (^checkRequestandExecuteSuccess)(NSArray*) = ^(NSArray *snapbies){
        if (thisRequestDate == self.lastRequestDate) {
            successBlock(snapbies);
        }
    };
    
    [AFSnapbyAPIClient pullSnapbiesInZone:cornersCoordinates AndExecuteSuccess:checkRequestandExecuteSuccess failure:failureBlock];
}

@end
