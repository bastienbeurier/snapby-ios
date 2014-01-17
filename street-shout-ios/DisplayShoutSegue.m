//
//  DisplayShoutSegue.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/17/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "DisplayShoutSegue.h"

@implementation DisplayShoutSegue

- (void)perform
{
    UIViewController *source = self.sourceViewController;
    UIViewController *destination = self.destinationViewController;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    
    destination.view.frame = CGRectMake(0, source.view.frame.size.height, source.view.frame.size.width, screenHeight - 100);
    
    [source.view addSubview:destination.view];
    
    // perform animation here
    [UIView animateWithDuration:0.5 animations:^{
        destination.view.frame = CGRectMake(0, 0, source.view.frame.size.width, screenHeight - 100);
    } completion:^(BOOL finished) {
        [source.navigationController pushViewController:destination animated:NO];
    }];
}

@end
