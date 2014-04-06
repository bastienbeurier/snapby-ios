//
//  CommentsViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/20/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "CommentsViewController.h"
#import "Comment.h"
#import "ImageUtilities.h"
#import "AFStreetShoutAPIClient.h"
#import "TimeUtilities.h"
#import "LocationUtilities.h"
#import "GeneralUtilities.h"
#import "KeyboardUtilities.h"
#import "Constants.h"
#import "UIImageView+AFNetworking.h"
#import "ProfileViewController.h"

#define NO_COMMENT_TAG @"No comment"
#define LOADING_TAG @"Loading"
#define NO_CONNECTION_TAG @"No connection"

@interface CommentsViewController () 

@property (weak, nonatomic) IBOutlet UITableView *commentsTableView;
@property (strong, nonatomic) UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UITextField *addCommentTextField;
@property (weak, nonatomic) IBOutlet UIButton *addCommentButton;
@property (weak, nonatomic) IBOutlet UIView *addCommentContainerView;

@end

@implementation CommentsViewController

- (void)viewDidLoad
{
    self.commentsTableView.delegate = self;
    self.commentsTableView.dataSource = self;
    
    self.addCommentTextField.delegate = self;
    
    //Nav Bar
    [ImageUtilities drawCustomNavBarWithLeftItem:@"back" rightItem:nil title:@"Comments" sizeBig:YES inViewController:self];
    
    if (!self.activityView) {
        self.activityView= [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    
    //Fill Table View
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
    
    //Comment round button and border
    NSUInteger buttonCorner = 5;
    self.addCommentButton.layer.cornerRadius = buttonCorner;
    [[self.addCommentButton layer] setBorderWidth:1.0f];
    [[self.addCommentButton layer] setBorderColor:[ImageUtilities getShoutBlue].CGColor];
    
    // observe keyboard show notifications to resize the text view appropriately
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
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

- (NSInteger)commentCount
{
    if ([self.comments count] == 0 || [self.comments count] > 1 || [self.comments[0] isKindOfClass:[Comment class]]) {
        return [self.comments count];
    } else {
        //We don't know the comment count (loading or server error)
        return -1;
    }
}

- (void)backButtonClicked
{
    NSInteger commentCount = [self commentCount];
    
    if (commentCount > -1) {
        [self.commentsVCdelegate updateCommentCount:commentCount];
    }
    
    [[self navigationController] popViewControllerAnimated:YES];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.comments count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self noCommentsInArray:self.comments]) {
        static NSString *cellIdentifier = NO_COMMENT_TAG;
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        return cell;
    } else if ([self errorRetrievingComments:self.comments]) {
        static NSString *cellIdentifier = NO_CONNECTION_TAG;
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        return cell;
    } else {
        static NSString *cellIdentifier = @"CommentsTableViewCell";
        
        CommentsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellIdentifier owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
        
        Comment *comment = (Comment *)self.comments[indexPath.row];
        
        cell.commentsTableViewCellDelegate = self;
        cell.commenterId = comment.commenterId;
        cell.usernameLabel.text = [NSString stringWithFormat:@"@%@",comment.commenterUsername];
        cell.descriptionLabel.text = comment.description;
        
        NSArray *commentAgeStrings = [TimeUtilities ageToShortStrings:[TimeUtilities getShoutAge:comment.created]];
        
        cell.stampLabel.text = [NSString stringWithFormat:@"%@%@", [commentAgeStrings firstObject], [commentAgeStrings objectAtIndex:1]];
        
        if (comment.lat !=0 && comment.lng !=0 ) {
            NSArray *distanceStrings = [LocationUtilities formattedDistanceLat1:comment.lat lng1:comment.lng lat2:self.shout.lat lng2:self.shout.lng];
            cell.stampLabel.text = [NSString stringWithFormat:@" %@ | %@%@", cell.stampLabel.text, [distanceStrings firstObject], [distanceStrings objectAtIndex:1]];
        }
        
        // Picture
        [cell.profilePictureView setImageWithURL:[User getUserProfilePictureURLFromUserId:comment.commenterId] placeholderImage:nil];
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
    if ([self noCommentsInArray:self.comments]) {
        return 60;
    } else if ([self errorRetrievingComments:self.comments]) {
        return 60;
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
        
        return MAX(60,height);
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (BOOL)noCommentsInArray:(NSArray *)comments
{
    return [comments count] == 1 && [comments[0] isKindOfClass:[NSString class]] && [comments[0] isEqualToString:NO_COMMENT_TAG];
}

- (BOOL)errorRetrievingComments:(NSArray *)comments
{
    return [comments count] == 1 && [comments[0] isKindOfClass:[NSString class]] && [comments[0] isEqualToString:NO_CONNECTION_TAG];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    
    [KeyboardUtilities pushUpTopView:self.addCommentContainerView whenKeyboardWillShowNotification:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    
    [KeyboardUtilities pushDownTopView:self.addCommentContainerView whenKeyboardWillhideNotification:notification];
}

- (IBAction)addCommentButtonPressed:(id)sender {
    [self.addCommentTextField resignFirstResponder];
    
    ((UIButton *)sender).enabled = NO;
    self.addCommentTextField.enabled = NO;
    NSString *commentDescription = self.addCommentTextField.text;
    
    double lat = 0;
    double lng = 0;
    
    if ([LocationUtilities userLocationValid:self.userLocation.location]) {
        lat = self.userLocation.coordinate.latitude;
        lng = self.userLocation.coordinate.longitude;
    }
    
    [AFStreetShoutAPIClient createComment:commentDescription forShout:self.shout lat:lat lng:lng success:^(NSArray *comments) {
        self.addCommentTextField.text = @"";
        self.comments = comments;
        ((UIButton *)sender).enabled = YES;
        self.addCommentTextField.enabled = YES;
    }failure:^{
        [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"comment_failed_message", @"Strings", @"comment") withTitle:nil];
        ((UIButton *)sender).enabled = YES;
        self.addCommentTextField.enabled = YES;
    }];
}


- (BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    [textField resignFirstResponder];
    return NO;
}

- (void)moveToProfileOfUser:(NSInteger)userId
{
    [self performSegueWithIdentifier:@"Profile from Comments push segue" sender:[NSNumber numberWithLong:userId]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Profile from Comments push segue"]) {
        ProfileViewController * usersListViewController = (ProfileViewController *) [segue destinationViewController];
        usersListViewController.currentUser = self.currentUser;
        usersListViewController.profileUserId = [(NSNumber *) sender intValue];
    }
}

@end
