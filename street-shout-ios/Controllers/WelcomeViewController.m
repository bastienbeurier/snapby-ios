//
//  WelcomeViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/10/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "WelcomeViewController.h"
#import "SessionUtilities.h"
#import "ImageUtilities.h"

@interface WelcomeViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *welcomeImageView;
@property (weak, nonatomic) IBOutlet UIButton *facebookButtonView;
@property (weak, nonatomic) IBOutlet UIButton *signupButtonView;
@property (weak, nonatomic) IBOutlet UILabel *facebookFirstLabel;
@property (weak, nonatomic) IBOutlet UILabel *facebookSecondLabel;
@property (weak, nonatomic) IBOutlet UILabel *signupFirstLabel;
@property (weak, nonatomic) IBOutlet UILabel *signupSecondLabel;


@end

@implementation WelcomeViewController

- (void)viewDidLoad
{
    //Check if user is logged in
    if ([SessionUtilities loggedIn]) {
        [self performSegueWithIdentifier:@"Navigation Push Segue From Welcome" sender:nil];
    }
    
    //Set background image
    NSString *filename = @"Welcome.png";
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    if (screenRect.size.height == 568.0f) {
        filename = [filename stringByReplacingOccurrencesOfString:@".png" withString:@"-568h.png"];
    }
    self.welcomeImageView.image = [UIImage imageNamed:filename];
    
    //Round corners
    NSUInteger buttonHeight = self.facebookButtonView.bounds.size.height;
    self.facebookButtonView.layer.cornerRadius = buttonHeight/2;
    self.signupButtonView.layer.cornerRadius = buttonHeight/2;
    
    //Set button borders
    [[self.signupButtonView layer] setBorderWidth:2.0f];
    [[self.signupButtonView layer] setBorderColor:[UIColor whiteColor].CGColor];
    [[self.facebookButtonView layer] setBorderWidth:2.0f];
    [[self.facebookButtonView layer] setBorderColor:[ImageUtilities getFacebookBlue].CGColor];
}

- (IBAction)facebookButtonStartedClicking:(id)sender {
    self.facebookFirstLabel.textColor = [UIColor grayColor];
    self.facebookSecondLabel.textColor = [UIColor grayColor];
    [[self.facebookButtonView layer] setBorderColor:[UIColor grayColor].CGColor];
}

- (IBAction)facebookButtonClicked:(id)sender {
    self.facebookFirstLabel.textColor = [ImageUtilities getFacebookBlue];
    self.facebookSecondLabel.textColor = [ImageUtilities getFacebookBlue];
    [[self.facebookButtonView layer] setBorderColor:[ImageUtilities getFacebookBlue].CGColor];
}

- (IBAction)signupButtonDidCancelledClicking:(id)sender {
    self.facebookFirstLabel.textColor = [ImageUtilities getFacebookBlue];
    self.facebookSecondLabel.textColor = [ImageUtilities getFacebookBlue];
    [[self.facebookButtonView layer] setBorderColor:[ImageUtilities getFacebookBlue].CGColor];
}


- (IBAction)signupButtonStartedClicking:(id)sender {
    self.signupFirstLabel.textColor = [UIColor grayColor];
    self.signupSecondLabel.textColor = [UIColor grayColor];
    [[self.signupButtonView layer] setBorderColor:[UIColor grayColor].CGColor];
}


- (IBAction)signupButtonClicked:(id)sender {
    self.signupFirstLabel.textColor = [UIColor whiteColor];
    self.signupSecondLabel.textColor = [UIColor whiteColor];
    [[self.signupButtonView layer] setBorderColor:[UIColor whiteColor].CGColor];
    [self performSegueWithIdentifier:@"Signup Push Segue" sender:nil];
}

- (IBAction)signupButtonCancelledClicking:(id)sender {
    self.signupFirstLabel.textColor = [UIColor whiteColor];
    self.signupSecondLabel.textColor = [UIColor whiteColor];
    [[self.signupButtonView layer] setBorderColor:[UIColor whiteColor].CGColor];
}


- (IBAction)signinButtonClicked:(id)sender {
    [self performSegueWithIdentifier:@"Signin Push Segue" sender:nil];
}



@end