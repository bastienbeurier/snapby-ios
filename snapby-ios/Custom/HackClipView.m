//
//  HackClipView.m
//  snapby-ios
//
//  Created by Bastien Beurier on 4/21/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import "HackClipView.h"

@implementation HackClipView

-(UIView *) hitTest:(CGPoint) point withEvent:(UIEvent *)event
{
    UIView* child = [super hitTest:point withEvent:event];
    if (child == self && self.subviews.count > 0)
    {
        return self.subviews[0];
    }
    return child;
}

@end
