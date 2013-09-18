//
//  ImageUtilities.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 9/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "ImageUtilities.h"

@implementation ImageUtilities

//Code from http://stackoverflow.com/questions/17712797/ios-custom-uiimagepickercontroller-camera-crop-to-square
//TODO: check for iphone 5
+ (void)addSquareBoundsToImagePicker:(UIImagePickerController *)imagePickerController
{
    //Create camera overlay
    CGRect f = imagePickerController.view.bounds;
    f.size.height -= imagePickerController.navigationBar.bounds.size.height;
    CGFloat barHeight = (f.size.height - f.size.width) / 2;
    UIGraphicsBeginImageContext(f.size);
    [[UIColor colorWithWhite:0 alpha:.5] set];
    UIRectFillUsingBlendMode(CGRectMake(0, 0, f.size.width, barHeight), kCGBlendModeNormal);
    UIRectFillUsingBlendMode(CGRectMake(0, f.size.height - barHeight, f.size.width, barHeight), kCGBlendModeNormal);
    UIImage *overlayImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *overlayIV = [[UIImageView alloc] initWithFrame:f];
    overlayIV.image = overlayImage;
    [imagePickerController.cameraOverlayView addSubview:overlayIV];
}

+ (UIImage *)cropImageToSquare:(UIImage *)image
{
    //Crop the image to a square
    CGSize imageSize = image.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    if (width != height) {
        CGFloat newDimension = MIN(width, height);
        CGFloat widthOffset = (width - newDimension) / 2;
        CGFloat heightOffset = (height - newDimension) / 2;
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(newDimension, newDimension), NO, 0.);
        [image drawAtPoint:CGPointMake(-widthOffset, -heightOffset)
                 blendMode:kCGBlendModeCopy
                     alpha:1.];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return image;
}

+ (UIImage *)resizeImage:(UIImage *)image withSize:(NSUInteger)size
{
    CGSize imageSize;
    imageSize.height = size;
    imageSize.width = size;
    
    UIGraphicsBeginImageContext(imageSize);
    [image drawInRect:CGRectMake(0,0, imageSize.width, imageSize.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
