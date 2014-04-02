//
//  LikesTableViewCell.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/22/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LikesTableViewCellDelegate;

@interface LikesTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *stampLabel;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureView;
@property (weak, nonatomic) id <LikesTableViewCellDelegate> likesTableViewCellDelegate;
@property (nonatomic) NSInteger likerId;

@end

@protocol LikesTableViewCellDelegate

-(void)moveToProfileOfUser:(NSInteger)userId;

@end