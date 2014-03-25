//
//  CreateShoutViewController.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/24/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "RefineShoutLocationViewController.h"
#import "Shout.h"
#import <CoreLocation/CLLocationManager.h>

@protocol CreateShoutViewControllerDelegate;

@interface CreateShoutViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate, RefineShoutLocationViewControllerDelegate, UIActionSheetDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) id <CreateShoutViewControllerDelegate> createShoutVCDelegate;

@property (strong, nonatomic) IBOutlet UIImage *sentImage;


@end

@protocol CreateShoutViewControllerDelegate

- (void)onShoutCreated:(Shout *)shout;

@end