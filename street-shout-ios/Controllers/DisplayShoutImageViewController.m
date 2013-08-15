//
//  DisplayShoutImageViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 8/14/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "DisplayShoutImageViewController.h"

@interface DisplayShoutImageViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *shoutImageView;

@end

@implementation DisplayShoutImageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.shoutImageView.image = self.shoutImage;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [super viewWillDisappear:animated];
}

@end
