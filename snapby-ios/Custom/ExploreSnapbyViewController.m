//
//  ExploreSnapbyViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 4/21/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import "ExploreSnapbyViewController.h"
#import "UIImageView+AFNetworking.h"
#import "Snapby.h"
#import "User.h"
#import "TimeUtilities.h"

@interface ExploreSnapbyViewController ()

@property (nonatomic, strong) Snapby *snapby;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeStamp;
@property (weak, nonatomic) IBOutlet UIView *infoContainer;
@property (weak, nonatomic) IBOutlet UIImageView *likeIcon;
@property (weak, nonatomic) IBOutlet UILabel *likeCount;
@property (weak, nonatomic) IBOutlet UIImageView *commentIcon;
@property (weak, nonatomic) IBOutlet UILabel *commentCount;
@property (weak, nonatomic) IBOutlet UIView *actionsContainer;
@property (weak, nonatomic) IBOutlet UIImageView *moreIcon;



@end

@implementation ExploreSnapbyViewController

- (id)initWithSnapby:(Snapby *)snapby
{
    if (self = [super initWithNibName:@"ExploreSnapby" bundle:nil])
    {
        self.snapby = snapby;
    }
    return self;
}

- (void)viewDidLoad
{
    self.likeCount.text = @"";
    self.commentCount.text = @"";
    self.usernameLabel.text = @"";
    self.timeStamp.text = @"";
    
    [self.profileImage.layer setCornerRadius:15.0f];
    
    [self outerGlow:self.usernameLabel];
    [self outerGlow:self.timeStamp];
    [self outerGlow:self.likeCount];
    [self outerGlow:self.commentCount];
    [self outerGlow:self.likeIcon];
    [self outerGlow:self.commentIcon];
    [self outerGlow:self.moreIcon];
    
    self.imageView.clipsToBounds = YES;
    [self.imageView setImageWithURL:[self.snapby getSnapbyThumbURL] placeholderImage:nil];
    
    if (!self.snapby.anonymous) {
        [self.profileImage setImageWithURL:[User getUserProfilePictureURLFromUserId:self.snapby.userId]];
        self.usernameLabel.text = [NSString stringWithFormat:@"%@ (%lu)", self.snapby.username, self.snapby.userScore];
    } else {
        self.usernameLabel.text = @"Anonymous";
    }
    
    NSString *snapbyCreated = [TimeUtilities ageToShortString:[TimeUtilities getSnapbyAge:self.snapby.created]];
    NSString *snapbyActive = [TimeUtilities ageToShortString:[TimeUtilities getSnapbyAge:self.snapby.lastActive]];
    
    if (self.snapby.commentCount == 0 && self.snapby.likeCount == 0) {
        self.timeStamp.text = [NSString stringWithFormat:@"%@", snapbyCreated];
    } else {
        self.timeStamp.text = [NSString stringWithFormat:@"%@ (active: %@)", snapbyCreated, snapbyActive];
    }
    
    self.likeCount.text = [NSString stringWithFormat:@"%lu", self.snapby.likeCount];
    self.commentCount.text = [NSString stringWithFormat:@"%lu", self.snapby.commentCount];
}

- (void)outerGlow:(UIView *)view
{
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    view.layer.shadowRadius = 1;
    view.layer.shadowOpacity = 0.9;
    view.layer.masksToBounds = NO;
}

- (void)snapbyDisplayed
{
    self.infoContainer.hidden = NO;
    self.actionsContainer.hidden = NO;
}

- (void)snapbyDismissed
{
    self.infoContainer.hidden = YES;
    self.actionsContainer.hidden = YES;
}
@end
