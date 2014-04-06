//
//  UsersTableViewCell.m
//  street-shout-ios
//
//  Created by Baptiste Truchot on 3/27/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "UsersTableViewCell.h"
#import "AFStreetShoutAPIClient.h"
#import "GeneralUtilities.h"

@implementation UsersTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    return; // to avoid the cell to stay selected
}

- (IBAction)followButtonClicked:(id)sender {
    if(!self.userId) {
        return;
    }
    void (^successBlock)() = ^void(){
        [self changeFollowButtonTitle];
    };
    void (^failureBlock)() = ^void(){
        [GeneralUtilities showMessage:NSLocalizedStringFromTable(@"Try_again_message", @"Strings", @"comment") withTitle:NSLocalizedStringFromTable(@"relationship_error_title", @"Strings", @"comment")];
    };
    
    if([self.followButton titleForState:UIControlStateNormal] == NSLocalizedStringFromTable(@"follow", @"Strings", @"comment")) {
        [AFStreetShoutAPIClient followUser:self.userId success:successBlock failure:failureBlock];
    } else if([self.followButton titleForState:UIControlStateNormal] == NSLocalizedStringFromTable(@"unfollow", @"Strings", @"comment")) {
        [AFStreetShoutAPIClient unfollowUser:self.userId success:successBlock failure:failureBlock];
    }
}

- (IBAction)usernameClicked:(id)sender {
    if(self.userId && self.usersTableViewCellDelegate) {
        [self.usersTableViewCellDelegate moveToProfileOfUser:self.userId];
    }
}

- (void)changeFollowButtonTitle
{
    if([self.followButton titleForState:UIControlStateNormal] == NSLocalizedStringFromTable(@"follow", @"Strings", @"comment")) {
        [self.followButton setTitle:NSLocalizedStringFromTable(@"unfollow", @"Strings", @"comment") forState:UIControlStateNormal];
    } else if([self.followButton titleForState:UIControlStateNormal] == NSLocalizedStringFromTable(@"unfollow", @"Strings", @"comment")) {
        [self.followButton setTitle:NSLocalizedStringFromTable(@"follow", @"Strings", @"comment") forState:UIControlStateNormal];
    }
}

@end
