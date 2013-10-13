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
#import "UIDevice-Hardware.h"

#define APP_ID 123 //id from iTunesConnect

@interface SettingsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *notificationRadiusLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *rateMeLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *notificationRadiusButton;
@property (weak, nonatomic) IBOutlet UIButton *distanceUnitButton;
@property (weak, nonatomic) IBOutlet UIButton *feedbackButton;
@property (weak, nonatomic) IBOutlet UIButton *ratemeButton;
@property (weak, nonatomic) IBOutlet UIView *innterShadowingView;
@property (strong, nonatomic) NSArray *distanceUnitPreferences;
@property (strong, nonatomic) NSArray *notificationRadiusPreferences;

@end

@implementation SettingsViewController

- (NSArray *)distanceUnitPreferences
{
    return @[NSLocalizedStringFromTable (@"meters", @"Strings", @"comment"),
             NSLocalizedStringFromTable (@"miles", @"Strings", @"comment")];
}

- (NSArray *)notificationRadiusPreferences
{
    NSNumber *distanceUnitPreference = [[NSUserDefaults standardUserDefaults] objectForKey:DISTANCE_UNIT_PREF];
    if (!distanceUnitPreference || [distanceUnitPreference integerValue] == 0) {
        return @[NSLocalizedStringFromTable (@"none", @"Strings", @"comment"),
                 NSLocalizedStringFromTable (@"100m", @"Strings", @"comment"),
                 NSLocalizedStringFromTable (@"1km", @"Strings", @"comment"),
                 NSLocalizedStringFromTable (@"10km", @"Strings", @"comment")];
    } else {
        return @[NSLocalizedStringFromTable (@"none", @"Strings", @"comment"),
                 NSLocalizedStringFromTable (@"100yd", @"Strings", @"comment"),
                 NSLocalizedStringFromTable (@"1mi", @"Strings", @"comment"),
                 NSLocalizedStringFromTable (@"10mi", @"Strings", @"comment")];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updateDistanceUnitLabel];
    [self updateNotificationRadiusLabel];
    
    self.rateMeLabel.text = [self.rateMeLabel.text stringByAppendingFormat:@" (v.%@)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    
    //Round corners
    NSUInteger buttonHeight = self.notificationRadiusButton.bounds.size.height;
    self.notificationRadiusButton.layer.cornerRadius = buttonHeight/2;
    self.distanceUnitButton.layer.cornerRadius = buttonHeight/2;
    self.feedbackButton.layer.cornerRadius = buttonHeight/2;
    self.ratemeButton.layer.cornerRadius = buttonHeight/2;
    
    //Drop shadows
    [ImageUtilities addDropShadowToView:self.backButton];
    [ImageUtilities addDropShadowToView:self.notificationRadiusButton];
    [ImageUtilities addDropShadowToView:self.distanceUnitButton];
    [ImageUtilities addDropShadowToView:self.feedbackButton];
    [ImageUtilities addDropShadowToView:self.ratemeButton];
    
    //Inner shadow
    [ImageUtilities addInnerShadowToView:self.innterShadowingView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.settingsViewControllerDelegate refreshShouts];
    
    [super viewWillDisappear:animated];
}

- (void)updateDistanceUnitLabel
{
    NSNumber *distanceUnitPreferenceIndex = [[NSUserDefaults standardUserDefaults] objectForKey:DISTANCE_UNIT_PREF];
    
    if (distanceUnitPreferenceIndex) {
        self.distanceUnitLabel.text = self.distanceUnitPreferences[[distanceUnitPreferenceIndex integerValue]];
    } else {
        self.distanceUnitLabel.text = self.distanceUnitPreferences[0];
    }
}

- (void)updateNotificationRadiusLabel
{
    NSNumber *notificationRadiusPreferenceIndex = [[NSUserDefaults standardUserDefaults] objectForKey:NOTIFICATION_RADIUS_PREF];
    
    if (notificationRadiusPreferenceIndex) {
        self.notificationRadiusLabel.text = self.notificationRadiusPreferences[[notificationRadiusPreferenceIndex integerValue]];
    } else {
        self.notificationRadiusLabel.text = [self.notificationRadiusPreferences lastObject];
    }
}

- (IBAction)feedbackClicked:(id)sender {
    NSString *email = @"mailto:info@street-shout.com";
    
    email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}

- (IBAction)rateMeClicked:(id)sender {
    if ([GeneralUtilities connected]) {
        //        NSString *reviewURL = [NSString stringWithFormat:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%d",APP_ID];
        //
        //        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.com/apps/shout"]];
    } else {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment")
                                                          message:nil
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
    }
}

- (IBAction)backButtonClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Notification Radius"]) {
        NSArray *pickerData = self.notificationRadiusPreferences;
        NSString *preferenceType = NOTIFICATION_RADIUS_PREF;
                
        [segue.destinationViewController performSelector:@selector(setPickerData:) withObject:pickerData];
        [segue.destinationViewController performSelector:@selector(setPreferenceType:) withObject:preferenceType];
    } else if ([segue.identifier isEqualToString:@"Distance Unit"]) {
        NSArray *pickerData = self.distanceUnitPreferences;
        NSString *preferenceType = DISTANCE_UNIT_PREF;
                
        [segue.destinationViewController
         performSelector:@selector(setPickerData:) withObject:pickerData];
        [segue.destinationViewController performSelector:@selector(setPreferenceType:) withObject:preferenceType];
    }
            
    ((SettingPickerViewController *)[segue destinationViewController]).settingPickerVCDelegate = self;
}

- (void)dismissSettingPickerModal:(SettingPickerViewController *)settingPickerViewController
{
    if ([settingPickerViewController.preferenceType isEqualToString:NOTIFICATION_RADIUS_PREF]) {
        //TODO: send device info
        
        [self updateNotificationRadiusLabel];
    } else if ([settingPickerViewController.preferenceType isEqualToString:DISTANCE_UNIT_PREF]) {
        [self updateDistanceUnitLabel];
        [self updateNotificationRadiusLabel];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)sendDeviceInfo
{
    [self.settingsViewControllerDelegate sendDeviceInfo];
}

- (void)viewDidUnload {
    [self setRateMeLabel:nil];
    [super viewDidUnload];
}

@end
