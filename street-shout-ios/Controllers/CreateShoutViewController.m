//
//  CreateShoutViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/24/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "CreateShoutViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <MapKit/MapKit.h>
#import "Constants.h"

@interface CreateShoutViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameView;
@property (weak, nonatomic) IBOutlet UITextView *descriptionView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) MKUserLocation *myLocation;
@property (weak, nonatomic) IBOutlet UILabel *charCount;

@end

@implementation CreateShoutViewController

- (MKUserLocation *)myLocation
{
    return self.mapView.userLocation;
}

- (void)viewWillAppear:(BOOL)animated {
    //TODO: Probably grab user location before segue
    MKUserLocation *userLocation = self.mapView.userLocation;
    CLLocationCoordinate2D location;
    if (userLocation.coordinate.latitude && userLocation.coordinate.longitude) {
        location.latitude = userLocation.coordinate.latitude;
        location.longitude = userLocation.coordinate.longitude;
        MKCoordinateRegion shoutRegion = MKCoordinateRegionMakeWithDistance(location, kCreateShoutDistance, kCreateShoutDistance);
        
        [self.mapView setRegion:shoutRegion animated:NO];
    } else {
        //TODO: handle that case
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

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
        self.charCount.text = [countStr stringByAppendingFormat:@" characters"];
        return YES;
    }
}

- (IBAction)createShoutClicked:(id)sender {
}

- (IBAction)cancelShoutClicked:(id)sender {
    [self.createShoutVCDelegate dismissCreateShoutModal];
}

@end
