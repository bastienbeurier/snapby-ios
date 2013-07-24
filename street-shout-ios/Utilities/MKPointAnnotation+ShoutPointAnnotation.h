//
//  MKPointAnnotation+ShoutPointAnnotation.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/23/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "Shout.h"

@interface MKPointAnnotation (ShoutPointAnnotation)

@property (strong, nonatomic) Shout *shout;

@end
