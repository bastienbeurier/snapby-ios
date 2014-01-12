//
//  WelcomeViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 1/10/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import "WelcomeViewController.h"
#import "SessionUtilities.h"

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController

- (IBAction)signupButtonClicked:(id)sender {
    [self performSegueWithIdentifier:@"Signup Push Segue" sender:nil];
}


- (IBAction)signinButtonClicked:(id)sender {
    [self performSegueWithIdentifier:@"Signin Push Segue" sender:nil];
}

- (void)viewDidLoad
{
    //Check if user is logged in
    if ([SessionUtilities loggedIn]) {
        [self performSegueWithIdentifier:@"Navigation Push Segue From Welcome" sender:nil];
    }
}

@end