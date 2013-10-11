//
//  ShoutTableViewCell.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 10/7/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShoutTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *shoutContentLabel;
@property (weak, nonatomic) IBOutlet UILabel *shoutUserNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *shoutAgeLabel;
@property (weak, nonatomic) IBOutlet UILabel *shoutAgeUnitLabel;
@property (weak, nonatomic) IBOutlet UIImageView *shoutImageView;
@property (weak, nonatomic) IBOutlet UIView *shoutAgeColorView;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewDropShadow;
@property (weak, nonatomic) IBOutlet UIView *shoutAgeColorSeparatorView;

@end
