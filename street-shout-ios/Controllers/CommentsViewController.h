//
//  CommentsViewController.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/20/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Shout.h"
#import <MapKit/MapKit.h>
#import "User.h"
#import "CommentsTableViewCell.h"

@protocol CommentsVCDelegate;

@interface CommentsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, CommentsTableViewCellDelegate>

@property (nonatomic, strong) NSArray *comments;
@property (nonatomic, strong) Shout *shout;
@property (nonatomic, strong) MKUserLocation *userLocation;
@property (weak, nonatomic) id <CommentsVCDelegate> commentsVCdelegate;
@property (weak, nonatomic) User *currentUser;

@end

@protocol CommentsVCDelegate

- (void)updateCommentCount:(NSInteger)count;

@end