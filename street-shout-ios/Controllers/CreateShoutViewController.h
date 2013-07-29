//
//  CreateShoutViewController.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/24/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@protocol CreateShoutViewControllerDelegate;

@interface CreateShoutViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) id <CreateShoutViewControllerDelegate> createShoutVCDelegate;
@property (strong, nonatomic) MKUserLocation *myLocation;

@end

@protocol CreateShoutViewControllerDelegate

- (void)dismissCreateShoutModal;

@end