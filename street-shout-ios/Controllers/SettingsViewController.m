//
//  SettingsViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 10/12/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "SettingsViewController.h"
#import "TestFlight.h"
#import "Constants.h"
#import "GeneralUtilities.h"
#import "ImageUtilities.h"
#import "SessionUtilities.h"
#import "AFStreetShoutAPIClient.h"


@interface SettingsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *rateMeLabel;
@property (weak, nonatomic) IBOutlet UIButton *distanceUnitButton;
@property (weak, nonatomic) IBOutlet UIButton *feedbackButton;
@property (weak, nonatomic) IBOutlet UIButton *ratemeButton;
@property (weak, nonatomic) IBOutlet UIButton *logOutButton;
@property (strong, nonatomic) NSArray *distanceUnitPreferences;
@property (weak, nonatomic) IBOutlet UISegmentedControl *unitSegmentedControl;

@end

@implementation SettingsViewController

- (NSArray *)distanceUnitPreferences
{
    return @[NSLocalizedStringFromTable (@"meters", @"Strings", @"comment"),
             NSLocalizedStringFromTable (@"miles", @"Strings", @"comment")];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Nav Bar
    [ImageUtilities drawCustomNavBarWithLeftItem:@"back" rightItem:nil title:@"Settings" sizeBig:YES inViewController:self];
    
    self.rateMeLabel.text = [self.rateMeLabel.text stringByAppendingFormat:@" (v.%@)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    
    //Set distance unit pref if exists, update user prefs
    NSNumber *unitPref = [[NSUserDefaults standardUserDefaults] objectForKey:DISTANCE_UNIT_PREF];
    self.unitSegmentedControl.selectedSegmentIndex = unitPref ? [unitPref integerValue] : 0;
    [self unitSegmentedControlValueChanged:nil];
    
    //Round corners
    NSUInteger buttonHeight = self.distanceUnitButton.bounds.size.height;
    self.distanceUnitButton.layer.cornerRadius = buttonHeight/2;
    self.feedbackButton.layer.cornerRadius = buttonHeight/2;
    self.ratemeButton.layer.cornerRadius = buttonHeight/2;
    self.logOutButton.layer.cornerRadius = buttonHeight/2;
    
}

- (IBAction)unitSegmentedControlValueChanged:(UISegmentedControl *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:self.unitSegmentedControl.selectedSegmentIndex] forKey:DISTANCE_UNIT_PREF];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)feedbackClicked:(id)sender {
    NSString *email = @"mailto:info@street-shout.com";
    
    email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}

- (IBAction)rateMeClicked:(id)sender {
    if ([GeneralUtilities connected]) {
        [GeneralUtilities redirectToAppStore];
    } else {
        [GeneralUtilities showMessage:nil withTitle:NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment")];
    }
}

- (void)viewDidUnload {
    [self setRateMeLabel:nil];
    [super viewDidUnload];
}

- (IBAction)logoutButtonClicked:(id)sender {
    [SessionUtilities redirectToSignIn];
}

- (void)backButtonClicked
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
