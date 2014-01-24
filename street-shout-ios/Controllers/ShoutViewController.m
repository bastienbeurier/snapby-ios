//
//  ShoutViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/23/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "ShoutViewController.h"
#import "TimeUtilities.h"
#import "Constants.h"
#import "UIImageView+AFNetworking.h"
#import "LocationUtilities.h"
#import "GeneralUtilities.h"
#import "ImageUtilities.h"
#import "AFStreetShoutAPIClient.h"
#import "SessionUtilities.h"
#import "LikesViewController.h"

#define MORE_ACTION_SHEET_OPTION_1 NSLocalizedStringFromTable (@"report_shout", @"Strings", @"comment")
#define MORE_ACTION_SHEET_OPTION_2 NSLocalizedStringFromTable (@"navigate_to_shout", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_1 NSLocalizedStringFromTable (@"abusive_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_2 NSLocalizedStringFromTable (@"spam_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_3 NSLocalizedStringFromTable (@"privacy_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_4 NSLocalizedStringFromTable (@"inaccurate_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_5 NSLocalizedStringFromTable (@"other_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_CANCEL NSLocalizedStringFromTable (@"cancel", @"Strings", @"comment")

@interface ShoutViewController ()

@property (weak, nonatomic) IBOutlet UILabel *shoutUsername;
@property (weak, nonatomic) IBOutlet UILabel *shoutContent;
@property (weak, nonatomic) IBOutlet UIImageView *shoutImageView;
@property (weak, nonatomic) IBOutlet UILabel *shoutAgeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *shoutImageDropShadowView;
@property (weak, nonatomic) IBOutlet UIButton *commentButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *moreShoutOptionsButton;
@property (weak, nonatomic) IBOutlet UIView *bottomBarView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIImageView *commentsCountIcon;
@property (weak, nonatomic) IBOutlet UIButton *commentsCountLabelButton;
@property (weak, nonatomic) IBOutlet UIButton *likesCountButton;
@property (weak, nonatomic) IBOutlet UIImageView *likesCountIcon;
@property (weak, nonatomic) IBOutlet UIButton *dismissShoutButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (strong, nonatomic) NSMutableArray *likerIds;
@property (nonatomic) BOOL likeButtonActive;
@property (strong, nonatomic) UIActionSheet *flagActionSheet;
@property (strong, nonatomic) UIActionSheet *moreActionSheet;


@end

@implementation ShoutViewController

- (void)viewDidLoad
{
    self.likeButtonActive = YES;
    
    self.mapView.delegate = self;
    
    self.likerIds = [[NSMutableArray alloc] initWithArray:@[]];
    
    ////Hack to remove the selection highligh from the cell during the back animation
    [self.shoutVCDelegate redisplayFeed];
    
    //Buttons round corner
    NSUInteger buttonHeight = self.dismissShoutButton.bounds.size.height;
    self.dismissShoutButton.layer.cornerRadius = buttonHeight/2;
    
    [self updateUI];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    if (screenRect.size.height == 568.0f) {
        self.scrollView.scrollEnabled = NO;
    }
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    //Shout content round corners
    self.shoutContent.layer.cornerRadius = 5;
    
    //Add bottom bar borders
    CALayer *topBorder = [CALayer layer];
    topBorder.frame = CGRectMake(0.0f, 0.0f, self.bottomBarView.frame.size.width, 0.5f);
    topBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [self.bottomBarView.layer addSublayer:topBorder];
    
    CALayer *firstInterBorder = [CALayer layer];
    firstInterBorder.frame = CGRectMake(80.0f, 10.0f, 0.5f, self.bottomBarView.frame.size.height - 20);
    firstInterBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [self.bottomBarView.layer addSublayer:firstInterBorder];
    
    CALayer *secondInterBorder = [CALayer layer];
    secondInterBorder.frame = CGRectMake(160.0f, 10.0f, 0.5f, self.bottomBarView.frame.size.height - 20);
    secondInterBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [self.bottomBarView.layer addSublayer:secondInterBorder];
    
    CALayer *thirdInterBorder = [CALayer layer];
    thirdInterBorder.frame = CGRectMake(240.0f, 10.0f, 0.5f, self.bottomBarView.frame.size.height - 20);
    thirdInterBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [self.bottomBarView.layer addSublayer:thirdInterBorder];
    
    //Bug coming back from comments
    if (self.likeButtonActive == NO) {
        [self updateUIOnShoutLiked:YES];
    }
    
    [super viewWillAppear:animated];
}

