//
//  SnapbyViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 7/23/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "DisplayViewController.h"
#import "UIImageView+AFNetworking.h"

@interface DisplayViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *snapbyImageView;
@property (weak, nonatomic) IBOutlet UIImageView *snapbyThumbView;

@end

@implementation DisplayViewController

- (void)viewDidLoad
{
    [self updateUI];
    
    [super viewDidLoad];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)updateUI
{
    if (self.snapby) {
        
        //Preload thumb
        [self.snapbyThumbView setImageWithURL:[self.snapby getSnapbyThumbURL]];
        // Get image
        [self.snapbyImageView setImageWithURL:[self.snapby getSnapbyImageURL] placeholderImage:nil];
    }
}

- (IBAction)snapbyImageClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
