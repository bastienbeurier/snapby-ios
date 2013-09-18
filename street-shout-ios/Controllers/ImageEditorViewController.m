//
//  ImageEditorViewController.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 9/18/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "ImageEditorViewController.h"

@interface ImageEditorViewController ()

@end

@implementation ImageEditorViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        self.cropSize = CGSizeMake(320,320);
        self.minimumScale = 0.2;
        self.maximumScale = 10;
    }
    return self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.saveButton = nil;
}

@end
