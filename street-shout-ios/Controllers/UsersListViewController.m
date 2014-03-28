//
//  UsersListViewController.m
//  street-shout-ios
//
//  Created by Baptiste Truchot on 3/27/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "UsersListViewController.h"
#import "ImageUtilities.h"
#import "AFStreetShoutAPIClient.h"
#import "Constants.h"
#import "UsersTableViewCell.h"
#import "LocationUtilities.h"
#import "UIImageView+AFNetworking.h"
#import "ProfileViewController.h"

#define NO_USERS_TAG @"No users"
#define LOADING_TAG @"Loading"
#define NO_CONNECTION_TAG @"No connection"
#define PROFILE_PIC_SIZE 50


@interface UsersListViewController ()

@property (nonatomic, strong) NSArray *users;
@property (nonatomic, strong) NSArray *currentUserFollowedIds;
@property (weak, nonatomic) IBOutlet UITableView *usersTableView;
@property (strong, nonatomic) UIActivityIndicatorView *activityView;

@end

@implementation UsersListViewController


- (void)viewDidLoad
{
    if (!self.listType){
        [[self navigationController] popViewControllerAnimated:YES];
    }
    self.usersTableView.delegate = self;
    self.usersTableView.dataSource = self;
    
    //Nav Bar
    [ImageUtilities drawCustomNavBarWithLeftItem:@"back" rightItem:nil title:self.listType sizeBig:YES inViewController:self];
    
    if (!self.activityView) {
        self.activityView= [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    
    //Fill Table View
    self.activityView.center = CGPointMake(160, 50);
    
    [self.activityView startAnimating];
    
    [self.usersTableView addSubview:self.activityView];
    
    self.users = @[LOADING_TAG];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Get list of friends
    [self getFriendsList];
}


// ----------------------------------------------------------
// Navigation
// ----------------------------------------------------------

- (void)backButtonClicked
{
    [[self navigationController] popViewControllerAnimated:YES];
}


// ----------------------------------------------------------
// Utilities
// ----------------------------------------------------------

- (void)getFriendsList
{
    void(^successBlock)(NSArray *, NSArray *) = ^ (NSArray *users, NSArray *currentUserFollowedIds){
        [self.activityView stopAnimating];
        self.users = users;
        self.currentUserFollowedIds = currentUserFollowedIds;
    };
    void(^failureBlock)() = ^ {
        [self.activityView stopAnimating];
        self.users = @[NO_CONNECTION_TAG];
    };
    if(self.listType == FOLLOWERS_LIST){
        [AFStreetShoutAPIClient getFollowersOfUser:self.profileUserId success:successBlock failure:failureBlock];
    } else if(self.listType == FOLLOWING_LIST) {
        [AFStreetShoutAPIClient getFollowingOfUser:self.profileUserId success:successBlock failure:failureBlock];
    } else if(self.listType == SUGGESTED_FRIENDS_LIST) {
        [AFStreetShoutAPIClient getSuggestedFriendsOfUser:self.profileUserId success:successBlock failure:failureBlock];
    }
}

- (void)setUsers:(NSArray *)users
{
    if ([users count] == 0) {
        _users = @[NO_USERS_TAG];
    } else if ([users[0] isKindOfClass:[NSString class]] && [users[0] isEqualToString:LOADING_TAG]) {
        _users = @[];
    } else if ([users[0] isKindOfClass:[NSString class]] && [users[0] isEqualToString:NO_CONNECTION_TAG]) {
        _users = @[NO_CONNECTION_TAG];
    } else {
        _users = users;
    }
    
    [self.usersTableView reloadData];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.users count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self noUsersInArray:self.users]) {
        static NSString *cellIdentifier = NO_USERS_TAG;
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        return cell;
    } else if ([self errorRetrievingUsers:self.users]) {
        static NSString *cellIdentifier = NO_CONNECTION_TAG;
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        return cell;
    } else {
        static NSString *cellIdentifier = @"UsersTableViewCell";
        
        UsersTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellIdentifier owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
        
        User *user = (User *)self.users[indexPath.row];
        
        cell.userId = user.identifier;
        cell.usersTableViewCellDelegate = self;
        cell.usernameLabel.text = [NSString stringWithFormat:@"@%@",user.username];
        cell.shoutCountLabel.text = [NSString stringWithFormat:@"%ld shout%@",user.shoutCount, user.shoutCount>1 ? @"s" : @""];
        
        if (user.lat !=0 && user.lng !=0 ) {
            NSArray *distanceStrings = [LocationUtilities formattedDistanceLat1:user.lat lng1:user.lng lat2:self.currentUser.lat lng2:self.currentUser.lng];
            cell.distanceLabel.text = [NSString stringWithFormat:@"%@%@ away", [distanceStrings firstObject], [distanceStrings objectAtIndex:1]];
        }
        
        // Picture
        [cell.profileThumb setImageWithURL:[user getUserProfilePicture] placeholderImage:nil];
        cell.profileThumb.clipsToBounds = YES;
        cell.profileThumb.layer.cornerRadius = PROFILE_PIC_SIZE/2;
        
        if (indexPath.row != 0) {
            UIView *seperator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.contentView.frame.size.width, 0.3)];
            seperator.backgroundColor = [UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1];
            [cell.contentView addSubview:seperator];
        }
        
        NSString *buttonTitle;
        if(user.identifier == self.currentUser.identifier) {
            [cell.followButton setHidden:YES];
        } else if([self.currentUserFollowedIds containsObject:[NSNumber numberWithInteger:user.identifier]])
        {
            buttonTitle = NSLocalizedStringFromTable (@"unfollow", @"Strings", @"comment");
        } else {
            buttonTitle = NSLocalizedStringFromTable (@"follow", @"Strings", @"comment");
        }
        [cell.followButton setTitle:buttonTitle forState:UIControlStateNormal];
        
        return cell;
    }
}

- (BOOL)noUsersInArray:(NSArray *)users
{
    return [users count] == 1 && [users[0] isKindOfClass:[NSString class]] && [users[0] isEqualToString:NO_USERS_TAG];
}

- (BOOL)errorRetrievingUsers:(NSArray *)users
{
    return [users count] == 1 && [users[0] isKindOfClass:[NSString class]] && [users[0] isEqualToString:NO_CONNECTION_TAG];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (void)moveToProfileOfUser:(NSInteger)userId
{
    [self performSegueWithIdentifier:@"Profile from List push segue" sender:[NSNumber numberWithLong:userId]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Profile from List push segue"]) {
        ProfileViewController * usersListViewController = (ProfileViewController *) [segue destinationViewController];
        usersListViewController.currentUser = self.currentUser;
        usersListViewController.profileUserId = [(NSNumber *) sender intValue];    }
}

@end
