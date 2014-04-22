//
//  MapRequestHandler.h
//  snapby-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MapRequestHandler : NSObject

- (void)addMapRequest:(NSArray *)cornersCoordinates AndExecuteSuccess:(void(^)(NSArray *snapbies))successBlock failure:(void(^)())failureBlock;


@end
