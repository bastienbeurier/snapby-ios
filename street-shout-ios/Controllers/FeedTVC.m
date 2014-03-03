//
//  FeedTVC.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/19/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "FeedTVC.h"
#import "MapRequestHandler.h"
#import "TimeUtilities.h"
#import "ShoutViewController.h"
#import "ExploreViewController.h"
#import "ShoutTableViewCell.h"
#import "Constants.h"
#import "UIImageView+AFNetworking.h"
#import "GeneralUtilities.h"
#import "ImageUtilities.h"
#import "TrackingUtilities.h"

#define SHOUT_TAG @"Shout"
#define NO_SHOUT_TAG @"No Shout"
#define LOADING_TAG @"Loading"
#define NO_CONNECTION_TAG @"No connection"
#define SHOUT_IMAGE_SIZE 50
#define SHOUT_CONTENT_WIDTH_WITH_PHOTO 186.0f
#define SHOUT_CONTENT_WIDTH_WITHOUT_PHOTO 244.0f

@interface FeedTVC ()

@end

@implementation FeedTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.refreshControl addTarget:self
                            action:@selector(refreshShouts) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor clearColor];
    
    [super viewWillAppear:animated];
}

- (void)refreshShouts
{
    [self.refreshControl endRefreshing];
    [self.feedTVCdelegate refreshShouts];
}

- (void)viewDidAppear:(BOOL)animated
{
    //Hack due to autolayout bug
    CGRect superViewBounds = [self.view.superview bounds];
    CGRect viewBounds = [self.view bounds];
    CGRect containerViewBounds = [self.view.superview.superview bounds];
    
    if (superViewBounds.size.height != containerViewBounds.size.height) {
        [self.view.superview setBounds:CGRectMake(superViewBounds.origin.x,
                                                  superViewBounds.origin.y,
                                                  superViewBounds.size.width,
                                                  containerViewBounds.size.height + 20)];
        
        [self.view setBounds:CGRectMake(viewBounds.origin.x,
                                        viewBounds.origin.y,
                                        viewBounds.size.width,
                                        containerViewBounds.size.height + 20)];
    }
}

- (void)setShouts:(NSArray *)shouts
{
    if ([shouts count] == 0) {
        _shouts = @[NO_SHOUT_TAG];
    } else if ([shouts[0] isKindOfClass:[NSString class]] && [shouts[0] isEqualToString:LOADING_TAG]) {
        _shouts = @[];
    } else if ([shouts[0] isKindOfClass:[NSString class]] && [shouts[0] isEqualToString:NO_CONNECTION_TAG]) {
        _shouts = @[NO_CONNECTION_TAG];
    } else {
        _shouts = shouts;
    }
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.shouts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self noShoutsInArray:self.shouts]) {
        static NSString *CellIdentifier = NO_SHOUT_TAG;
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        return cell;
    } else if ([self errorRetrievingShouts:self.shouts]) {
        static NSString *CellIdentifier = NO_CONNECTION_TAG;
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        return cell;
    } else {
        ShoutTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ShoutTableViewCell"];
        
        if (cell == nil) {
            // Load the top-level objects from the custom cell XIB.
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"ShoutTableViewCell" owner:self options:nil];
            // Grab a pointer to the first object (presumably the custom cell, as that's all the XIB should contain).
            cell = [topLevelObjects objectAtIndex:0];
        }
        
        Shout *shout = (Shout *)self.shouts[indexPath.row];
        
        if (shout.image) {
            cell.imageViewDropShadow.image = [UIImage imageNamed:@"shout-image-place-holder-square-small"];
            
            NSURL *url = [NSURL URLWithString:[shout.image stringByAppendingFormat:@"--%d", kShoutImageWidth]];
            [cell.shoutImageView setImageWithURL:url placeholderImage:nil];
            
            cell.shoutImageView.layer.cornerRadius = SHOUT_IMAGE_SIZE/2;
            cell.shoutImageView.clipsToBounds = YES;
            cell.imageViewDropShadow.layer.cornerRadius = SHOUT_IMAGE_SIZE/2;
            cell.imageViewDropShadow.clipsToBounds = YES;
            
            cell.imageViewDropShadow.layer.cornerRadius = SHOUT_IMAGE_SIZE/2;
            
            [GeneralUtilities resizeView:cell.shoutContentLabel Width:SHOUT_CONTENT_WIDTH_WITH_PHOTO];
            
            [cell.shoutImageView setHidden:NO];
            [cell.imageViewDropShadow setHidden:NO];
        } else {
            [GeneralUtilities resizeView:cell.shoutContentLabel Width:SHOUT_CONTENT_WIDTH_WITHOUT_PHOTO];
            
            [cell.shoutImageView setHidden:YES];
            [cell.imageViewDropShadow setHidden:YES];
        }
        
        cell.shoutContentLabel.text = shout.description;
        cell.shoutUserNameLabel.text = [NSString stringWithFormat:@"by %@", shout.anonymous? @"Anonymous" : shout.username];
        
        NSArray *shoutAgeStrings = [TimeUtilities ageToStrings:[TimeUtilities getShoutAge:shout.created]];
        
        cell.shoutAgeLabel.text = [shoutAgeStrings firstObject];
        
        if (shoutAgeStrings.count > 1) {
            cell.shoutAgeUnitLabel.text = [shoutAgeStrings objectAtIndex:1];
        } else {
            cell.shoutAgeUnitLabel.text = @"";
        }
        
        cell.shoutAgeColorView.backgroundColor = [GeneralUtilities getShoutAgeColor:shout];
        
        return cell;
    }
}

- (BOOL)noShoutsInArray:(NSArray *)shouts
{
    return [shouts count] == 1 && [shouts[0] isKindOfClass:[NSString class]] && [shouts[0] isEqualToString:NO_SHOUT_TAG];
}

- (BOOL)errorRetrievingShouts:(NSArray *)shouts
{
    return [shouts count] == 1 && [shouts[0] isKindOfClass:[NSString class]] && [shouts[0] isEqualToString:NO_CONNECTION_TAG];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    Shout *shout = self.shouts[indexPath.row];
    [self.feedTVCdelegate shoutSelectionComingFromFeed:shout];
    
    //Mixpanel tracking
    [TrackingUtilities trackDisplayShout:shout withSource:@"Feed"];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 60;
}

@end
