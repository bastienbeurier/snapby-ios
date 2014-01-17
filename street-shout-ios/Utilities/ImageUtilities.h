//
//  ImageUtilities.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 9/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MapKit/MapKit.h>
#import "MapViewController.h"

@interface ImageUtilities : NSObject

+ (void)addSquareBoundsToImagePicker:(UIImagePickerController *)imagePickerController;

+ (ALAssetOrientation)convertImageOrientationToAssetOrientation:(UIImageOrientation)orientation;

+ (void)addInnerShadowToView:(UIView *)view;

+ (void)addDropShadowToView:(UIView *)view;

+ (UIColor *)getShoutBlue;

+ (UIImage*) cropBiggestCenteredSquareImageFromImage:(UIImage*)image withSide:(CGFloat)side;

+ (UIColor *)getFacebookBlue;

+ (void)drawBottomBorderForView:(UIView *)view withColor:(UIColor *)color;

+ (void)drawCustomNavBarWithLeftItem:(NSString *)leftItem rightItem:(NSString *)rightItem title:(NSString *)title sizeBig:(BOOL)sizeBig inViewController:(UIViewController *)viewController;

+ (void)displayShoutAnimationsTopContainer:(UIView *)topContainerView
                           bottomContainer:(UIView *)bottomContainerView
                                   mapView:(MKMapView *)mapView
                         createShoutButton:(UIView *)createShoutButton
                                moreButton:(UIView *)moreButton
                        darkMapOverlayView:(UIView *)darkMapOverlayView
                         mapViewController:(MapViewController *)mapViewController;

+ (void)stopDisplayShoutAnimationsTopContainer:(UIView *)topContainerView
                               bottomContainer:(UIView *)bottomContainerView
                                       mapView:(MKMapView *)mapView
                             createShoutButton:(UIView *)createShoutButton
                                    moreButton:(UIView *)moreButton
                            darkMapOverlayView:(UIView *)darkMapOverlayView
                             mapViewController:(MapViewController *)mapViewController;

+ (void)popShoutControllerSegueAnimation:(UIViewController *)controller;

@end
