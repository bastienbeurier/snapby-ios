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

#define SHOUT_IMAGE_SIZE 60

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
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *shoutZoomButton;
@property (weak, nonatomic) IBOutlet UILabel *shoutAgeLabel;
@property (weak, nonatomic) IBOutlet UILabel *shoutAgeUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *shoutDistanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *shoutDistanceUnitLabel;
@property (weak, nonatomic) IBOutlet UIImageView *shoutImageDropShadowView;


@end

@implementation ShoutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.view.backgroundColor = [GeneralUtilities getShoutAgeColor:self.shout];
    
    //Round shout image
    self.shoutImageView.layer.cornerRadius = SHOUT_IMAGE_SIZE/2;
    self.shoutImageView.clipsToBounds = YES;
    self.shoutImageDropShadowView.layer.cornerRadius = SHOUT_IMAGE_SIZE/2;
    
    //Gabrielle recommendation

    
    
    [super viewWillAppear:animated];
}

- (void)setShout:(Shout *)shout
{
    _shout = shout;
    [self updateUI];
}

- (void)updateUI
{
    if (self.shout) {
        if (self.shout.image) {
            self.shoutImageDropShadowView.image = [UIImage imageNamed:@"shout-image-place-holder"];
            NSURL *url = [NSURL URLWithString:[self.shout.image stringByAppendingFormat:@"--%d", kShoutImageSize]];
            [self.shoutImageView setImageWithURL:url placeholderImage:nil];
            
            [self.shoutImageView setHidden:NO];
            [self.shoutImageDropShadowView setHidden:NO];
        } else {
            [self.shoutImageView setHidden:YES];
            [self.shoutImageDropShadowView setHidden:YES];
        }
        
        self.shoutUsername.text = [NSString stringWithFormat:@"by %@", self.shout.username];

        self.shoutContent.text = self.shout.description;
        
        NSArray *shoutAgeStrings = [TimeUtilities shoutAgeToStrings:[TimeUtilities getShoutAge:self.shout.created]];
        
        self.shoutAgeLabel.text = [shoutAgeStrings firstObject];
        
        if (shoutAgeStrings.count > 1) {
            self.shoutAgeUnitLabel.text = [NSString stringWithFormat:@"%@ %@", [shoutAgeStrings objectAtIndex:1], NSLocalizedStringFromTable (@"ago", @"Strings", @"comment")];
        } else {
            //The space instead of blank is a hack for the view to stay in place (helps in autolayout)
            self.shoutAgeUnitLabel.text = @" ";
        }
        
        MKUserLocation *myLocation = [self.shoutVCDelegate getMyLocation];
        
        if (myLocation && myLocation.coordinate.longitude != 0 && myLocation.coordinate.latitude != 0) {
            NSArray *shoutDistanceStrings = [LocationUtilities formattedDistanceLat1:myLocation.coordinate.latitude lng1:myLocation.coordinate.longitude lat2:self.shout.lat lng2:self.shout.lng];
            self.shoutDistanceLabel.text = [shoutDistanceStrings firstObject];
            
            if (shoutDistanceStrings.count > 1) {
                self.shoutDistanceUnitLabel.text = [NSString stringWithFormat:@"%@ %@", [shoutDistanceStrings objectAtIndex:1], NSLocalizedStringFromTable (@"away", @"Strings", @"comment")];
            } else {
                //The space instead of blank is a hack for the view to stay in place (helps in autolayout)
                self.shoutDistanceUnitLabel.text = @" ";
            }
        } else {
            self.shoutDistanceLabel.text = @"";
            self.shoutDistanceUnitLabel.text = @"";
        }
    }
}

- (IBAction)shoutImageClicked:(UITapGestureRecognizer *)sender {    
    [self.shoutVCDelegate displayShoutImage:self.shout];
}

- (IBAction)backButtonClicked:(id)sender {
    [self.shoutVCDelegate endShoutSelectionModeInMapViewController];
}

- (IBAction)shoutZoomButtonClicked:(id)sender {
    [self.shoutVCDelegate animateMapWhenZoomOnShout:self.shout];
}

- (IBAction)flagButtonClicked:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedStringFromTable (@"flag_action_sheet_title", @"Strings", @"comment")
 delegate:self cancelButtonTitle:FLAG_ACTION_SHEET_CANCEL destructiveButtonTitle:nil otherButtonTitles:FLAG_ACTION_SHEET_OPTION_1, FLAG_ACTION_SHEET_OPTION_2, FLAG_ACTION_SHEET_OPTION_3, FLAG_ACTION_SHEET_OPTION_4, FLAG_ACTION_SHEET_OPTION_5, nil];
    
    [actionSheet showInView:self.shoutVCDelegate.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if (![buttonTitle isEqualToString:FLAG_ACTION_SHEET_CANCEL]) {
        [AFStreetShoutAPIClient reportShout:self.shout.identifier withMotive:buttonIndex AndExecute:nil Failure:nil];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedStringFromTable (@"flag_thanks_alert", @"Strings", @"comment")
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles: nil];
        [alert show];
    }
}

@end
