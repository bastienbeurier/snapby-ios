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

#define NO_COMMENT_TAG @"No Comment"
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
    
    self.activityView.center = self.commentsTableView.center;
    
    [self.activityView startAnimating];
    
    [self.commentsTableView addSubview:self.activityView];
    
    self.comments = @[@"Loading"];
    
    [AFStreetShoutAPIClient getCommentsForShout:self.shout success:^(NSArray *comments) {
        [self.activityView stopAnimating];
        self.comments = comments;
    } failure: ^{
        [self.activityView stopAnimating];
        self.comments = @[@"No connection"];
    }];

    [super viewDidLoad];
}

- (void)setComments:(NSArray *)comments
{
    if ([comments count] == 0) {
        comments = @[NO_COMMENT_TAG];
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
        
        cell.separatorView.frame = CGRectMake(cell.separatorView.frame.origin.x, cell.separatorView.frame.origin.y, cell.separatorView.frame.size.width, 0.3);
        
        return cell;
        
        //TODO implement time and distance
        
//        cell.shoutContentLabel.text = shout.description;
//        cell.shoutUserNameLabel.text = [NSString stringWithFormat:@"by %@", shout.username];
//        
//        NSArray *shoutAgeStrings = [TimeUtilities shoutAgeToStrings:[TimeUtilities getShoutAge:shout.created]];
//        
//        cell.shoutAgeLabel.text = [shoutAgeStrings firstObject];
//        
//        if (shoutAgeStrings.count > 1) {
//            cell.shoutAgeUnitLabel.text = [shoutAgeStrings objectAtIndex:1];
//        } else {
//            cell.shoutAgeUnitLabel.text = @"";
//        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
