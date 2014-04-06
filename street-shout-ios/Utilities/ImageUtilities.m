//
//  ImageUtilities.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 9/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "ImageUtilities.h"
#import "Constants.h"
#import <MapKit/MapKit.h>
#import "MapViewController.h"
#import "ShoutViewController.h"
#import "UIImageView+AFNetworking.h"

#define DISPLAY_SHOUT_MAP_SIZE 100
#define INITIAL_FEED_SIZE 170

@implementation ImageUtilities

//Code from http://stackoverflow.com/questions/17712797/ios-custom-uiimagepickercontroller-camera-crop-to-square
+ (void)addSquareBoundsToImagePicker:(UIImagePickerController *)imagePickerController
{
    CGRect f = imagePickerController.view.bounds;
    
    //TODO: make this more robust
    if (f.size.height== 568.0f){
        UIGraphicsBeginImageContext(f.size);
        [[UIColor colorWithWhite:0 alpha:1] set];
        UIRectFillUsingBlendMode(CGRectMake(0, 69, f.size.width, 53), kCGBlendModeNormal);
        UIRectFillUsingBlendMode(CGRectMake(0, 69+426-53, f.size.width, 56),kCGBlendModeNormal);
    } else {
        f.size.height -= imagePickerController.navigationBar.bounds.size.height;
        CGFloat barHeight = (f.size.height - f.size.width) / 2;
        UIGraphicsBeginImageContext(f.size);
        [[UIColor colorWithWhite:0 alpha:0] set];
        UIRectFillUsingBlendMode(CGRectMake(0, 0, f.size.width, barHeight), kCGBlendModeNormal);
        UIRectFillUsingBlendMode(CGRectMake(0, f.size.height - barHeight, f.size.width, barHeight), kCGBlendModeNormal);
    }
    
    UIImage *overlayImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *overlayIV = [[UIImageView alloc] initWithFrame:f];
    overlayIV.image = overlayImage;
    [imagePickerController setCameraOverlayView:overlayIV];
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

+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage*)cropWidthOfImage:(UIImage*)image by:(CGFloat)croppedPercentage {
    
    if(croppedPercentage<0 || croppedPercentage>=1){
        // do nothing
        return image;
    }
    
    // Create rectangle from middle of current image
    CGFloat croppedWidth = croppedPercentage * image.size.width;
    CGRect croprect = CGRectMake(croppedWidth / 2, 0.0,
                                 image.size.width - croppedWidth, image.size.height);
    
    // Draw new image in current graphics context
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], croprect);
    
    // Create new cropped UIImage
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return croppedImage;
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

+ (UIColor *)getShoutBlue
{
    return [UIColor colorWithRed:139/256.0 green:172/256.0 blue:224/256.0 alpha:1];
}

+ (UIColor *)getFacebookBlue
{
    return [UIColor colorWithRed:59/256.0 green:89/256.0 blue:152/256.0 alpha:1];
}

+ (void)drawBottomBorderForView:(UIView *)view withColor:(UIColor *)color andHeight:(double)height
{
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, view.frame.size.height - height, view.frame.size.width, height);
    bottomBorder.backgroundColor = color.CGColor;
    [view.layer addSublayer:bottomBorder];
}

+ (void)drawBottomBorderForView:(UIView *)view withColor:(UIColor *)color
{
    [ImageUtilities drawBottomBorderForView:view withColor:color andHeight:1.0f];
}

+ (void)drawTopBorderForView:(UIView *)view withColor:(UIColor *)color
{
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, 0.0f, view.frame.size.width, 1.0f);
    bottomBorder.backgroundColor = color.CGColor;
    [view.layer addSublayer:bottomBorder];
}

+ (void)drawRightBorderForView:(UIView *)view withColor:(UIColor *)color
{
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(view.frame.size.width - 1.0f, 0.0f, 1.0f, view.frame.size.height);
    bottomBorder.backgroundColor = color.CGColor;
    [view.layer addSublayer:bottomBorder];
}

+ (void)drawCustomNavBarWithLeftItem:(NSString *)leftItem rightItem:(NSString *)rightItem title:(NSString *)title sizeBig:(BOOL)sizeBig inViewController:(UIViewController *)viewController
{
    //Status bar color
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    //Constants
    NSUInteger barHeight = sizeBig ? 80 : 60;
    NSUInteger buttonSize = 45;
    NSUInteger buttonSideMargin = 10;
    NSUInteger buttonTopMargin = sizeBig ? 25 : 15;
    NSUInteger titleTopMargin = sizeBig ? 32 : 22;
    
    //Create bar view
    UIView *customNavBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewController.view.frame.size.width, barHeight)];
    customNavBar.backgroundColor = [ImageUtilities getShoutBlue];
    [viewController.view addSubview:customNavBar];
    
    // Right Button
    CGRect rightRect = CGRectMake(viewController.view.frame.size.width - buttonSize - buttonSideMargin, buttonTopMargin, buttonSize, buttonSize);
    if ([rightItem isEqualToString:@"ok"]) {
        [ImageUtilities addButtonWithImage:@"ok-item-button.png"
                                    target:viewController
                                  selector:@selector(okButtonClicked)
                                      rect:rightRect
                                  toNavBar:customNavBar];
    } else if ([rightItem isEqualToString:@"settings"]) {
        [ImageUtilities addButtonWithImage:@"settingsButton.png"
                                    target:viewController
                                  selector:@selector(settingsButtonClicked)
                                      rect:rightRect
                                  toNavBar:customNavBar];
    }
    
    // Left Button
    CGRect leftRect = CGRectMake(buttonSideMargin, buttonTopMargin, buttonSize, buttonSize);
    if ([leftItem isEqualToString:@"back"]) {
        [ImageUtilities addButtonWithImage:@"back-item-button.png"
                                    target:viewController
                                  selector:@selector(backButtonClicked)
                                      rect:leftRect
                                  toNavBar:customNavBar];
    } 
    
    //Add title
    if (title) {
        UIFont *customFont = [UIFont fontWithName:@"Avenir Heavy" size:20];
        NSString *text = title;
        
        CGSize labelSize = [text sizeWithAttributes:@{NSFontAttributeName:customFont}];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(viewController.view.frame.size.width/2 - labelSize.width/2, titleTopMargin, labelSize.width, labelSize.height)];
        label.text = text;
        label.font = customFont;
        label.numberOfLines = 1;
        label.textColor = [UIColor whiteColor];
        
        [customNavBar addSubview:label];
    }
}

+ (void)addButtonWithImage:(NSString*)imageName
                             target:(UIViewController *)viewController
                           selector:(SEL)selector
                               rect:(CGRect)rect
                            toNavBar:(UIView *)navBar
{
    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    customButton.frame = rect;
    [customButton addTarget:viewController action:selector forControlEvents:UIControlEventTouchUpInside];
    [customButton setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [navBar addSubview:customButton];
}

+ (NSString *)encodeToBase64String:(UIImage *)image {
    return [UIImageJPEGRepresentation(image,0.9) base64EncodedStringWithOptions:0];
}

+ (void)setWithoutCachingImageView:(UIImageView *)imageView withURL:(NSURL *)url
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    request.cachePolicy=NSURLRequestReloadIgnoringCacheData;
    [imageView setImageWithURLRequest:request placeholderImage:nil success:nil failure:nil];
}

@end
