//
//  CreateShoutViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/24/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "CreateShoutViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Constants.h"
#import "AFStreetShoutAPIClient.h"

@interface CreateShoutViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameView;
@property (weak, nonatomic) IBOutlet UITextView *descriptionView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *charCount;

@end

@implementation CreateShoutViewController

- (void)viewWillAppear:(BOOL)animated {
    CLLocationCoordinate2D location;

//        location.latitude = self.myLocation.coordinate.latitude;
//        location.longitude = self.myLocation.coordinate.longitude;
        //TODO: REMOVE!!
    location.latitude = 37.753615;
    location.longitude = -122.417578;
    MKCoordinateRegion shoutRegion = MKCoordinateRegionMakeWithDistance(location, kCreateShoutDistance, kCreateShoutDistance);
        
    [self.mapView setRegion:shoutRegion animated:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.usernameView.delegate = self;
    self.descriptionView.delegate = self;

    //discriptionView formatting
    self.descriptionView.layer.cornerRadius = 5;
    self.descriptionView.clipsToBounds = YES;
    [self.descriptionView.layer setBorderColor:[[[UIColor grayColor]colorWithAlphaComponent:0.5] CGColor]];
    [self.descriptionView.layer setBorderWidth:2.0];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    } else {
        NSInteger charCount = [textView.text length] + [text length] - range.length;
        NSInteger remainingCharCount = kShoutMaxLength - charCount;
        NSString *countStr = [NSString stringWithFormat:@"%d", remainingCharCount];
        self.charCount.text = [countStr stringByAppendingFormat:@" %@", NSLocalizedStringFromTable (@"characters", @"Strings", @"comment")];
        return YES;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.descriptionView becomeFirstResponder];
    return YES;
}

- (IBAction)createShoutClicked:(id)sender {
    BOOL error = NO;
    
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@""
                                                      message:@""
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];

    if (self.usernameView.text.length == 0) {
        message.title = NSLocalizedStringFromTable (@"incorrect_username", @"Strings", @"comment");
        message.message = NSLocalizedStringFromTable (@"username_blank", @"Strings", @"comment");
        error = YES;
    }
    
    if (self.usernameView.text.length > kMaxUsernameLength) {
        message.title = NSLocalizedStringFromTable (@"incorrect_username", @"Strings", @"comment");
        NSString *maxChars = [NSString stringWithFormat:@" (max: %d).", kMaxUsernameLength];
        message.message = [(NSLocalizedStringFromTable (@"username_too_long", @"Strings", @"comment")) stringByAppendingString:maxChars];
        error = YES;
    }

    if (self.descriptionView.text.length == 0) {
        message.title = NSLocalizedStringFromTable (@"incorrect_shout_description", @"Strings", @"comment");
        message.message = NSLocalizedStringFromTable (@"shout_description_blank", @"Strings", @"comment");
        error = YES;
    }
    
    if (self.descriptionView.text.length > kMaxShoutDescriptionLength) {
        message.title = NSLocalizedStringFromTable (@"incorrect_shout_description", @"Strings", @"comment");
        NSString *maxChars = [NSString stringWithFormat:@" (max: %d).", kMaxShoutDescriptionLength];
        message.message = [(NSLocalizedStringFromTable (@"shout_description_too_long", @"Strings", @"comment")) stringByAppendingString:maxChars];
        error = YES;
    }
    
    if (error) {
        [message show];
        return;
    } else {
        //TODO: save username
        [self createShout];
    }
}

- (void)createShout
{
    [AFStreetShoutAPIClient createShoutWithLat:self.myLocation.coordinate.latitude
                                           Lng:self.myLocation.coordinate.longitude
                                      Username:self.usernameView.text
                                   Description:self.descriptionView.text
                                         Image:nil
                             AndExecuteSuccess:nil Failure:nil];
}

- (IBAction)cancelShoutClicked:(id)sender {
    [self.createShoutVCDelegate dismissCreateShoutModal];
}

@end
