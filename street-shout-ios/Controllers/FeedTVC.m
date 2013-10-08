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
#import "NavigationViewController.h"
#import "ShoutTableViewCell.h"
#import "Constants.h"
#import "UIImageView+AFNetworking.h"
#import "GeneralUtilities.h"

#define SHOUT_TAG @"Shout"
#define NO_SHOUT_TAG @"No Shout"
#define LOADING_TAG @"Loading"
#define SHOUT_IMAGE_SIZE 50

@interface FeedTVC ()

@end

@implementation FeedTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    
    [self.refreshControl addTarget:self
                            action:@selector(refreshShouts) forControlEvents:UIControlEventValueChanged];
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
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
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
        
        cell.shoutContentLabel.text = shout.description;
        cell.shoutUserNameLabel.text = [NSString stringWithFormat:@"by %@", shout.displayName];
        
        if (shout.image) {
            NSURL *url = [NSURL URLWithString:[shout.image stringByAppendingFormat:@"--%d", kShoutImageSize]];
            [cell.shoutImageView setImageWithURL:url placeholderImage:nil];
            
            cell.shoutImageView.layer.cornerRadius = SHOUT_IMAGE_SIZE/2;
            cell.shoutImageView.clipsToBounds = YES;
            
            [cell.shoutImageView setHidden:NO];
        } else {
            [cell.shoutImageView setHidden:YES];
        }
        
        NSArray *shoutAgeStrings = [TimeUtilities shoutAgeToStrings:[TimeUtilities getShoutAge:shout.created]];
        
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

- (NSString *)titleForRow:(NSUInteger)row
{
    return ((Shout *)self.shouts[row]).description;
} 

- (NSString *)subtitleForRow:(NSUInteger)row
{
    Shout *shout = (Shout *)self.shouts[row];
    
    NSString *timeStamp = [TimeUtilities shoutAgeToString:[TimeUtilities getShoutAge:shout.created]];
    NSString *userName = [NSString stringWithFormat:@", by %@", ((Shout *)self.shouts[row]).displayName];
    NSString *stamp = [timeStamp stringByAppendingString:userName];
    
    if (shout.image) {
        stamp = [stamp stringByAppendingString:@" (photo)"];
    }
    return stamp;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Shout *shout = self.shouts[indexPath.row];
    [self.feedTVCdelegate shoutSelectionComingFromFeed:shout];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"Show Shout"]) {
                if ([segue.destinationViewController respondsToSelector:@selector(setShout:)]) {
                    Shout *shout = self.shouts[indexPath.row];
                    [segue.destinationViewController performSelector:@selector(setShout:) withObject:shout];
                    ((ShoutViewController *)segue.destinationViewController).shoutVCDelegate = (NavigationViewController *)self.feedTVCdelegate;
                }
            }
        }
    } else if ([sender isKindOfClass:[Shout class]]) {
        if ([segue.identifier isEqualToString:@"Show Shout"]) {
            if ([segue.destinationViewController respondsToSelector:@selector(setShout:)]) {
                [segue.destinationViewController performSelector:@selector(setShout:) withObject:sender];
                ((ShoutViewController *)segue.destinationViewController).shoutVCDelegate = (NavigationViewController *)self.feedTVCdelegate;
            }
        }
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 60;
}

@end
