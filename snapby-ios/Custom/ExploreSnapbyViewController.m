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
#import "ImageUtilities.h"
#import "MBProgressHUD.h"

@interface ExploreSnapbyViewController ()

@property (nonatomic, strong) Snapby *snapby;


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
    
    [ImageUtilities outerGlow:self.usernameLabel];
    [ImageUtilities outerGlow:self.timeStamp];
    [ImageUtilities outerGlow:self.likeCount];
    [ImageUtilities outerGlow:self.commentCount];
    [ImageUtilities outerGlow:self.likeIcon];
    [ImageUtilities outerGlow:self.commentIcon];
    [ImageUtilities outerGlow:self.moreIcon];
    
    [self.profileImage.layer setCornerRadius:20.0f];
    
    self.imageView.clipsToBounds = YES;
    

    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[self.snapby getSnapbyImageURL]];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [self.imageView setImageWithURLRequest:imageRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        self.imageView.image = image;
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        //TODO:Ask to refresh
        NSLog(@"IMAGE RESPONSE IS NEGATIVE");
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
     }];
    
    if (!self.snapby.anonymous) {
        [self.profileImage setImageWithURL:[User getUserProfilePictureURLFromUserId:self.snapby.userId]];
        self.usernameLabel.text = [NSString stringWithFormat:@"%@ (%lu)", self.snapby.username, self.snapby.userScore];
    } else {
        self.usernameLabel.text = @"Anonymous";
    }
    
    NSString *snapbyCreated = [TimeUtilities ageToShortString:[TimeUtilities getSnapbyAge:self.snapby.created]];
    NSString *snapbyActive = [TimeUtilities ageToShortString:[TimeUtilities getSnapbyAge:self.snapby.lastActive]];
    
    if (self.snapby.commentCount == 0 && self.snapby.likeCount == 0) {
        self.timeStamp.text = [NSString stringWithFormat:@"created: %@", snapbyCreated];
    } else {
        self.timeStamp.text = [NSString stringWithFormat:@"created: %@ - active: %@", snapbyCreated, snapbyActive];
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
    
    if ([self.exploreSnapbyVCDelegate isSnapbyCommented:self.snapby.identifier] && [self.snapby commentCount] > 0) {
        self.commentIcon.image = [UIImage imageNamed:@"snapby_commented"];
    } else {
        self.commentIcon.image = [UIImage imageNamed:@"snapby_comment"];
    }
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.actionsContainer.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0/256.0 green:0/256.0 blue:0/256.0 alpha:0] CGColor], (id)[[UIColor colorWithRed:0/256.0 green:0/256.0 blue:0/256.0 alpha:0.5] CGColor], nil];
    [self.actionsContainer.layer insertSublayer:gradient atIndex:0];
    
    gradient = [CAGradientLayer layer];
    gradient.frame = self.infoContainer.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0/256.0 green:0/256.0 blue:0/256.0 alpha:0.5] CGColor], (id)[[UIColor colorWithRed:0/256.0 green:0/256.0 blue:0/256.0 alpha:0] CGColor], nil];
    [self.infoContainer.layer insertSublayer:gradient atIndex:0];
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
        
        [self.exploreSnapbyVCDelegate onSnapbyUnliked:self.snapby];
        
        [ApiUtilities removeLike:self.snapby success:nil failure:^{
            [self updateUIOnLike];
            
            [self.exploreSnapbyVCDelegate onSnapbyLiked:self.snapby];
            
            [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"unlike_failed_message", @"Strings", @"comment") withTitle:nil];
        }];
    } else {
        [self updateUIOnLike];
        
        [self.exploreSnapbyVCDelegate onSnapbyLiked:self.snapby];
        
        [ApiUtilities createLikeforSnapby:self.snapby success:nil failure:^{
            [self updateUIOnUnlike];
            
            [self.exploreSnapbyVCDelegate onSnapbyUnliked:self.snapby];
            
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

- (void)snapbyCommentedOnOtherController:(NSUInteger)commentCount
{
    [self userDidComment];
    self.snapby.commentCount = commentCount;
    self.commentCount.text = [NSString stringWithFormat:@"%lu", self.snapby.commentCount];
}

- (void)snapbyLikedOnOtherController
{
    [self updateUIOnLike];
}

- (void)snapbyUnlikedOnOtherController
{
    [self updateUIOnUnlike];
}
@end
