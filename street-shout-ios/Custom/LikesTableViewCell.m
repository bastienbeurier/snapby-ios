//
//  LikesTableViewCell.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/22/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "LikesTableViewCell.h"

@implementation LikesTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    return;
}

- (IBAction)usernameClicked:(id)sender {
    if(self.likerId && self.likesTableViewCellDelegate) {
        [self.likesTableViewCellDelegate moveToProfileOfUser:self.likerId];
    }
}

@end
