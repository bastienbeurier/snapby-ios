//
//  MKPointAnnotation+ShoutPointAnnotation.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/23/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "MKPointAnnotation+ShoutPointAnnotation.h"
#import "objc/runtime.h"

NSString const * kShoutKey = @"kShoutPropertyKeyForShoutPointAnnotation";

@implementation MKPointAnnotation (ShoutPointAnnotation)

@dynamic shout;

- (void)setShout:(Shout *)shout
{
	objc_setAssociatedObject(self, &kShoutKey, shout, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)shout
{
	return objc_getAssociatedObject(self, &kShoutKey);
}

@end
