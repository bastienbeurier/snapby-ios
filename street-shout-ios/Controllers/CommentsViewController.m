//
//  CommentsViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/20/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "CommentsViewController.h"
#import "CommentsTableViewCell.h"
#import "Comment.h"
#import "ImageUtilities.h"
#import "AFStreetShoutAPIClient.h"
#import "TimeUtilities.h"
#import "LocationUtilities.h"

#define NO_COMMENT_TAG @"No comment"
#define LOADING_TAG @"Loading"
#define NO_CONNECTION_TAG @"No connection"

@interface CommentsViewController () 

@property (weak, nonatomic) IBOutlet UITableView *commentsTableView;
@property (strong, nonatomic) UIActivityIndicatorView *activityView;

@end

@implementation CommentsViewController

- (void)viewDidLoad
{
    self.commentsTableView.delegate = self;
    self.commentsTableView.dataSource = self;
    
    //Custom nav bar
    //Nav Bar
    [ImageUtilities drawCustomNavBarWithLeftItem:@"back" rightItem:nil title:@"Comments" sizeBig:YES inViewController:self];
    
    //Status bar style
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    
    if (!self.activityView) {
        self.activityView= [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    
    self.activityView.center = CGPointMake(160, 50);
    
    [self.activityView startAnimating];
    
    [self.commentsTableView addSubview:self.activityView];
    
    self.comments = @[LOADING_TAG];
    
    [AFStreetShoutAPIClient getCommentsForShout:self.shout success:^(NSArray *comments) {
        [self.activityView stopAnimating];
        self.comments = comments;
    } failure: ^{
        [self.activityView stopAnimating];
        self.comments = @[NO_CONNECTION_TAG];
    }];

    [super viewDidLoad];
}

- (void)setComments:(NSArray *)comments
{
    if ([comments count] == 0) {
        _comments = @[NO_COMMENT_TAG];
    } else if ([comments[0] isKindOfClass:[NSString class]] && [comments[0] isEqualToString:LOADING_TAG]) {
        _comments = @[];
    } else if ([comments[0] isKindOfClass:[NSString class]] && [comments[0] isEqualToString:NO_CONNECTION_TAG]) {
        _comments = @[NO_CONNECTION_TAG];
    } else {
        _comments = comments;
    }
    
    [self.commentsTableView reloadData];
}


- (void)backButtonClicked
{
    [[self navigationController] popViewControllerAnimated:YES];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.comments count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self noCommentsInArray:self.comments]) {
        static NSString *CellIdentifier = NO_COMMENT_TAG;
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        return cell;
    } else if ([self errorRetrievingComments:self.comments]) {
        static NSString *CellIdentifier = NO_CONNECTION_TAG;
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        return cell;
    } else {
        static NSString *cellIdentifier = @"CommentsTableViewCell";
        
        CommentsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellIdentifier owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
        
        Comment *comment = (Comment *)self.comments[indexPath.row];
        
        cell.usernameLabel.text = [NSString stringWithFormat:@"@%@",comment.commenterUsername];
        cell.descriptionLabel.text = comment.description;
        
        NSArray *commentAgeStrings = [TimeUtilities ageToShortStrings:[TimeUtilities getShoutAge:comment.created]];
        
        cell.stampLabel.text = [NSString stringWithFormat:@"%@%@", [commentAgeStrings firstObject], [commentAgeStrings objectAtIndex:1]];
        
        if (comment.lat !=0 && comment.lng !=0 ) {
            NSArray *distanceStrings = [LocationUtilities formattedDistanceLat1:comment.lat lng1:comment.lng lat2:self.shout.lat lng2:self.shout.lng];
            cell.stampLabel.text = [NSString stringWithFormat:@" %@ | %@%@", cell.stampLabel.text, [distanceStrings firstObject], [distanceStrings objectAtIndex:1]];
        }
        
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
    if ([self noCommentsInArray:self.comments]) {
        return 54;
    } else if ([self errorRetrievingComments:self.comments]) {
        return 54;
    } else {
        static NSString *cellIdentifier = @"CommentsTableViewCell";
        
        CommentsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellIdentifier owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
        
        Comment *comment = (Comment *)self.comments[indexPath.row];
        
        cell.usernameLabel.text = [NSString stringWithFormat:@"@%@",comment.commenterUsername];
        cell.descriptionLabel.text = comment.description;
        
        cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
        
        [cell setNeedsLayout];
        [cell layoutIfNeeded];
        
        CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
        
        height += 1.0f;
        
        return height;
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

- (BOOL)noCommentsInArray:(NSArray *)comments
{
    return [comments count] == 1 && [comments[0] isKindOfClass:[NSString class]] && [comments[0] isEqualToString:NO_COMMENT_TAG];
}

- (BOOL)errorRetrievingComments:(NSArray *)comments
{
    return [comments count] == 1 && [comments[0] isKindOfClass:[NSString class]] && [comments[0] isEqualToString:NO_CONNECTION_TAG];
}

@end