- (void)updateUI
{
    //Get comment count and liker ids
    [AFStreetShoutAPIClient getShoutMetaData:self.shout success:^(NSInteger commentCount, NSMutableArray *likerIds) {
        [self updateCommentCount:commentCount];
        self.commentsCountLabelButton.hidden = NO;
        self.commentsCountIcon.hidden = NO;
        
        //Store them for later
        self.likerIds = likerIds;
        
        [self updateLikeCount:[self.likerIds count]];
        self.likesCountButton.hidden = NO;
        self.likesCountIcon.hidden = NO;
        
        
        BOOL currentUserLikedShout = NO;
        
        //Check if current user liked this shout
        for (NSNumber *likerId in self.likerIds) {
            if ([likerId integerValue] == [SessionUtilities getCurrentUser].identifier) {
                currentUserLikedShout = YES;
            }
        }
        
        [self updateUIOnShoutLiked:currentUserLikedShout];
    } failure:nil];
    
    //Move map to shout
    [LocationUtilities animateMap:self.mapView ToLatitude:self.shout.lat Longitude:self.shout.lng WithDistance:kDistanceWhenDisplayShout Animated:NO];
    
    //Put annotation for shout
    CLLocationCoordinate2D annotationCoordinate;
    annotationCoordinate.latitude = self.shout.lat;
    annotationCoordinate.longitude = self.shout.lng;
    MKPointAnnotation *shoutAnnotation = [[MKPointAnnotation alloc] init];
    shoutAnnotation.coordinate = annotationCoordinate;
    [self.mapView addAnnotation:shoutAnnotation];
    
    //Fill with shout info
    if (self.shout) {
        if (self.shout.image) {
            NSURL *url = [NSURL URLWithString:[self.shout.image stringByAppendingFormat:@"--%d", kShoutImageSize]];
            [self.shoutImageView setImageWithURL:url placeholderImage:nil];
            
            [self.shoutImageView setHidden:NO];
            [self.shoutImageDropShadowView setHidden:NO];
        } else {
            [self.shoutImageView setHidden:YES];
            [self.shoutImageDropShadowView setHidden:NO];
        }
        
        self.shoutUsername.text = [NSString stringWithFormat:@"@%@", self.shout.username];

        self.shoutContent.text = self.shout.description;
        
        NSArray *shoutAgeStrings = [TimeUtilities ageToShortStrings:[TimeUtilities getShoutAge:self.shout.created]];
        
        self.shoutAgeLabel.text = [NSString stringWithFormat:@"%@%@", [shoutAgeStrings firstObject], [shoutAgeStrings objectAtIndex:1]];
        
        MKUserLocation *myLocation = self.mapView.userLocation;
        
        if (myLocation && myLocation.coordinate.longitude != 0 && myLocation.coordinate.latitude != 0) {
            NSArray *shoutDistanceStrings = [LocationUtilities formattedDistanceLat1:myLocation.coordinate.latitude lng1:myLocation.coordinate.longitude lat2:self.shout.lat lng2:self.shout.lng];
            self.shoutAgeLabel.text = [NSString stringWithFormat:@" %@ | %@%@", self.shoutAgeLabel.text, [shoutDistanceStrings firstObject], [shoutDistanceStrings objectAtIndex:1]];
        } else {
            self.shoutAgeLabel.text = [NSString stringWithFormat:@" %@ | ?", self.shoutAgeLabel.text];
        }
    }
}

