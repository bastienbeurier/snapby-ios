//
//  CommentsTableViewCell.h
//  snapby-ios
//
//  Created by Bastien Beurier on 1/20/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CommentsTableViewCellDelegate;

@interface CommentsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *stampLabel;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureView;
@property (weak, nonatomic) id <CommentsTableViewCellDelegate> commentsTableViewCellDelegate;
@property (nonatomic) NSInteger commenterId;

@end

@protocol CommentsTableViewCellDelegate

-(void)moveToProfileOfUser:(NSInteger)userId;

@end