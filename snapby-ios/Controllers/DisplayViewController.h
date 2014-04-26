//
//  SnapbyViewController.h
//  snapby-ios
//
//  Created by Bastien Beurier on 7/23/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Snapby.h"
#import <MapKit/MapKit.h>
#import "CommentsViewController.h"
#import "User.h"

@protocol SnapbyVCDelegate;

@interface DisplayViewController : UIViewController <UIActionSheetDelegate>

@property (strong, nonatomic) Snapby *snapby;

@property (weak, nonatomic) id <SnapbyVCDelegate> displayVCDelegate;

@end

@protocol SnapbyVCDelegate

- (void)refreshSnapbiesFromDisplay;

@end
