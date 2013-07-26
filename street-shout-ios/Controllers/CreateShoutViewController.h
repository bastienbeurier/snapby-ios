//
//  CreateShoutViewController.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/24/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CreateShoutViewControllerDelegate;

@interface CreateShoutViewController : UIViewController <UITextViewDelegate>

@property (weak, nonatomic) id <CreateShoutViewControllerDelegate> createShoutVCDelegate;

@end

@protocol CreateShoutViewControllerDelegate

- (void)dismissCreateShoutModal;

@end