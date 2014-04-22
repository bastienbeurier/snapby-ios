//
//  CommentsTableViewCell.m
//  snapby-ios
//
//  Created by Bastien Beurier on 1/20/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import "CommentsTableViewCell.h"

@implementation CommentsTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    return;
}

- (IBAction)usernameClicked:(id)sender {
    if(self.commenterId && self.commentsTableViewCellDelegate) {
        [self.commentsTableViewCellDelegate moveToProfileOfUser:self.commenterId];
    }
}

@end
