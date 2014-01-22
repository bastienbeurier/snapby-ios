//
//  ShoutLabel.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/20/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "ShoutLabel.h"

@implementation ShoutLabel

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, UIEdgeInsetsMake(0, 5, 0, 5))];
}

@end
