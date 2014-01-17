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
    
    CATransition* transition = [CATransition animation];
    
    transition.duration = 0.3;
    transition.type = kCATransitionFade;
    
    [source.navigationController.view.layer addAnimation:transition forKey:kCATransition];
    [source.navigationController pushViewController:destination animated:NO];
}

@end
