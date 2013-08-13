//
//  SettingsTVC.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 8/1/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "SettingsTVC.h"

#define NOTIFICATION_RADIUS_PREFERENCE_TYPE @"Notification Radius"
#define DISTANCE_UNIT_PREFERENCE_TYPE @"Distance Unit"

@interface SettingsTVC ()

@property (weak, nonatomic) IBOutlet UILabel *notificationRadiusLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceUnitLabel;
@property (strong, nonatomic) NSArray *distanceUnitPreferences;
@property (strong, nonatomic) NSArray *notificationRadiusPreferences;

@end

@implementation SettingsTVC

- (NSArray *)distanceUnitPreferences
{
    return @[NSLocalizedStringFromTable (@"meters", @"Strings", @"comment"),
             NSLocalizedStringFromTable (@"miles", @"Strings", @"comment")];
}

- (NSArray *)notificationRadiusPreferences
{
    NSNumber *distanceUnitPreference = [[NSUserDefaults standardUserDefaults] objectForKey:DISTANCE_UNIT_PREFERENCE_TYPE];
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
}

- (void)updateDistanceUnitLabel
{
    NSNumber *distanceUnitPreferenceIndex = [[NSUserDefaults standardUserDefaults] objectForKey:DISTANCE_UNIT_PREFERENCE_TYPE];
    
    if (distanceUnitPreferenceIndex) {
        self.distanceUnitLabel.text = self.distanceUnitPreferences[[distanceUnitPreferenceIndex integerValue]];
    } else {
        self.distanceUnitLabel.text = self.distanceUnitPreferences[0];
    }
}

- (void)updateNotificationRadiusLabel
{
    NSNumber *notificationRadiusPreferenceIndex = [[NSUserDefaults standardUserDefaults] objectForKey:NOTIFICATION_RADIUS_PREFERENCE_TYPE];
    
    if (notificationRadiusPreferenceIndex) {
        self.notificationRadiusLabel.text = self.notificationRadiusPreferences[[notificationRadiusPreferenceIndex integerValue]];
    } else {
        self.notificationRadiusLabel.text = [self.notificationRadiusPreferences lastObject];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillDisappear:animated];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
        [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
    
    switch (indexPath.row) {
        case 0:
            break;
        case 1:
            break;
        case 2:
            [self feedBackClicked];
            break;
        case 3:
            [self rateMeClicked];
            break;
    }
}

- (void)feedBackClicked
{
    [TestFlight openFeedbackView];
}

- (void)rateMeClicked
{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Not yet implemented" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [message show];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"Notification Radius"]) {
                NSArray *pickerData = self.notificationRadiusPreferences;
                NSString *preferenceType = NOTIFICATION_RADIUS_PREFERENCE_TYPE;
                
                [segue.destinationViewController performSelector:@selector(setPickerData:) withObject:pickerData];
                [segue.destinationViewController performSelector:@selector(setPreferenceType:) withObject:preferenceType];
            } else if ([segue.identifier isEqualToString:@"Distance Unit"]) {
                NSArray *pickerData = self.distanceUnitPreferences;
                NSString *preferenceType = DISTANCE_UNIT_PREFERENCE_TYPE;
                
                [segue.destinationViewController performSelector:@selector(setPickerData:) withObject:pickerData];
                [segue.destinationViewController performSelector:@selector(setPreferenceType:) withObject:preferenceType];
            }
            
            ((SettingPickerViewController *)[segue destinationViewController]).settingPickerVCDelegate = self;
        }
    } 
}

- (void)dismissSettingPickerModal:(SettingPickerViewController *)settingPickerViewController
{
    if ([settingPickerViewController.preferenceType isEqualToString:NOTIFICATION_RADIUS_PREFERENCE_TYPE]) {
        //TODO: send device info
        
        [self updateNotificationRadiusLabel];
    } else if ([settingPickerViewController.preferenceType isEqualToString:DISTANCE_UNIT_PREFERENCE_TYPE]) {
        [self updateDistanceUnitLabel];
        [self updateNotificationRadiusLabel];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
