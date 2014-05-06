//
//  TutorialViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 5/5/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import "TutorialViewController.h"

@interface TutorialViewController ()

@property (weak, nonatomic) IBOutlet UILabel *tutorialLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) NSUInteger page;

@end

@implementation TutorialViewController

- (id)initWithPage:(NSUInteger)page
{
    self = [super initWithNibName:@"TutorialView" bundle:nil];
    if (self) {
        self.page = page;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.page == 0) {
        self.imageView.image = [UIImage imageNamed:@"tutorial-logo"];
        self.tutorialLabel.text = @"Snapby is all about local fun.";
    } else if (self.page == 1) {
        self.imageView.image = [UIImage imageNamed:@"tutorial-camera"];
        self.tutorialLabel.text = @"Take a picture...";
    } else if (self.page == 2) {
        self.imageView.image = [UIImage imageNamed:@"tutorial-perimeter"];
        self.tutorialLabel.text = @"...it’s only visible nearby!";
    } else {
        self.imageView.image = [UIImage imageNamed:@"tutorial-interaction"];
        self.tutorialLabel.text = @"Discover your neighbors' photos now! ";
    }
}

@end
