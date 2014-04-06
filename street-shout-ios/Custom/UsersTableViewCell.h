//
//  UsersTableViewCell.h
//  street-shout-ios
//
//  Created by Baptiste Truchot on 3/27/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UsersTableViewCellDelegate;

@interface UsersTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *profileThumb;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UIButton *followButton;
@property (weak, nonatomic) IBOutlet UILabel *shoutCountLabel;
@property (nonatomic) NSInteger userId;
@property (weak, nonatomic) id <UsersTableViewCellDelegate> usersTableViewCellDelegate;

@end

@protocol UsersTableViewCellDelegate

-(void)moveToProfileOfUser:(NSInteger)userId;

@end
