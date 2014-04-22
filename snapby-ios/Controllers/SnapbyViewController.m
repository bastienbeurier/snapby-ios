//
//  SnapbyViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 7/23/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "SnapbyViewController.h"
#import "TimeUtilities.h"
#import "Constants.h"
#import "UIImageView+AFNetworking.h"
#import "LocationUtilities.h"
#import "GeneralUtilities.h"
#import "ImageUtilities.h"
#import "AFSnapbyAPIClient.h"
#import "SessionUtilities.h"
#import "ProfileViewController.h"

#define MORE_ACTION_SHEET_OPTION_1 NSLocalizedStringFromTable (@"report_snapby", @"Strings", @"comment")
#define MORE_ACTION_SHEET_OPTION_2 NSLocalizedStringFromTable (@"navigate_to_snapby", @"Strings", @"comment")
#define MORE_ACTION_SHEET_OPTION_3 NSLocalizedStringFromTable (@"remove_snapby", @"Strings", @"comment")

#define FLAG_ACTION_SHEET_OPTION_1 NSLocalizedStringFromTable (@"abusive_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_2 NSLocalizedStringFromTable (@"spam_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_3 NSLocalizedStringFromTable (@"privacy_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_4 NSLocalizedStringFromTable (@"inaccurate_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_5 NSLocalizedStringFromTable (@"other_content", @"Strings", @"comment")

#define FLAG_ACTION_SHEET_CANCEL NSLocalizedStringFromTable (@"cancel", @"Strings", @"comment")

@interface SnapbyViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *snapbyImageView;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *moreSnapbyOptionsButton;
@property (weak, nonatomic) IBOutlet UIView *bottomBarView;
@property (strong, nonatomic) UIActionSheet *flagActionSheet;
@property (strong, nonatomic) UIActionSheet *moreActionSheet;


@end

@implementation SnapbyViewController

- (void)viewDidLoad
{
    [self updateUI];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    //Status bar style
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    //Add bottom bar borders
    CALayer *topBorder = [CALayer layer];
    topBorder.frame = CGRectMake(0.0f, 0.0f, self.bottomBarView.frame.size.width, 0.5f);
    topBorder.backgroundColor = [UIColor whiteColor].CGColor;
    [self.bottomBarView.layer addSublayer:topBorder];
    
    CALayer *firstInterBorder = [CALayer layer];
    firstInterBorder.frame = CGRectMake(80.0f, 10.0f, 0.5f, self.bottomBarView.frame.size.height - 20);
    firstInterBorder.backgroundColor = [UIColor whiteColor].CGColor;
    [self.bottomBarView.layer addSublayer:firstInterBorder];
    
    CALayer *secondInterBorder = [CALayer layer];
    secondInterBorder.frame = CGRectMake(160.0f, 10.0f, 0.5f, self.bottomBarView.frame.size.height - 20);
    secondInterBorder.backgroundColor = [UIColor whiteColor].CGColor;
    [self.bottomBarView.layer addSublayer:secondInterBorder];
    
    CALayer *thirdInterBorder = [CALayer layer];
    thirdInterBorder.frame = CGRectMake(240.0f, 10.0f, 0.5f, self.bottomBarView.frame.size.height - 20);
    thirdInterBorder.backgroundColor = [UIColor whiteColor].CGColor;
    [self.bottomBarView.layer addSublayer:thirdInterBorder];
    
    [super viewWillAppear:animated];
}

- (void)updateUI
{
        
    //Fill with snapby info
    if (self.snapby) {
        // Get image
        [self.snapbyImageView setImageWithURL:[self.snapby getSnapbyImageURL] placeholderImage:nil];
        
        self.snapbyImageView.clipsToBounds = YES;
        [self.snapbyImageView setHidden:NO];
    }
}

- (IBAction)moreSnapbyOptionButtonPressed:(id)sender {
    
    if([SessionUtilities currentUserIsAdmin] || self.snapby.userId == [SessionUtilities getCurrentUser].identifier) {
        self.moreActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self cancelButtonTitle:FLAG_ACTION_SHEET_CANCEL
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:MORE_ACTION_SHEET_OPTION_1, MORE_ACTION_SHEET_OPTION_3, nil];
    } else {
        self.moreActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self cancelButtonTitle:FLAG_ACTION_SHEET_CANCEL
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:MORE_ACTION_SHEET_OPTION_1, MORE_ACTION_SHEET_OPTION_2, nil];
    }
    
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
        } else if ([buttonTitle isEqualToString:MORE_ACTION_SHEET_OPTION_2]) {
            Class mapItemClass = [MKMapItem class];
            if (mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)]) {
                // Create an MKMapItem to pass to the Maps app
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(self.snapby.lat, self.snapby.lng);
                MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate
                                                               addressDictionary:nil];
                MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
                [mapItem setName:@"Snapby"];
                // Pass the map item to the Maps app
                [mapItem openInMapsWithLaunchOptions:nil];
            }
        } else if ([buttonTitle isEqualToString:MORE_ACTION_SHEET_OPTION_3]) {
            [AFSnapbyAPIClient removeSnapby: self.snapby success:nil failure:nil];
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else if (actionSheet == self.flagActionSheet) {
        typedef void (^FailureBlock)(NSURLSessionDataTask *);
        FailureBlock failureBlock = ^(NSURLSessionDataTask *task) {
            //In this case, 401 means that the auth token is no valid.
            if ([SessionUtilities invalidTokenResponse:task]) {
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
        
        [AFSnapbyAPIClient reportSnapby:self.snapby.identifier withFlaggerId:[SessionUtilities getCurrentUser].identifier withMotive:motive AndExecute:nil Failure:failureBlock];
        
        [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"flag_thanks_alert", @"Strings", @"comment") withTitle:nil];
    }
}

// Share to FB, sms, email.. using UIActivityViewController
- (IBAction)shareButtonPressed:(id)sender {
    NSString *shareString = @"Hey, check this snapby before it's too late!\n";

    NSURL *shareUrl = [NSURL URLWithString:[[(PRODUCTION? kProdSnapbyBaseURLString : kDevAFSnapbyAPIBaseURLString) stringByAppendingString:@"snapbies/"]stringByAppendingString:[NSString stringWithFormat:@"%lu",(unsigned long)self.snapby.identifier]]];
    
    NSArray *activityItems = [NSArray arrayWithObjects:shareString, shareUrl, nil];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [activityViewController setValue:@"Sharing a snapby with you." forKey:@"subject"];
    activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop];
    [self presentViewController:activityViewController animated:YES completion:nil];
}
- (IBAction)snapbyImageClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];

}


@end
