//
//  ExploreSnapbyViewController.h
//  snapby-ios
//
//  Created by Bastien Beurier on 4/21/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Snapby.h"

@protocol ExploreSnapbyVCDelegate;

@interface ExploreSnapbyViewController : UIViewController

- (id)initWithSnapby:(Snapby *)snapby;
- (void)snapbyDisplayed;
- (void)snapbyDismissed;

@property (weak, nonatomic) id <ExploreSnapbyVCDelegate> exploreSnapbyVCDelegate;

@end

@protocol ExploreSnapbyVCDelegate

- (void)moreButtonClicked:(Snapby *)snapby;

@end

