//
//  SnapbyViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 7/23/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "DisplayViewController.h"
#import "TimeUtilities.h"
#import "Constants.h"
#import "UIImageView+AFNetworking.h"
#import "LocationUtilities.h"
#import "GeneralUtilities.h"
#import "ImageUtilities.h"
#import "AFSnapbyAPIClient.h"
#import "SessionUtilities.h"
#import "ProfileViewController.h"
#import "MBProgressHUD.h"

#define MORE_ACTION_SHEET_OPTION_1 NSLocalizedStringFromTable (@"navigate_to_snapby", @"Strings", @"comment")
#define MORE_ACTION_SHEET_OPTION_2 NSLocalizedStringFromTable (@"share_snapby", @"Strings", @"comment")
#define MORE_ACTION_SHEET_OPTION_3 NSLocalizedStringFromTable (@"report_snapby", @"Strings", @"comment")
#define MORE_ACTION_SHEET_OPTION_4 NSLocalizedStringFromTable (@"remove_snapby", @"Strings", @"comment")

#define FLAG_ACTION_SHEET_OPTION_1 NSLocalizedStringFromTable (@"abusive_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_2 NSLocalizedStringFromTable (@"spam_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_3 NSLocalizedStringFromTable (@"privacy_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_4 NSLocalizedStringFromTable (@"inaccurate_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_5 NSLocalizedStringFromTable (@"other_content", @"Strings", @"comment")

#define FLAG_ACTION_SHEET_CANCEL NSLocalizedStringFromTable (@"cancel", @"Strings", @"comment")

@interface DisplayViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *snapbyImageView;
@property (weak, nonatomic) IBOutlet UIImageView *snapbyThumbView;
@property (strong, nonatomic) UIActionSheet *flagActionSheet;
@property (strong, nonatomic) UIActionSheet *moreActionSheet;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *createdLabel;


@end

@implementation DisplayViewController

- (void)viewDidLoad
{
    [self updateUI];
    
    [super viewDidLoad];
}

- (void)updateUI
{
        
    //Fill with snapby info
    if (self.snapby) {
        
        //Preload thumb
        [self.snapbyThumbView setImageWithURL:[self.snapby getSnapbyThumbURL]];
        // Get image
        [self.snapbyImageView setImageWithURL:[self.snapby getSnapbyImageURL] placeholderImage:nil];
        
        self.usernameLabel.text = [NSString stringWithFormat:@"%@ (%lu)", self.snapby.username, self.snapby.userScore];
        
        NSString *snapbyAge = [TimeUtilities ageToString:[TimeUtilities getSnapbyAge:self.snapby.created]];
        
        self.createdLabel.text = [NSString stringWithFormat:@"Created %@ ago", snapbyAge];
        
        self.snapbyImageView.clipsToBounds = YES;
        [self.snapbyImageView setHidden:NO];
    }
}

- (IBAction)moreSnapbyOptionButtonPressed:(id)sender {
    
    if(self.snapby.userId == [SessionUtilities getCurrentUser].identifier) {
        self.moreActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self cancelButtonTitle:FLAG_ACTION_SHEET_CANCEL
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:MORE_ACTION_SHEET_OPTION_1, MORE_ACTION_SHEET_OPTION_2, MORE_ACTION_SHEET_OPTION_3, MORE_ACTION_SHEET_OPTION_4, nil];
    } else {
        self.moreActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self cancelButtonTitle:FLAG_ACTION_SHEET_CANCEL
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:MORE_ACTION_SHEET_OPTION_1, MORE_ACTION_SHEET_OPTION_2, MORE_ACTION_SHEET_OPTION_3, nil];
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
        } else if ([buttonTitle isEqualToString:MORE_ACTION_SHEET_OPTION_2]) {
            NSString *shareString = @"Hey, check out this snapby!\n";
            
            NSURL *shareUrl = [NSURL URLWithString:[[(PRODUCTION? kProdSnapbyBaseURLString : kDevAFSnapbyAPIBaseURLString) stringByAppendingString:@"snapbies/"]stringByAppendingString:[NSString stringWithFormat:@"%lu",(unsigned long)self.snapby.identifier]]];
            
            NSArray *activityItems = [NSArray arrayWithObjects:shareString, shareUrl, nil];
            
            UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
            [activityViewController setValue:@"Sharing a snapby with you." forKey:@"subject"];
            activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop];
            [self presentViewController:activityViewController animated:YES completion:nil];
        } else if ([buttonTitle isEqualToString:MORE_ACTION_SHEET_OPTION_3]) {
            self.flagActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedStringFromTable (@"flag_action_sheet_title", @"Strings", @"comment")
                                                               delegate:self
                                                      cancelButtonTitle:FLAG_ACTION_SHEET_CANCEL
                                                 destructiveButtonTitle:nil
                                                      otherButtonTitles:FLAG_ACTION_SHEET_OPTION_1, FLAG_ACTION_SHEET_OPTION_2, FLAG_ACTION_SHEET_OPTION_3, FLAG_ACTION_SHEET_OPTION_4, FLAG_ACTION_SHEET_OPTION_5, nil];
            [self.flagActionSheet showInView:self.view];
        } else if ([buttonTitle isEqualToString:MORE_ACTION_SHEET_OPTION_4]) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
            [AFSnapbyAPIClient removeSnapby: self.snapby success:^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [self dismissViewControllerAnimated:YES completion:^{
                    [self.displayVCDelegate refreshSnapbiesFromDisplay];
                }];
            } failure:^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"fail_delete_snapby", @"Strings", @"comment") withTitle:nil];
            }];
        }
    } else if (actionSheet == self.flagActionSheet) {
        
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
        
        [AFSnapbyAPIClient reportSnapby:self.snapby.identifier withFlaggerId:[SessionUtilities getCurrentUser].identifier withMotive:motive AndExecute:nil Failure:^{
            [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"fail_report_snapby", @"Strings", @"comment") withTitle:nil];
        }];
        
        [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"flag_thanks_alert", @"Strings", @"comment") withTitle:nil];
    }
}

- (IBAction)snapbyImageClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
