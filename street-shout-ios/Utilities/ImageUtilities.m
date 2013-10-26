//
//  ImageUtilities.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 9/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "ImageUtilities.h"
#import "Constants.h"

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

//From http://stackoverflow.com/questions/14917770/finding-the-biggest-centered-square-from-a-landscape-or-a-portrait-uiimage-and-s
+ (UIImage*) cropBiggestCenteredSquareImageFromImage:(UIImage*)image withSide:(CGFloat)side
{
    // Get size of current image
    CGSize size = [image size];
    if( size.width == size.height && size.width == side){
        return image;
    }
    
    CGSize newSize = CGSizeMake(side, side);
    double ratio;
    double delta;
    CGPoint offset;
    
    //make a new square size, that is the resized imaged width
    CGSize sz = CGSizeMake(newSize.width, newSize.width);
    
    //figure out if the picture is landscape or portrait, then
    //calculate scale factor and offset
    if (image.size.width > image.size.height) {
        ratio = newSize.height / image.size.height;
        delta = ratio*(image.size.width - image.size.height);
        offset = CGPointMake(delta/2, 0);
    } else {
        ratio = newSize.width / image.size.width;
        delta = ratio*(image.size.height - image.size.width);
        offset = CGPointMake(0, delta/2);
    }
    
    //make the final clipping rect based on the calculated values
    CGRect clipRect = CGRectMake(-offset.x, -offset.y,
                                 (ratio * image.size.width),
                                 (ratio * image.size.height));
    
    //start a new context, with scale factor 0.0 so retina displays get
    //high quality image
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(sz, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(sz);
    }
    UIRectClip(clipRect);
    [image drawInRect:clipRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (ALAssetOrientation)convertImageOrientationToAssetOrientation:(UIImageOrientation)orientation
{
    if (orientation == UIImageOrientationUp) {
        return ALAssetOrientationUp;
    } else if (orientation == UIImageOrientationDown) {
        return ALAssetOrientationDown;
    } else if (orientation == UIImageOrientationLeft) {
        return ALAssetOrientationLeft;
    } else if (orientation == UIImageOrientationRight) {
        return ALAssetOrientationRight;
    } else {
        return 0;
    }
}


//Code taken from http://stackoverflow.com/questions/4431292/inner-shadow-effect-on-uiview-layer
+ (void)addInnerShadowToView:(UIView *)view
{
    CAShapeLayer* shadowLayer = [CAShapeLayer layer];
    [shadowLayer setFrame:view.bounds];
    
    // Standard shadow stuff
    [shadowLayer setShadowColor:[[UIColor colorWithWhite:0 alpha:1] CGColor]];
    [shadowLayer setShadowOffset:CGSizeMake(0.0f, 0.0f)];
    [shadowLayer setShadowOpacity:0.3f];
    [shadowLayer setShadowRadius:5];
    
    // Causes the inner region in this example to NOT be filled.
    [shadowLayer setFillRule:kCAFillRuleEvenOdd];
    
    // Create the larger rectangle path.
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectInset(view.bounds, -40, -40));
    
    // Add the inner path so it's subtracted from the outer path.
    // someInnerPath could be a simple bounds rect, or maybe
    // a rounded one for some extra fanciness.
    CGPathAddPath(path, NULL, [[UIBezierPath bezierPathWithRect:[shadowLayer bounds]] CGPath]);
    CGPathCloseSubpath(path);
    
    [shadowLayer setPath:path];
    CGPathRelease(path);
    
    [view.layer addSublayer:shadowLayer];
    
    CAShapeLayer* maskLayer = [CAShapeLayer layer];
    [maskLayer setPath:[[UIBezierPath bezierPathWithRect:[shadowLayer bounds]] CGPath]];
    [shadowLayer setMask:maskLayer];
}

+ (void)addDropShadowToView:(UIView *)view
{
    view.clipsToBounds = NO;
    
    [view.layer setShadowColor:[UIColor blackColor].CGColor];
    [view.layer setShadowOpacity:0.25];
    [view.layer setShadowRadius:1.5];
    [view.layer setShadowOffset:CGSizeMake(kDropShadowX, kDropShadowY)];
}

//Shout be 139-172-224
+ (UIColor *)getShoutBlue
{
    return [UIColor colorWithRed:139/256.0 green:172/256.0 blue:224/256.0 alpha:1];
}


@end
