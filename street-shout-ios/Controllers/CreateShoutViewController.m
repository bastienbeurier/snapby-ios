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
#import "LocationUtilities.h"

@interface CreateShoutViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameView;
@property (weak, nonatomic) IBOutlet UITextView *descriptionView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *charCount;
@property (strong, nonatomic) MKPointAnnotation *shoutAnnotation;

@end

@implementation CreateShoutViewController

- (void)viewWillAppear:(BOOL)animated {
    [LocationUtilities animateMap:self.mapView ToLatitude:self.shoutLocation.coordinate.latitude Longitude:self.shoutLocation.coordinate.longitude WithDistance:2*kShoutRadius Animated:NO];
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    MKPointAnnotation *shoutAnnotation = [[MKPointAnnotation alloc] init];
    shoutAnnotation.coordinate = self.shoutLocation.coordinate;
    [self.mapView addAnnotation:shoutAnnotation];
}

- (void)updateCreateShoutLocation:(CLLocation *)shoutLocation
{
    self.shoutLocation = shoutLocation;
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
    
    typedef void (^SuccessBlock)(Shout *);
    SuccessBlock successBlock = ^(Shout *shout) {
        [self.createShoutVCDelegate dismissCreateShoutModal];
    };
    
    typedef void (^FailureBlock)();
    FailureBlock failureBlock = ^{
        NSString *title = NSLocalizedStringFromTable (@"create_shout_failed_title", @"Strings", @"comment");
        NSString *message = NSLocalizedStringFromTable (@"create_shout_failed_message", @"Strings", @"comment");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    };
    
    [AFStreetShoutAPIClient createShoutWithLat:self.shoutLocation.coordinate.latitude
                                           Lng:self.shoutLocation.coordinate.longitude
                                      Username:self.usernameView.text
                                   Description:self.descriptionView.text
                                         Image:nil
                             AndExecuteSuccess:successBlock
                                       Failure:failureBlock];
}

- (IBAction)cancelShoutClicked:(id)sender {
    [self.createShoutVCDelegate dismissCreateShoutModal];
}

- (IBAction)settingsMapClicked:(id)sender {
    [self performSegueWithIdentifier:@"Refine Shout Location" sender:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Refine Shout Location"]) {
        ((RefineShoutLocationViewController *) [segue destinationViewController]).myLocation = self.myLocation;
        ((RefineShoutLocationViewController *) [segue destinationViewController]).refineShoutLocationVCDelegate = self;
    }
}

- (void)dismissRefineShoutLocationModal {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
