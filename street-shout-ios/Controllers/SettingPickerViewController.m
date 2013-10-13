//
//  SettingPickerViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 8/1/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "SettingPickerViewController.h"
#import "Constants.h"
#import "ImageUtilities.h"

@interface SettingPickerViewController ()

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIView *innerShadowingView;

@end

@implementation SettingPickerViewController

- (void)viewDidLayoutSubviews
{
    //Can initialize Picker View in viewWillAppear because it won't select the last row if needed (bug)
    if ([self.preferenceType isEqualToString:NOTIFICATION_RADIUS_PREF]) {
        NSNumber *index = [[NSUserDefaults standardUserDefaults] objectForKey:NOTIFICATION_RADIUS_PREF];
        if (index) {
            [self.pickerView selectRow:[index integerValue] inComponent:0 animated:NO];
        } else {
            [self.pickerView selectRow:kDefaultNotificationRadiusIndex inComponent:0 animated:NO];
        }
    } else if ([self.preferenceType isEqualToString:DISTANCE_UNIT_PREF]) {
        NSNumber *index = [[NSUserDefaults standardUserDefaults] objectForKey:DISTANCE_UNIT_PREF];
        if (index) {
            [self.pickerView selectRow:[index integerValue] inComponent:0 animated:NO];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Round corners
    NSUInteger buttonHeight = self.doneButton.bounds.size.height;
    self.doneButton.layer.cornerRadius = buttonHeight/2;
    
    //Drop shadows
    [ImageUtilities addDropShadowToView:self.doneButton];
    
    //Inner shasow
    [ImageUtilities addInnerShadowToView:self.innerShadowingView];
}

- (IBAction)validateButtonClicked:(id)sender {
    NSNumber *selectedRow = [NSNumber numberWithInt:[self.pickerView selectedRowInComponent:0]];
    [[NSUserDefaults standardUserDefaults] setObject:selectedRow forKey:self.preferenceType];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.settingPickerVCDelegate dismissSettingPickerModal:self];
    [self.settingPickerVCDelegate sendDeviceInfo];
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.pickerData.count;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.pickerData objectAtIndex:row];
}

@end
