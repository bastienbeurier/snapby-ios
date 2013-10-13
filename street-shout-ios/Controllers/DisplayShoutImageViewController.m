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
#import "ImageUtilities.h"

#define IMAGE_CORNER_RADIUS 20

@interface DisplayShoutImageViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *shoutImageView;
@property (weak, nonatomic) IBOutlet UIImageView *shoutImageDropShadowView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIView *innedShadowingView;

@end

@implementation DisplayShoutImageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.shoutImageView.image = [UIImage imageNamed:@"shout-image-place-holder-square"];
    NSURL *url = [NSURL URLWithString:[self.shout.image stringByAppendingFormat:@"--%d", kShoutImageSize]];
    [self.shoutImageView setImageWithURL:url placeholderImage:nil];
    
    [self.shoutImageView.layer setCornerRadius:IMAGE_CORNER_RADIUS];
    self.shoutImageView.clipsToBounds = YES;
    
    [self.shoutImageDropShadowView.layer setCornerRadius:IMAGE_CORNER_RADIUS];
    
    //Drop shadows
    [ImageUtilities addDropShadowToView:self.shoutImageDropShadowView];
    [ImageUtilities addDropShadowToView:self.backButton];
    
    //Inner shadow
    [ImageUtilities addInnerShadowToView:self.innedShadowingView];
}

- (IBAction)backButtonClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
