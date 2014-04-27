//
//  ExploreSnapbyViewController.h
//  snapby-ios
//
//  Created by Bastien Beurier on 4/21/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Snapby.h"

@protocol ProfileSnapbyVCDelegate;

@interface ProfileSnapbyViewController : UIViewController

- (id)initWithSnapby:(Snapby *)snapby;
- (void)snapbyDisplayed;
- (void)snapbyDismissed;

@property (weak, nonatomic) id <ProfileSnapbyVCDelegate> profileSnapbyVCDelegate;

@end

@protocol ProfileSnapbyVCDelegate

- (void)moreButtonClicked:(Snapby *)snapby;

@end

