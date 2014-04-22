//
//  ExploreSnapbyViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 4/21/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import "ExploreSnapbyViewController.h"
#import "UIImageView+AFNetworking.h"
#import "Snapby.h"

@interface ExploreSnapbyViewController ()

@property (nonatomic, strong) Snapby *snapby;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIView *view;

@end

@implementation ExploreSnapbyViewController

- (id)initWithSnapby:(Snapby *)snapby
{
    if (self = [super initWithNibName:@"ExploreSnapby" bundle:nil])
    {
        self.snapby = snapby;
    }
    return self;
}

- (void)viewDidLoad
{
    self.imageView.clipsToBounds = YES;
    [self.imageView setImageWithURL:[self.snapby getSnapbyImageURL] placeholderImage:nil];
}

@end
