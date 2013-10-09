//
//  DisplayShoutImageViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 8/14/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "DisplayShoutImageViewController.h"
#import "Constants.h"
#import "UIImageView+AFNetworking.h"

#define IMAGE_CORNER_RADIUS 20

@interface DisplayShoutImageViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *shoutImageView;
@property (weak, nonatomic) IBOutlet UIImageView *shoutImageDropShadowView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@end

@implementation DisplayShoutImageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.shoutImageView.image = [UIImage imageNamed:@"shout-image-place-holder-square"];
    NSURL *url = [NSURL URLWithString:[self.shout.image stringByAppendingFormat:@"--%d", kShoutImageSize]];
    [self.shoutImageView setImageWithURL:url placeholderImage:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.shoutImageView.layer setCornerRadius:IMAGE_CORNER_RADIUS];
    self.shoutImageView.clipsToBounds = YES;
    
    [self.shoutImageDropShadowView.layer setCornerRadius:IMAGE_CORNER_RADIUS];
    self.shoutImageDropShadowView.clipsToBounds = NO;
    
    [self.shoutImageDropShadowView.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.shoutImageDropShadowView.layer setShadowOpacity:0.3];
    [self.shoutImageDropShadowView.layer setShadowRadius:1.5];
    
    self.backButton.clipsToBounds = NO;
    [self.backButton.layer setShadowOffset:CGSizeMake(kDropShadowX, kDropShadowY)];
    
    [self.backButton.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.backButton.layer setShadowOpacity:0.3];
    [self.backButton.layer setShadowRadius:1.5];
    
    [self.backButton.layer setShadowOffset:CGSizeMake(kDropShadowX, kDropShadowY)];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [super viewWillDisappear:animated];
}

- (IBAction)backButtonClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
