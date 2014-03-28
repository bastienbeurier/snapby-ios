//
//  UsersListViewController.h
//  street-shout-ios
//
//  Created by Baptiste Truchot on 3/27/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "UsersTableViewCell.h"

@interface UsersListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UsersTableViewCellDelegate>

@property (nonatomic) NSString *listType;
@property (nonatomic, weak) User *currentUser;
@property (nonatomic) NSInteger profileUserId;

@end
