//
//  ProfileViewController.m
//  snapby-ios
//
//  Created by Baptiste Truchot on 3/26/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import "ProfileViewController.h"
#import "ImageUtilities.h"
#import "AFSnapbyAPIClient.h"
#import "SessionUtilities.h"
#import "GeneralUtilities.h"
#import "UIImageView+AFNetworking.h"
#import "Constants.h"
#import "SettingsViewController.h"

@interface ProfileViewController ()

@property (strong, nonatomic) User *profileUser;

@property (weak, nonatomic) IBOutlet UILabel *snapbyCount;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureView;


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

- (void)settingsButtonClicked {
    [self performSegueWithIdentifier:@"settings push segue" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;

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
        self.snapbyCount.text = [NSString stringWithFormat: @"(%ld snapby%@)", (long)user.snapbyCount, user.snapbyCount>1 ? @"s" : @""];
        self.userName.text = [NSString stringWithFormat: @"@%@", user.username];
        
        // Get the profile picture (and avoid caching)
        //TODO: Move somewhere elsewhere
        [ImageUtilities setWithoutCachingImageView:self.profilePictureView withURL:[User getUserProfilePictureURLFromUserId:self.profileUser.identifier]];
    };
    
    void (^failureBlock)() = ^() {
        //TODO handle profile did not load
    };
    
    [AFSnapbyAPIClient getOtherUserInfo:self.profileUserId success:successBlock failure:failureBlock];
}

- (void)initProfile
{
    [self.snapbyCount setText:nil];
    [self.userName setText:nil];
    
    [self.profilePictureView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [self.profilePictureView.layer setBorderWidth:2.0];
    [self.profilePictureView.layer setCornerRadius: 5.0];
}

@end
