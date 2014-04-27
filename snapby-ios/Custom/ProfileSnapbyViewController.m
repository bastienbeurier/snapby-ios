//
//  ExploreSnapbyViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 4/21/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import "ProfileSnapbyViewController.h"
#import "UIImageView+AFNetworking.h"
#import "Snapby.h"
#import "User.h"
#import "TimeUtilities.h"

@interface ProfileSnapbyViewController ()

@property (nonatomic, strong) Snapby *snapby;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeStamp;
@property (weak, nonatomic) IBOutlet UIView *infoContainer;
@property (weak, nonatomic) IBOutlet UIImageView *likeIcon;
@property (weak, nonatomic) IBOutlet UILabel *likeCount;
@property (weak, nonatomic) IBOutlet UILabel *commentCount;
@property (weak, nonatomic) IBOutlet UIView *actionsContainer;



@end

@implementation ProfileSnapbyViewController

- (id)initWithSnapby:(Snapby *)snapby
{
    if (self = [super initWithNibName:@"ProfileSnapby" bundle:nil])
    {
        self.snapby = snapby;
    }
    return self;
}

- (void)viewDidLoad
{
    [self.profileImage.layer setCornerRadius:17.5f];
    
    [self outerGlow:self.usernameLabel];
    [self outerGlow:self.timeStamp];
    [self outerGlow:self.likeCount];
    [self outerGlow:self.commentCount];
    [self outerGlow:self.likeIcon];
    
    self.imageView.clipsToBounds = YES;
    [self.imageView setImageWithURL:[self.snapby getSnapbyThumbURL] placeholderImage:nil];
    
    if (!self.snapby.anonymous) {
        [self.profileImage setImageWithURL:[User getUserProfilePictureURLFromUserId:self.snapby.userId]];
        self.usernameLabel.text = [NSString stringWithFormat:@"%@ (%lu)", self.snapby.username, self.snapby.userScore];
    } else {
        self.usernameLabel.text = self.snapby.username;
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

- (IBAction)likeButtonClicked:(id)sender {
}

- (IBAction)commentButtonClicked:(id)sender {
}

- (IBAction)moreButtonClicked:(id)sender {
    [self.profileSnapbyVCDelegate moreButtonClicked:self.snapby];
}
@end
