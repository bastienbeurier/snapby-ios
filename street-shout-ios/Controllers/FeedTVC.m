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

#define SHOUT_TAG @"Shout"
#define NO_SHOUT_TAG @"No Shout"
#define LOADING_TAG @"Loading"

@interface FeedTVC ()

@end

@implementation FeedTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    UITableViewCell *cell;
    
    if ([self noShoutsInArray:self.shouts]) {
        static NSString *CellIdentifier = NO_SHOUT_TAG;
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    } else {
        static NSString *CellIdentifier = SHOUT_TAG;
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        // Configure the cell...
        cell.textLabel.text = [self titleForRow:indexPath.row];
        cell.detailTextLabel.text = [self subtitleForRow:indexPath.row];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    
    
    return cell;
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
    NSString *timeStamp = [TimeUtilities shoutAgeToString:[TimeUtilities getShoutAge:((Shout *)self.shouts[row]).created]];
    NSString *userName = [NSString stringWithFormat:@", by %@", ((Shout *)self.shouts[row]).displayName];
    return [timeStamp stringByAppendingString:userName];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Shout *shout = self.shouts[indexPath.row];
    [self.feedTVCdelegate shoutSelectedInFeed:shout];
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
                }
            }
        }
    } else if ([sender isKindOfClass:[Shout class]]) {
        if ([segue.identifier isEqualToString:@"Show Shout"]) {
            if ([segue.destinationViewController respondsToSelector:@selector(setShout:)]) {
                [segue.destinationViewController performSelector:@selector(setShout:) withObject:sender];
            }
        }
    }
}

@end
