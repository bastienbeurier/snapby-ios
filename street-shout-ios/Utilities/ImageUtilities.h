//
//  ImageUtilities.h
//  street-shout-ios
//
//  Created by Bastien Beurier on 9/17/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface ImageUtilities : NSObject

+ (void)addSquareBoundsToImagePicker:(UIImagePickerController *)imagePickerController;

+ (UIImage *)cropImageToSquare:(UIImage *)image;

+ (UIImage *)resizeImage:(UIImage *)image withSize:(NSUInteger)size;

+ (ALAssetOrientation)convertImageOrientationToAssetOrientation:(UIImageOrientation)orientation;

+ (void)addInnerShadowToView:(UIView *)view;

+ (void)addDropShadowToView:(UIView *)view;

@end
