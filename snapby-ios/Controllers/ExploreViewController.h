//
//  MapViewController.h
//  snapby-ios
//
//  Created by Bastien Beurier on 7/22/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Snapby.h"
#import "DisplayViewController.h"
#import <GoogleMaps/GoogleMaps.h>
#import "ExploreSnapbyViewController.h"
#import "CommentsViewController.h"

@protocol ExploreViewControllerDelegate;

@interface ExploreViewController : UIViewController <CommentsVCDelegate, UIScrollViewDelegate, UIActionSheetDelegate, ExploreSnapbyVCDelegate>

@property (weak, nonatomic) id <ExploreViewControllerDelegate> exploreVCDelegate;

- (void) moveMapToMyLocationAndLoadSnapbies;
- (void) onLocationObtained;
- (void)snapby:(Snapby *)likedSnapby likedOrUnlike:(BOOL)liked;
- (void)snapbyCommented:(Snapby *)commentedSnapby count:(NSUInteger)commentCount;

@end

@protocol ExploreViewControllerDelegate

@property (strong, nonatomic) NSMutableSet *myLikes;
@property (strong, nonatomic) NSMutableSet *myComments;

- (CLLocation *)getMyLocation;
- (void)snapby:(Snapby *)likedSnapby likedOrUnlike:(BOOL)liked onController:(NSString *)controller;
- (void)snapbyCommented:(Snapby *)commentedSnapby count:(NSUInteger)commentCount onController:(NSString *)controller;

@end
