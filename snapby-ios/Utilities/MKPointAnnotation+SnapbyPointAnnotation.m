//
//  MKPointAnnotation+SnapbyPointAnnotation.m
//  snapby-ios
//
//  Created by Bastien Beurier on 7/23/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "MKPointAnnotation+SnapbyPointAnnotation.h"
#import "objc/runtime.h"

NSString const * kSnapbyKey = @"kSnapbyPropertyKeyForSnapbyPointAnnotation";

@implementation MKPointAnnotation (SnapbyPointAnnotation)

@dynamic snapby;

- (void)setSnapby:(Snapby *)snapby
{
	objc_setAssociatedObject(self, &kSnapbyKey, snapby, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)snapby
{
	return objc_getAssociatedObject(self, &kSnapbyKey);
}

@end
