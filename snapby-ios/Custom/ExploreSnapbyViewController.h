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
- (void)updateCommentCount:(NSUInteger)count;
- (void)userDidComment;
- (void)snapbyCommentedOnOtherController:(NSUInteger)commentCount;
- (void)snapbyLikedOnOtherController;
- (void)snapbyUnlikedOnOtherController;


@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) id <ExploreSnapbyVCDelegate> exploreSnapbyVCDelegate;

@end

@protocol ExploreSnapbyVCDelegate

- (void)moreButtonClicked:(Snapby *)snapby;
- (BOOL)snapbyHasBeenLiked:(NSUInteger)snapbyId;
- (void)onSnapbyLiked:(Snapby *)snapby;
- (void)onSnapbyUnliked:(Snapby *)snapby;
- (BOOL)isSnapbyCommented:(NSUInteger)snapbyId;
- (void)commentButtonClicked:(Snapby *)snapby;

@end

