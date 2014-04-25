//
//  CreateSnapbyViewController.h
//  snapby-ios
//
//  Created by Bastien Beurier on 7/24/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "RefineSnapbyLocationViewController.h"
#import "Snapby.h"


@protocol CreateSnapbyViewControllerDelegate;

@interface CreateSnapbyViewController : UIViewController <RefineSnapbyLocationViewControllerDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) id <CreateSnapbyViewControllerDelegate> createSnapbyVCDelegate;

@property (strong, nonatomic) IBOutlet UIImage *sentImage;
@property (strong, nonatomic) CLLocation *snapbyLocation;

@end

@protocol CreateSnapbyViewControllerDelegate

- (void)onSnapbyCreated;

@end