- (IBAction)moreShoutOptionButtonPressed:(id)sender {
    
    
    self.moreActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self cancelButtonTitle:FLAG_ACTION_SHEET_CANCEL
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:MORE_ACTION_SHEET_OPTION_1, MORE_ACTION_SHEET_OPTION_2, nil];
    
    [self.moreActionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:FLAG_ACTION_SHEET_CANCEL]) {
        return;
    }
    
    if (actionSheet == self.moreActionSheet) {
        if ([buttonTitle isEqualToString:MORE_ACTION_SHEET_OPTION_1]) {
            self.flagActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedStringFromTable (@"flag_action_sheet_title", @"Strings", @"comment")
                                                               delegate:self
                                                      cancelButtonTitle:FLAG_ACTION_SHEET_CANCEL
                                                 destructiveButtonTitle:nil
                                                      otherButtonTitles:FLAG_ACTION_SHEET_OPTION_1, FLAG_ACTION_SHEET_OPTION_2, FLAG_ACTION_SHEET_OPTION_3, FLAG_ACTION_SHEET_OPTION_4, FLAG_ACTION_SHEET_OPTION_5, nil];
            [self.flagActionSheet showInView:self.view];
        }
        
        if ([buttonTitle isEqualToString:MORE_ACTION_SHEET_OPTION_2]) {
            Class mapItemClass = [MKMapItem class];
            if (mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)]) {
                // Create an MKMapItem to pass to the Maps app
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(self.shout.lat, self.shout.lng);
                MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate
                                                               addressDictionary:nil];
                MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
                [mapItem setName:@"Shout"];
                // Pass the map item to the Maps app
                [mapItem openInMapsWithLaunchOptions:nil];
            }
        }
    } else if (actionSheet == self.flagActionSheet) {
        typedef void (^FailureBlock)(AFHTTPRequestOperation *);
        FailureBlock failureBlock = ^(AFHTTPRequestOperation *operation) {
            //In this case, 401 means that the auth token is no valid.
            if ([SessionUtilities invalidTokenResponse:operation]) {
                [SessionUtilities redirectToSignIn];
            }
        };
        
        NSString *motive = nil;
        
        switch (buttonIndex) {
            case 0:
                motive = @"abuse";
                break;
            case 1:
                motive = @"spam";
                break;
            case 2:
                motive = @"privacy";
                break;
            case 3:
                motive = @"inaccurate";
                break;
            case 4:
                motive = @"other";
                break;
        }
        
        [AFStreetShoutAPIClient reportShout:self.shout.identifier withFlaggerId:[SessionUtilities getCurrentUser].identifier withMotive:motive AndExecute:nil Failure:failureBlock];
        
        [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"flag_thanks_alert", @"Strings", @"comment") withTitle:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString: @"Comments Push Segue From Bar Button"] ||
        [segueName isEqualToString: @"Comments Push Segue From Count Label"]) {
        ((CommentsViewController *) [segue destinationViewController]).shout = self.shout;
        ((CommentsViewController *) [segue destinationViewController]).userLocation = self.mapView.userLocation;
        ((CommentsViewController *) [segue destinationViewController]).commentsVCdelegate = self;
    }
    
    if ([segueName isEqualToString: @"Likes Push Segue From Count Label"]) {
        ((LikesViewController *) [segue destinationViewController]).shout = self.shout;
        ((LikesViewController *) [segue destinationViewController]).userLocation = self.mapView.userLocation;
    }
}
- (IBAction)dissmissShoutClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

