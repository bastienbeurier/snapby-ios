//
//  LikesViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/22/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "LikesViewController.h"
#import "ImageUtilities.h"
#import "AFStreetShoutAPIClient.h"
#import "TimeUtilities.h"
#import "LocationUtilities.h"
#import "Constants.h"
#import "UIImageView+AFNetworking.h"
#import "ProfileViewController.h"

#define NO_LIKE_TAG @"No like"
#define LOADING_TAG @"Loading"
#define NO_CONNECTION_TAG @"No connection"

@interface LikesViewController ()

@property (weak, nonatomic) IBOutlet UITableView *likesTableView;
@property (strong, nonatomic) UIActivityIndicatorView *activityView;

@end

@implementation LikesViewController

- (void)viewDidLoad
{
    self.likesTableView.delegate = self;
    self.likesTableView.dataSource = self;
    
    //Nav Bar
    [ImageUtilities drawCustomNavBarWithLeftItem:@"back" rightItem:nil title:@"Likes" sizeBig:YES inViewController:self];
    
    if (!self.activityView) {
        self.activityView= [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    
    //Fill Table View
    self.activityView.center = CGPointMake(160, 50);
    
    [self.activityView startAnimating];
    
    [self.likesTableView addSubview:self.activityView];
    
    self.likes = @[LOADING_TAG];
    
    [AFStreetShoutAPIClient getLikesForShout:self.shout success:^(NSArray *likes) {
        [self.activityView stopAnimating];
        self.likes = likes;
    } failure: ^{
        [self.activityView stopAnimating];
        self.likes = @[NO_CONNECTION_TAG];
    }];
    
    [super viewDidLoad];
}

- (void)setLikes:(NSArray *)likes
{
    if ([likes count] == 0) {
        _likes = @[NO_LIKE_TAG];
    } else if ([likes[0] isKindOfClass:[NSString class]] && [likes[0] isEqualToString:LOADING_TAG]) {
        _likes = @[];
    } else if ([likes[0] isKindOfClass:[NSString class]] && [likes[0] isEqualToString:NO_CONNECTION_TAG]) {
        _likes = @[NO_CONNECTION_TAG];
    } else {
        _likes = likes;
    }
    
    [self.likesTableView reloadData];
}

- (void)backButtonClicked
{
    [[self navigationController] popViewControllerAnimated:YES];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.likes count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self noLikesInArray:self.likes]) {
        static NSString *cellIdentifier = NO_LIKE_TAG;
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        return cell;
    } else if ([self errorRetrievingLikes:self.likes]) {
        static NSString *cellIdentifier = NO_CONNECTION_TAG;
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        return cell;
    } else {
        static NSString *cellIdentifier = @"LikesTableViewCell";
        
        LikesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellIdentifier owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
        
        Like *like = (Like *)self.likes[indexPath.row];
        
        cell.likesTableViewCellDelegate = self;
        cell.likerId = like.likerId;
        cell.usernameLabel.text = [NSString stringWithFormat:@"@%@",like.likerUsername];
        
        NSArray *likeAgeStrings = [TimeUtilities ageToShortStrings:[TimeUtilities getShoutAge:like.created]];
        
        cell.stampLabel.text = [NSString stringWithFormat:@"%@%@", [likeAgeStrings firstObject], [likeAgeStrings objectAtIndex:1]];
        
        if (like.lat !=0 && like.lng !=0 ) {
            NSArray *distanceStrings = [LocationUtilities formattedDistanceLat1:like.lat lng1:like.lng lat2:self.shout.lat lng2:self.shout.lng];
            cell.stampLabel.text = [NSString stringWithFormat:@" %@ | %@%@", cell.stampLabel.text, [distanceStrings firstObject], [distanceStrings objectAtIndex:1]];
        }

        // Picture
        [cell.profilePictureView setImageWithURL:[User getUserProfilePictureURLFromUserId:like.likerId] placeholderImage:nil];
        cell.profilePictureView.clipsToBounds = YES;
        cell.profilePictureView.layer.cornerRadius = kCellProfilePictureSize/2;
        
        //separator
        if (indexPath.row != 0) {
            UIView *seperator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.contentView.frame.size.width, 0.3)];
            seperator.backgroundColor = [UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1];
            [cell.contentView addSubview:seperator];
        }
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (BOOL)noLikesInArray:(NSArray *)likes
{
    return [likes count] == 1 && [likes[0] isKindOfClass:[NSString class]] && [likes[0] isEqualToString:NO_LIKE_TAG];
}

- (BOOL)errorRetrievingLikes:(NSArray *)likes
{
    return [likes count] == 1 && [likes[0] isKindOfClass:[NSString class]] && [likes[0] isEqualToString:NO_CONNECTION_TAG];
}

- (void)moveToProfileOfUser:(NSInteger)userId
{
    [self performSegueWithIdentifier:@"Profile from Likes push segue" sender:[NSNumber numberWithLong:userId]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Profile from Likes push segue"]) {
        ProfileViewController * usersListViewController = (ProfileViewController *) [segue destinationViewController];
        usersListViewController.currentUser = self.currentUser;
        usersListViewController.profileUserId = [(NSNumber *) sender intValue];
    }
}

@end
