//
//  SettingPickerViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 8/1/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "SettingPickerViewController.h"

@interface SettingPickerViewController ()

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;

@end

@implementation SettingPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    //Initialize picker to "1km" notification range
    if ([self.preferenceType isEqualToString:@"Notification Radius"]) {
        [self.pickerView selectRow:2 inComponent:0 animated:NO];
    };
}

- (IBAction)validateButtonClicked:(id)sender {
    NSNumber *selectedRow = [NSNumber numberWithInt:[self.pickerView selectedRowInComponent:0]];
    [[NSUserDefaults standardUserDefaults] setObject:selectedRow forKey:self.preferenceType];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.settingPickerVCDelegate dismissSettingPickerModal:self];
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
