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

#define DISPLAY_SHOUT_MAP_SIZE 100
#define INITIAL_FEED_SIZE 170

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

+ (UIColor *)getShoutBlue
{
    return [UIColor colorWithRed:139/256.0 green:172/256.0 blue:224/256.0 alpha:1];
}

+ (UIColor *)getFacebookBlue
{
    return [UIColor colorWithRed:59/256.0 green:89/256.0 blue:152/256.0 alpha:1];
}

+ (void)drawBottomBorderForView:(UIView *)view withColor:(UIColor *)color
{
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, view.frame.size.height - 1.0f, view.frame.size.width, 1.0f);
    bottomBorder.backgroundColor = color.CGColor;
    [view.layer addSublayer:bottomBorder];
}

+ (void)drawCustomNavBarWithLeftItem:(NSString *)leftItem rightItem:(NSString *)rightItem title:(NSString *)title sizeBig:(BOOL)sizeBig inViewController:(UIViewController *)viewController
{
    //Constants
    NSUInteger barHeight = sizeBig ? 80 : 60;
    NSUInteger buttonSize = 45;
    NSUInteger buttonSideMargin = 10;
    NSUInteger buttonTopMargin = sizeBig ? 25 : 15;
    NSUInteger titleTopMargin = sizeBig ? 32 : 22;
    
    //Create bar view
    UIView *customNavBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewController.view.frame.size.width, barHeight)];
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, customNavBar.frame.size.height - 0.5f, customNavBar.frame.size.width, 0.5f);
    bottomBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [customNavBar.layer addSublayer:bottomBorder];
    [viewController.view addSubview:customNavBar];
    
    //Add ok button
    if ([leftItem isEqualToString:@"back"]) {
        UIButton *okButton = [UIButton buttonWithType:UIButtonTypeCustom];
        okButton.frame = CGRectMake(viewController.view.frame.size.width - buttonSize - buttonSideMargin , buttonTopMargin, buttonSize, buttonSize);
        [okButton addTarget:viewController action:@selector(okButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        
        UIImage *okImage = [UIImage imageNamed:@"ok-item-button.png"];
        [okButton setBackgroundImage:okImage forState:UIControlStateNormal];
        
        [customNavBar addSubview:okButton];
    }
    
    //Add back Button
    if ([rightItem isEqualToString:@"ok"]) {
        
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        backButton.frame = CGRectMake(buttonSideMargin, buttonTopMargin, buttonSize, buttonSize);
        [backButton addTarget:viewController action:@selector(backButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        
        UIImage *backImage = [UIImage imageNamed:@"back-item-button.png"];
        [backButton setBackgroundImage:backImage forState:UIControlStateNormal];
        
        [customNavBar addSubview:backButton];
    }
    
    //Add title
    if (title) {
        UIFont *customFont = [UIFont fontWithName:@"Avenir Heavy" size:20];
        NSString *text = title;
        
        CGSize labelSize = [text sizeWithFont:customFont constrainedToSize:CGSizeMake(380, 20) lineBreakMode:NSLineBreakByTruncatingTail];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(viewController.view.frame.size.width/2 - labelSize.width/2, titleTopMargin, labelSize.width, labelSize.height)];
        label.text = text;
        label.font = customFont;
        label.numberOfLines = 1;
        label.textColor = [UIColor lightGrayColor];
        
        [customNavBar addSubview:label];
    }
}

+ (void)displayShoutAnimationsTopContainer:(UIView *)topContainerView
                               bottomContainer:(UIView *)bottomContainerView
                                       mapView:(MKMapView *)mapView
                             createShoutButton:(UIView *)createShoutButton
                                    moreButton:(UIView *)moreButton
                            darkMapOverlayView:(UIView *)darkMapOverlayView
                             mapViewController:(MapViewController *)mapViewController
{
    mapView.zoomEnabled = NO;
    mapView.scrollEnabled = NO;
    mapView.userInteractionEnabled = NO;
    darkMapOverlayView.hidden = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        float showShoutAnimationHeightDelta = topContainerView.frame.size.height - DISPLAY_SHOUT_MAP_SIZE;
        
        topContainerView.frame = CGRectMake(topContainerView.frame.origin.x,
                                            topContainerView.frame.origin.y,
                                            topContainerView.frame.size.width,
                                            topContainerView.frame.size.height - showShoutAnimationHeightDelta);
        
        mapView.frame = CGRectMake(mapView.frame.origin.x,
                                   mapView.frame.origin.y,
                                   mapView.frame.size.width,
                                   mapView.frame.size.width - showShoutAnimationHeightDelta);
        
        bottomContainerView.frame = CGRectMake(bottomContainerView.frame.origin.x,
                                               bottomContainerView.frame.origin.y - showShoutAnimationHeightDelta,
                                               bottomContainerView.frame.size.width,
                                               bottomContainerView.frame.size.height + showShoutAnimationHeightDelta);
        darkMapOverlayView.alpha = 0.5;
        createShoutButton.alpha = 0;
        moreButton.alpha = 0;
    } completion:^(BOOL finished) {
        createShoutButton.hidden = YES;
        moreButton.hidden = YES;
    }];
}

+ (void)stopDisplayShoutAnimationsTopContainer:(UIView *)topContainerView
                               bottomContainer:(UIView *)bottomContainerView
                                       mapView:(MKMapView *)mapView
                             createShoutButton:(UIView *)createShoutButton
                                    moreButton:(UIView *)moreButton
                            darkMapOverlayView:(UIView *)darkMapOverlayView
                             mapViewController:(MapViewController *)mapViewController
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    
    createShoutButton.hidden = NO;
    moreButton.hidden = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        topContainerView.frame = CGRectMake(topContainerView.frame.origin.x,
                                            topContainerView.frame.origin.y,
                                            topContainerView.frame.size.width,
                                            screenHeight - INITIAL_FEED_SIZE);
        
        mapView.frame = CGRectMake(mapView.frame.origin.x,
                                   mapView.frame.origin.y,
                                   mapView.frame.size.width,
                                   screenHeight - INITIAL_FEED_SIZE);
        
        bottomContainerView.frame = CGRectMake(bottomContainerView.frame.origin.x,
                                               screenHeight - INITIAL_FEED_SIZE,
                                               bottomContainerView.frame.size.width,
                                               INITIAL_FEED_SIZE);
        
        createShoutButton.alpha = 1;
        moreButton.alpha = 1;
        darkMapOverlayView.alpha = 0;
    } completion:^(BOOL finished) {
        mapView.zoomEnabled = YES;
        mapView.scrollEnabled = YES;
        mapView.userInteractionEnabled = YES;
        darkMapOverlayView.hidden = YES;
        
        mapViewController.updateShoutsOnMapMove = YES;
    }];
}

+ (void)popShoutControllerSegueAnimation:(ShoutViewController *)shoutController
{
    CATransition* transition = [CATransition animation];
    
    transition.duration = 0.3;
    transition.type = kCATransitionFade;
    
    [shoutController.navigationController.view.layer addAnimation:transition forKey:kCATransition];
    [shoutController.navigationController popViewControllerAnimated:NO];
}

@end
