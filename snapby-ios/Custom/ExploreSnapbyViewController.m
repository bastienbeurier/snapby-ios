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
#import "ApiUtilities.h"
#import "GeneralUtilities.h"

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
@property (nonatomic) BOOL liked;



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
    
    if ([self.exploreSnapbyVCDelegate snapbyHasBeenLiked:self.snapby.identifier] && [self.snapby likeCount] > 0) {
        self.likeIcon.image = [UIImage imageNamed:@"snapby_liked"];
        self.liked = YES;
    } else {
        self.likeIcon.image = [UIImage imageNamed:@"snapby_like"];
        self.liked = NO;
    }
    
    if ([self.exploreSnapbyVCDelegate snapbyHasBeenCommented:self.snapby.identifier] && [self.snapby commentCount] > 0) {
        self.commentIcon.image = [UIImage imageNamed:@"snapby_commented"];
    } else {
        self.commentIcon.image = [UIImage imageNamed:@"snapby_comment"];
    }
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
    
    if (self.liked) {
        [self updateUIOnUnlike];
        
        [self.exploreSnapbyVCDelegate onSnapbyUnliked:self.snapby.identifier];
        
        [ApiUtilities removeLike:self.snapby success:nil failure:^{
            [self updateUIOnLike];
            
            [self.exploreSnapbyVCDelegate onSnapbyLiked:self.snapby.identifier];
            
            [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"unlike_failed_message", @"Strings", @"comment") withTitle:nil];
        }];
    } else {
        [self updateUIOnLike];
        
        [self.exploreSnapbyVCDelegate onSnapbyLiked:self.snapby.identifier];
        
        [ApiUtilities createLikeforSnapby:self.snapby success:nil failure:^{
            [self updateUIOnUnlike];
            
            [self.exploreSnapbyVCDelegate onSnapbyUnliked:self.snapby.identifier];
            
            [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"like_failed_message", @"Strings", @"comment") withTitle:nil];
        }];
    }
}

- (void)updateUIOnLike
{
    self.likeIcon.image = [UIImage imageNamed:@"snapby_liked"];
    self.snapby.likeCount = self.snapby.likeCount + 1;
    self.likeCount.text = [NSString stringWithFormat:@"%lu", self.snapby.likeCount];
    self.liked = YES;
}

- (void)updateUIOnUnlike
{
    self.likeIcon.image = [UIImage imageNamed:@"snapby_like"];
    self.snapby.likeCount = self.snapby.likeCount - 1;
    self.likeCount.text = [NSString stringWithFormat:@"%lu", self.snapby.likeCount];
    self.liked = NO;
}

- (IBAction)commentButtonClicked:(id)sender {
    [self.exploreSnapbyVCDelegate commentButtonClicked:self.snapby];
}

- (IBAction)moreButtonClicked:(id)sender {
    [self.exploreSnapbyVCDelegate moreButtonClicked:self.snapby];
}

- (void)updateCommentCount:(NSUInteger)count
{
    self.snapby.commentCount = count;
    self.commentCount.text = [NSString stringWithFormat:@"%lu", self.snapby.commentCount];
}

- (void)userDidComment
{
    self.commentIcon.image = [UIImage imageNamed:@"snapby_commented"];
}
@end
