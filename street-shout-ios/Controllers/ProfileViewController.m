//
//  ProfileViewController.m
//  street-shout-ios
//
//  Created by Baptiste Truchot on 3/26/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "ProfileViewController.h"
#import "ImageUtilities.h"
#import "AFStreetShoutAPIClient.h"
#import "SessionUtilities.h"
#import "GeneralUtilities.h"
#import "UIImageView+AFNetworking.h"
#import "UsersListViewController.h"
#import "Constants.h"
#import "SettingsViewController.h"

#define FIND_FRIENDS_TITLE NSLocalizedStringFromTable(@"find_friends", @"Strings", @"comment")
#define UNFOLLOW_TITLE NSLocalizedStringFromTable(@"unfollow", @"Strings", @"comment")
#define FOLLOW_TITLE NSLocalizedStringFromTable(@"follow", @"Strings", @"comment")

@interface ProfileViewController ()

@property (strong, nonatomic) User *profileUser;

@property (weak, nonatomic) IBOutlet UILabel *followerCount;
@property (weak, nonatomic) IBOutlet UILabel *followedCount;
@property (weak, nonatomic) IBOutlet UILabel *shoutCount;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureView;
@property (weak, nonatomic) IBOutlet UIButton *relationshipButton;


@end


@implementation ProfileViewController

- (void)viewDidLoad
{
    [self initProfile];
    [super viewDidLoad];
    
    //Nav Bar
    NSString *title = self.currentUser.identifier == self.profileUserId ? @"Me" : @"profile";
    [ImageUtilities drawCustomNavBarWithLeftItem:@"back" rightItem:@"settings" title:title sizeBig:YES inViewController:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Fill all the information
    [self getProfileInfo];
}

// ----------------------------------------------------------
// Navigation
// ----------------------------------------------------------

- (IBAction)relationshipButtonClicked:(id)sender {
    if([self.relationshipButton titleForState:UIControlStateNormal] == FIND_FRIENDS_TITLE){
        [self performSegueWithIdentifier:@"List from Profile push segue" sender:SUGGESTED_FRIENDS_LIST];
    } else {
        void (^successBlock)() = ^void(){
            [self getProfileInfo];
        };
        void (^failureBlock)() = ^void(){
            [GeneralUtilities showMessage:NSLocalizedStringFromTable(@"Try_again_message", @"Strings", @"comment") withTitle:NSLocalizedStringFromTable(@"relationship_error_title", @"Strings", @"comment")];
        };
        
        if([self.relationshipButton titleForState:UIControlStateNormal] == UNFOLLOW_TITLE) {
            [AFStreetShoutAPIClient unfollowUser:self.profileUserId success:successBlock failure:failureBlock];
        } else if([self.relationshipButton titleForState:UIControlStateNormal] == FOLLOW_TITLE) {
            [AFStreetShoutAPIClient followUser:self.profileUserId success:successBlock failure:failureBlock];
        }
    }
}

- (IBAction)followersViewClicked:(id)sender {
    [self performSegueWithIdentifier:@"List from Profile push segue" sender:FOLLOWERS_LIST];
}

- (IBAction)followingViewClicked:(id)sender {
    [self performSegueWithIdentifier:@"List from Profile push segue" sender:FOLLOWING_LIST];
}

- (void)backButtonClicked {
    [self dismissProfileController];
}

- (void)settingsButtonClicked {
    [self performSegueWithIdentifier:@"settings push segue" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"List from Profile push segue"]) {
        UsersListViewController * usersListViewController = (UsersListViewController *) [segue destinationViewController];
        usersListViewController.currentUser = self.currentUser;
        usersListViewController.profileUserId = self.profileUserId;
        usersListViewController.listType = (NSString *)sender;
    }
    if ([segueName isEqualToString: @"settings push segue"]) {
        SettingsViewController * settingsViewController = (SettingsViewController *) [segue destinationViewController];
        settingsViewController.currentUser = self.currentUser;
    }
}


// ----------------------------------------------------------
// Utilities
// ----------------------------------------------------------

// Get all profile info to display
- (void)getProfileInfo
{
    typedef void (^SuccessBlock)(User *, NSInteger, NSInteger, BOOL);
    SuccessBlock successBlock = ^(User * user, NSInteger nbFollowers, NSInteger nbFollowedUsers, BOOL isFollowedByCurrentUser)
    {
        self.profileUser = user;
        self.followerCount.text = [NSString stringWithFormat:@"%ld", (long)nbFollowers];
        self.followedCount.text = [NSString stringWithFormat:@"%ld", (long)nbFollowedUsers];
        self.shoutCount.text = [NSString stringWithFormat: @"(%ld shout%@)", (long)user.shoutCount, user.shoutCount>1 ? @"s" : @""];
        self.userName.text = [NSString stringWithFormat: @"@%@", user.username];
        [self setRelationshipButtonTitle:isFollowedByCurrentUser];
        
        // Get the profile picture (and avoid caching)
        [ImageUtilities setWithoutCachingImageView:self.profilePictureView withURL:[self.profileUser getUserProfilePictureURL]];
    };
    
    void (^failureBlock)() = ^() {
        [GeneralUtilities showMessage:NSLocalizedStringFromTable(@"user_info_error_message", @"Strings", @"comment") withTitle:nil];
        [self dismissProfileController];
    };
    
    [AFStreetShoutAPIClient getOtherUserInfo:self.profileUserId success:successBlock failure:failureBlock];
}

// Dismiss controller if not MyProfile, else go to camera screen
- (void)dismissProfileController
{
    if (self.myProfileViewControllerDelegate){
        [self.myProfileViewControllerDelegate moveToImagePickerController];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

// Set title depending on which profile is it
- (void)setRelationshipButtonTitle: (BOOL) isFollowedByCurrentUser
{
    NSString *relationshipButtonTitle;
    if(self.currentUser.identifier == self.profileUserId) {
        relationshipButtonTitle = FIND_FRIENDS_TITLE;
    } else if(isFollowedByCurrentUser) {
        relationshipButtonTitle = UNFOLLOW_TITLE;
    } else {
        relationshipButtonTitle = FOLLOW_TITLE;
    }
    [self.relationshipButton setTitle:relationshipButtonTitle forState:UIControlStateNormal];
}

- (void)initProfile
{
    [self.shoutCount setText:nil];
    [self.userName setText:nil];
    [self.followedCount setText:nil];
    [self.followerCount setText:nil];
    [self.relationshipButton setTitle:nil forState:UIControlStateNormal];
    
    [self.profilePictureView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [self.profilePictureView.layer setBorderWidth:2.0];
    [self.profilePictureView.layer setCornerRadius: 5.0];
}

@end