// Share to FB, sms, email.. using UIActivityViewController
- (IBAction)shareButtonPressed:(id)sender {
    NSString *shareString = @"Hey, check this Shout before it's too late!\n";
    UIImage *shareImage = [UIImage imageNamed:@"shout-app-icon-58.png"];
    // todoBT logo
    NSURL *shareUrl = [NSURL URLWithString:[[kProdShoutBaseURLString stringByAppendingString:@"shouts/"]stringByAppendingString:[NSString stringWithFormat:@"%d",self.shout.identifier]]];
    
    NSArray *activityItems = [NSArray arrayWithObjects:shareString, shareImage, shareUrl, nil];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [activityViewController setValue:@"One brand new Shout you should see!" forKey:@"subject"];
    activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop];
    [self presentViewController:activityViewController animated:YES completion:nil];
}

//Hack to make the annotations appear
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)annotationViews
{
    for (MKAnnotationView *annView in annotationViews)
    {
        if (![annView.annotation isKindOfClass:[MKUserLocation class]]) {
            MKPointAnnotation *annotation = (MKPointAnnotation *)annView.annotation;
            
            MKAnnotationView *annotationView = [self.mapView viewForAnnotation:annotation];
            
            NSString *annotationPinImage = [GeneralUtilities getAnnotationPinImageForShout:self.shout];
            
            annotationView.image = [UIImage imageNamed:annotationPinImage];
            annotationView.centerOffset = CGPointMake(kShoutAnnotationOffsetX,kShoutAnnotationOffsetY);
        }
    }
}

- (void)updateCommentsCount:(NSInteger)count
{
    [self.commentsCountLabelButton setTitle:[NSString stringWithFormat:@"%d comments", count] forState:UIControlStateNormal];
    self.commentsCountLabelButton.hidden = NO;
    self.commentsCountIcon.hidden = NO;
}

- (IBAction)createLikeButtonClicked:(id)sender {
    //Prevent from making the button color lighter if using de enabled property of UIButton
    if (self.likeButtonActive == NO) {
        return;
    }
    
    //Update the UI
    [self.likerIds insertObject:[NSNumber numberWithInt:[SessionUtilities getCurrentUser].identifier] atIndex:0];
    [self updateUIOnShoutLiked:YES];
    
    double lat = 0;
    double lng = 0;
    
    MKUserLocation *userLocation = self.mapView.userLocation;
    
    if ([LocationUtilities userLocationValid:userLocation]) {
        lat = userLocation.coordinate.latitude;
        lng = userLocation.coordinate.longitude;
    }
    
    //Create the like
    [AFStreetShoutAPIClient createLikeforShout:self.shout lat:lat lng:lng success:nil failure:^{
        [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"like_failed_message", @"Strings", @"comment") withTitle:nil];
        [self updateUIOnShoutLiked:NO];
        [self.likerIds removeObjectAtIndex:0];
    }];
}

- (void)updateUIOnShoutLiked:(BOOL)liked
{
    self.likeButton.enabled = YES;
    
    if (liked) {
        self.likeButtonActive = NO;
        [self.likeButton setImage:[UIImage imageNamed:@"shout-like-icon-selected"] forState:UIControlStateNormal];
    } else {
        self.likeButtonActive = YES;
        [self.likeButton setImage:[UIImage imageNamed:@"shout-like-icon"] forState:UIControlStateNormal];
    }
    
    [self updateLikeCount:[self.likerIds count]];
}

- (void)updateLikeCount:(NSUInteger)count
{
    if (count < 2) {
        [self.likesCountButton setTitle:[NSString stringWithFormat:@"%d like", [self.likerIds count]] forState:UIControlStateNormal];
    } else {
        [self.likesCountButton setTitle:[NSString stringWithFormat:@"%d likes", [self.likerIds count]] forState:UIControlStateNormal];
    }
}

- (void)updateCommentCount:(NSUInteger)count
{
    if (count < 2) {
        [self.commentsCountLabelButton setTitle:[NSString stringWithFormat:@"%d comment", count] forState:UIControlStateNormal];
    } else {
        [self.commentsCountLabelButton setTitle:[NSString stringWithFormat:@"%d comments", count] forState:UIControlStateNormal];
    }
    
}

@end
