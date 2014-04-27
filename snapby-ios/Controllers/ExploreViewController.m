//
//  MapViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 7/22/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "ExploreViewController.h"
#import "MKPointAnnotation+SnapbyPointAnnotation.h"
#import "LocationUtilities.h"
#import "Constants.h"
#import "GeneralUtilities.h"
#import "ImageUtilities.h"
#import "TrackingUtilities.h"
#import "HackClipView.h"
#import "AFSnapbyAPIClient.h"
#import "MBProgressHUD.h"
#import "SessionUtilities.h"

#define MORE_ACTION_SHEET_OPTION_1 NSLocalizedStringFromTable (@"navigate_to_snapby", @"Strings", @"comment")
#define MORE_ACTION_SHEET_OPTION_2 NSLocalizedStringFromTable (@"share_snapby", @"Strings", @"comment")
#define MORE_ACTION_SHEET_OPTION_3 NSLocalizedStringFromTable (@"report_snapby", @"Strings", @"comment")
#define MORE_ACTION_SHEET_OPTION_4 NSLocalizedStringFromTable (@"remove_snapby", @"Strings", @"comment")

#define FLAG_ACTION_SHEET_OPTION_1 NSLocalizedStringFromTable (@"abusive_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_2 NSLocalizedStringFromTable (@"spam_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_3 NSLocalizedStringFromTable (@"privacy_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_4 NSLocalizedStringFromTable (@"inaccurate_content", @"Strings", @"comment")
#define FLAG_ACTION_SHEET_OPTION_5 NSLocalizedStringFromTable (@"other_content", @"Strings", @"comment")

#define FLAG_ACTION_SHEET_CANCEL NSLocalizedStringFromTable (@"cancel", @"Strings", @"comment")

#define PER_PAGE 20

@interface ExploreViewController () <GMSMapViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *viewControllers;
@property (nonatomic) NSUInteger scrollViewWidth;
@property (nonatomic) NSUInteger scrollViewHeight;
@property (weak, nonatomic) IBOutlet HackClipView *scrollViewContainer;
@property (nonatomic, strong) NSArray *snapbies;
@property (strong, nonatomic) NSMutableDictionary *displayedSnapbies;
@property (weak, nonatomic) Snapby *previouslySelectedSnapby;
@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (nonatomic) int currentSelectedZIndex;
@property (nonatomic) NSInteger automaticScrolling;
@property (nonatomic) BOOL myLocationMarkerSet;
@property (weak, nonatomic) IBOutlet UIView *snapbyDialog;
@property (weak, nonatomic) IBOutlet UILabel *snapbyDialogLabel;
@property (nonatomic) BOOL didInitializedExplore;
@property (weak, nonatomic) IBOutlet UIImageView *refreshButton;
@property (nonatomic) NSInteger page;
@property (nonatomic) BOOL noMoreSnapbyToPull;
@property (nonatomic) BOOL pullingMoreSnapbies;
@property (nonatomic) NSUInteger lastPageScrolled;
@property (strong, nonatomic) UIActionSheet *flagActionSheet;
@property (strong, nonatomic) UIActionSheet *moreActionSheet;

@end

@implementation ExploreViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // border radius
    [self.snapbyDialog.layer setCornerRadius:25.0f];
    [self.refreshButton.layer setCornerRadius:22.0f];
    
    self.mapView.delegate = self;
    self.mapView.myLocationEnabled = NO;
    self.mapView.settings.scrollGestures = NO;
    self.mapView.settings.zoomGestures = NO;
    self.mapView.settings.tiltGestures = NO;
    self.mapView.settings.rotateGestures = NO;
    
    self.automaticScrolling = NO;
    
    // a page is the width of the scroll view
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
    
    self.currentSelectedZIndex = 0;
    
    //Equivalent of NO
    self.automaticScrolling = -1;
    
    self.myLocationMarkerSet = NO;
    
    
    
    self.didInitializedExplore = NO;
    
    self.page = 1;
    self.noMoreSnapbyToPull = NO;
    self.pullingMoreSnapbies = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (!self.didInitializedExplore) {
        self.didInitializedExplore = YES;
        UIEdgeInsets edgeInsets = UIEdgeInsetsMake(0, 0, self.scrollViewContainer.frame.size.height, 0);
        self.mapView.padding = edgeInsets;
        
        [self moveMapToMyLocationAndLoadSnapbies];
    }
}

- (void)refreshSnapbies
{
    [self loadingSnapbiesUI];
    
    [AFSnapbyAPIClient pullSnapbiesInZone:[LocationUtilities getMapBounds:self.mapView] page:1 pageSize:PER_PAGE AndExecuteSuccess:^(NSArray *snapbies, NSInteger page) {
        self.snapbies = snapbies;
    } failure:^{
        [self noConnectionUI];
    }];
}

- (void)loadingSnapbiesUI
{
    for (UIView *view in self.scrollView.subviews)
    {
        if (![view isKindOfClass:[UIImageView class]])
            [view removeFromSuperview];
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.snapbyDialog.hidden = YES;
    self.scrollView.hidden = YES;
}

- (void)loadingMoreSnapbiesUI
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.snapbyDialog.hidden = YES;
}

- (void)noSnapbiesUI
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    self.snapbyDialog.hidden = NO;
    self.snapbyDialogLabel.text = @"No snapby here...";
    self.scrollView.hidden = YES;
}

- (void)noConnectionUI
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    self.snapbyDialog.hidden = NO;
    self.snapbyDialogLabel.text = @"No connection...";
    self.scrollView.hidden = YES;
}

- (void)noLocationUI
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [self.mapView moveCamera:[GMSCameraUpdate setTarget:CLLocationCoordinate2DMake(50,0) zoom:0]];
    self.snapbyDialog.hidden = NO;
    self.snapbyDialogLabel.text = @"No location...";
    self.scrollView.hidden = YES;
}

- (void)displaySnapbiesUI
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    self.snapbyDialog.hidden = YES;
    self.snapbyDialogLabel.text = @"";
    self.scrollView.hidden = NO;
}

- (void)setSnapbies:(NSArray *)snapbies
{
    _snapbies = snapbies;
    self.page = 1;
    self.noMoreSnapbyToPull = NO;
    self.pullingMoreSnapbies = NO;
    
    if ([snapbies count] < PER_PAGE) {
        self.noMoreSnapbyToPull = YES;
    }
    
    if ([snapbies count] == 0) {
        [self noSnapbiesUI];
        return;
    }
    
    [self displaySnapbies:snapbies];
    
    NSUInteger numberPages = self.snapbies.count;
    
    // view controllers are created lazily
    // in the meantime, load the array with placeholders which will be replaced on demand
    NSMutableArray *controllers = [[NSMutableArray alloc] init];
    
    for (NSUInteger i = 0; i < numberPages; i++)
    {
        [controllers addObject:[NSNull null]];
    }
    
    self.viewControllers = controllers;
    
    if (self.scrollViewWidth == 0 && self.scrollViewHeight == 0) {
        self.scrollViewWidth = CGRectGetWidth(self.scrollView.frame);
        self.scrollViewHeight = CGRectGetHeight(self.scrollView.frame);
    }
    
    self.scrollView.contentSize = CGSizeMake(self.scrollViewWidth * numberPages, self.scrollViewHeight);
    
    [self gotoPage:0 animated:NO];
    
    [self loadSnapbiesAndUpdateMarker];
    
    [((ExploreSnapbyViewController *) [self.viewControllers objectAtIndex:0]) snapbyDisplayed];
    
    [self displaySnapbiesUI];
}

- (void)updateSnapbies:(NSArray *)newSnapbies
{
    if ([newSnapbies count] < PER_PAGE) {
        self.noMoreSnapbyToPull = YES;
    }
    
    if ([newSnapbies count] == 0) {
        return;
    }
    
    [self displayMoreSnapbies:newSnapbies];
    
    NSUInteger oldSnapbyCount = self.snapbies.count;
    NSUInteger numberPages = oldSnapbyCount + newSnapbies.count;
    
    NSMutableArray *updatedSnapbies = [_snapbies mutableCopy];
    [updatedSnapbies addObjectsFromArray:newSnapbies];
    _snapbies = updatedSnapbies;
    
    for (NSUInteger i = oldSnapbyCount; i < numberPages; i++)
    {
        [self.viewControllers addObject:[NSNull null]];
    }
    
    self.scrollView.contentSize = CGSizeMake(self.scrollViewWidth * numberPages, self.scrollViewHeight);
 
    [self loadSnapbiesAndUpdateMarker];
}

- (void) moveMapToMyLocationAndLoadSnapbies
{
    [self loadingSnapbiesUI];
    
    CLLocation *myLocation = [self.exploreVCDelegate getMyLocation];
    if (myLocation != nil && myLocation.coordinate.latitude != 0 && myLocation.coordinate.longitude != 0) {
        CLLocationCoordinate2D location;
        location.latitude = myLocation.coordinate.latitude;
        location.longitude = myLocation.coordinate.longitude;
        
        [self.mapView moveCamera:[GMSCameraUpdate setTarget:location zoom:kZoomAtStartup]];
        
        [self.mapView clear];
        
        GMSMarker *marker = [GMSMarker markerWithPosition:location];
        marker.icon = [UIImage imageNamed:@"my_location_marker"];
        marker.zIndex = 10000;
        marker.map = self.mapView;
        
        [self refreshSnapbies];
    } else {
        [self noLocationUI];
    }
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker
{
    NSUInteger snapbyId = [marker.title intValue];
    
    int i = 0;
    NSUInteger length = [self.snapbies count];
    
    for (i = 0; i < length; i = i + 1) {
        if (((Snapby *)[self.snapbies objectAtIndex:i]).identifier == snapbyId) {
            if (i != [self getScrollViewPage]) {
                self.automaticScrolling = (NSInteger) i;
                [self gotoPage:i animated:YES];
                break;
            }
        }
    }
    
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Snapby Push Segue From Explore"]) {
        ((DisplayViewController *) [segue destinationViewController]).snapby = (Snapby *)sender;
    }
}

- (void)displaySnapbies:(NSArray *)snapbies
{
    self.displayedSnapbies = [[NSMutableDictionary alloc] init];
    
    for (Snapby *snapby in snapbies) {
        NSString *snapbyKey = [NSString stringWithFormat:@"%lu", (unsigned long)snapby.identifier];
        
        CLLocationCoordinate2D markerCoordinate;
        markerCoordinate.latitude = snapby.lat;
        markerCoordinate.longitude = snapby.lng;
        
        GMSMarker *marker = [GMSMarker markerWithPosition:markerCoordinate];
        marker.title = [NSString stringWithFormat:@"%lu", snapby.identifier];
        marker.icon = [UIImage imageNamed:[GeneralUtilities getAnnotationPinImageForSnapby:(Snapby *)snapby selected:NO]];
        
        marker.map = self.mapView;
        
        [self.displayedSnapbies setObject:marker forKey:snapbyKey];
    }
}

- (void)displayMoreSnapbies:(NSArray *)newSnapbies
{
    for (Snapby *snapby in newSnapbies) {
        NSString *snapbyKey = [NSString stringWithFormat:@"%lu", (unsigned long)snapby.identifier];
        
        CLLocationCoordinate2D markerCoordinate;
        markerCoordinate.latitude = snapby.lat;
        markerCoordinate.longitude = snapby.lng;
        
        GMSMarker *marker = [GMSMarker markerWithPosition:markerCoordinate];
        marker.title = [NSString stringWithFormat:@"%lu", snapby.identifier];
        marker.icon = [UIImage imageNamed:[GeneralUtilities getAnnotationPinImageForSnapby:(Snapby *)snapby selected:NO]];
        
        marker.map = self.mapView;
        
        [self.displayedSnapbies setObject:marker forKey:snapbyKey];
    }
}

- (NSMutableDictionary *)displayedSnapbies
{
    if (!_displayedSnapbies) _displayedSnapbies = [[NSMutableDictionary alloc] init];
    return _displayedSnapbies;
}


//Scrollview related methods

- (void)loadScrollViewWithPage:(NSUInteger)page
{
    if (page >= self.snapbies.count) {
        return;
    }
    
    // replace the placeholder if necessary
    ExploreSnapbyViewController *controller = [self.viewControllers objectAtIndex:page];
    if ((NSNull *)controller == [NSNull null])
    {
        controller = [[ExploreSnapbyViewController alloc] initWithSnapby:[self.snapbies objectAtIndex:page]];
        controller.exploreSnapbyVCDelegate = self;
        [self.viewControllers replaceObjectAtIndex:page withObject:controller];
    }
    
    // add the controller's view to the scroll view
    if (controller.view.superview == nil)
    {
        controller.view.frame = CGRectMake((self.scrollViewWidth) * page, 0, self.scrollViewWidth, self.scrollViewHeight);
        
        [self addChildViewController:controller];
        [self.scrollView addSubview:controller.view];
        [controller didMoveToParentViewController:self];
    }
}

// at the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSUInteger page = [self getScrollViewPage];
    
    //Skip if method already called for this page or if scrolling automatically (when user clicks on marker)
    if (page == self.lastPageScrolled || (self.automaticScrolling > -1 && self.automaticScrolling != [self getScrollViewPage])) {
        return;
    }
    
    self.lastPageScrolled = page;
    
    self.automaticScrolling = -1;
    
    [self loadSnapbiesAndUpdateMarker];
    
    //Show snapby info on the center snapby controller
    [((ExploreSnapbyViewController *) [self.viewControllers objectAtIndex:page]) snapbyDisplayed];
    
    if (page > 0) {
        [((ExploreSnapbyViewController *) [self.viewControllers objectAtIndex:page - 1]) snapbyDismissed];
    }
    if (page < [self.viewControllers count] - 1) {
        [((ExploreSnapbyViewController *) [self.viewControllers objectAtIndex:page + 1]) snapbyDismissed];
    }
    
    //Pull more snapbies if it's the last snapby
    if (page == self.snapbies.count - 1 && !self.noMoreSnapbyToPull && !self.pullingMoreSnapbies) {
        
        self.pullingMoreSnapbies = YES;
        [self loadingMoreSnapbiesUI];
        
        [AFSnapbyAPIClient pullSnapbiesInZone:[LocationUtilities getMapBounds:self.mapView] page:self.page + 1 pageSize:PER_PAGE AndExecuteSuccess:^(NSArray *snapbies, NSInteger page) {
            
            if (page == self.page + 1) {
                self.pullingMoreSnapbies = NO;
                self.page = self.page + 1;
                [self updateSnapbies:snapbies];
                [self displaySnapbiesUI];
            }
        } failure:^{
            [self noConnectionUI];
        }];
    }
}

- (void)loadSnapbiesAndUpdateMarker
{
    NSUInteger page = [self getScrollViewPage];
    
    Snapby *snapby = ((Snapby *)[self.snapbies objectAtIndex:page]);
    
    NSString *snapbyKey = [NSString stringWithFormat:@"%lu", snapby.identifier];
    
    GMSMarker *marker = [self.displayedSnapbies objectForKey:snapbyKey];
    
    marker.icon = [UIImage imageNamed:[GeneralUtilities getAnnotationPinImageForSnapby:(Snapby *)snapby selected:YES]];
    marker.zIndex = self.currentSelectedZIndex + 1;
    self.currentSelectedZIndex = self.currentSelectedZIndex + 1;
    marker.map = self.mapView;
    
    if (self.previouslySelectedSnapby != nil && self.previouslySelectedSnapby.identifier != snapby.identifier) {
        GMSMarker *oldMarker = [self.displayedSnapbies objectForKey:[NSString stringWithFormat:@"%lu", self.previouslySelectedSnapby.identifier]];
        oldMarker.icon = [UIImage imageNamed:[GeneralUtilities getAnnotationPinImageForSnapby:(Snapby *)snapby selected:NO]];
        oldMarker.map = self.mapView;
    }
    
    self.previouslySelectedSnapby = snapby;
    
    [self loadScrollViewWithPage:page - 3];
    [self loadScrollViewWithPage:page - 2];
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
    [self loadScrollViewWithPage:page + 2];
    [self loadScrollViewWithPage:page + 3];
    
}

- (NSUInteger)getScrollViewPage
{
    // switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.scrollViewWidth;
    return MIN(floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1, self.snapbies.count - 1);
}

- (void)gotoPage:(NSUInteger)page animated:(BOOL)animated
{
	// update the scroll view to the appropriate page
    CGRect bounds = self.scrollView.bounds;
    bounds.origin.x = CGRectGetWidth(bounds) * page;
    bounds.origin.y = 0;
    
    [self.scrollView scrollRectToVisible:bounds animated:animated];
}

- (IBAction)onScrollViewClicked:(id)sender {
    Snapby *snapby = [self.snapbies objectAtIndex:[self getScrollViewPage]];
    [self performSegueWithIdentifier:@"Snapby Push Segue From Explore" sender:snapby];
}

- (IBAction)refreshButtonClicked:(id)sender {
    [self moveMapToMyLocationAndLoadSnapbies];
}

- (void)moreButtonClicked:(Snapby *)snapby
{
    if(snapby.userId == [SessionUtilities getCurrentUser].identifier) {
        self.moreActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self cancelButtonTitle:FLAG_ACTION_SHEET_CANCEL
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:MORE_ACTION_SHEET_OPTION_1, MORE_ACTION_SHEET_OPTION_2, MORE_ACTION_SHEET_OPTION_3, MORE_ACTION_SHEET_OPTION_4, nil];
    } else {
        self.moreActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self cancelButtonTitle:FLAG_ACTION_SHEET_CANCEL
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:MORE_ACTION_SHEET_OPTION_1, MORE_ACTION_SHEET_OPTION_2, MORE_ACTION_SHEET_OPTION_3, nil];
    }
    
    [self.moreActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    Snapby *snapby = [self.snapbies objectAtIndex:[self getScrollViewPage]];
    
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:FLAG_ACTION_SHEET_CANCEL]) {
        return;
    }
    
    if (actionSheet == self.moreActionSheet) {
        if ([buttonTitle isEqualToString:MORE_ACTION_SHEET_OPTION_1]) {
            Class mapItemClass = [MKMapItem class];
            if (mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)]) {
                // Create an MKMapItem to pass to the Maps app
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(snapby.lat, snapby.lng);
                MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate
                                                               addressDictionary:nil];
                MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
                [mapItem setName:@"Snapby"];
                // Pass the map item to the Maps app
                [mapItem openInMapsWithLaunchOptions:nil];
            }
        } else if ([buttonTitle isEqualToString:MORE_ACTION_SHEET_OPTION_2]) {
            NSString *shareString = @"Hey, check out this snapby!\n";
            
            NSURL *shareUrl = [NSURL URLWithString:[[(PRODUCTION? kProdSnapbyBaseURLString : kDevAFSnapbyAPIBaseURLString) stringByAppendingString:@"snapbies/"]stringByAppendingString:[NSString stringWithFormat:@"%lu",(unsigned long)snapby.identifier]]];
            
            NSArray *activityItems = [NSArray arrayWithObjects:shareString, shareUrl, nil];
            
            UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
            [activityViewController setValue:@"Sharing a snapby with you." forKey:@"subject"];
            activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop];
            [self presentViewController:activityViewController animated:YES completion:nil];
        } else if ([buttonTitle isEqualToString:MORE_ACTION_SHEET_OPTION_3]) {
            self.flagActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedStringFromTable (@"flag_action_sheet_title", @"Strings", @"comment")
                                                               delegate:self
                                                      cancelButtonTitle:FLAG_ACTION_SHEET_CANCEL
                                                 destructiveButtonTitle:nil
                                                      otherButtonTitles:FLAG_ACTION_SHEET_OPTION_1, FLAG_ACTION_SHEET_OPTION_2, FLAG_ACTION_SHEET_OPTION_3, FLAG_ACTION_SHEET_OPTION_4, FLAG_ACTION_SHEET_OPTION_5, nil];
            [self.flagActionSheet showInView:[UIApplication sharedApplication].keyWindow];
        } else if ([buttonTitle isEqualToString:MORE_ACTION_SHEET_OPTION_4]) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
            [AFSnapbyAPIClient removeSnapby: snapby success:^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [self refreshSnapbies];
            } failure:^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"fail_delete_snapby", @"Strings", @"comment") withTitle:nil];
            }];
        }
    } else if (actionSheet == self.flagActionSheet) {
        
        NSString *motive = nil;
        
        switch (buttonIndex) {
            case 0:
                motive = @"abuse";
                break;
            case 1:
                motive = @"spam";
                break;
            case 2:
                motive = @"privacy";
                break;
            case 3:
                motive = @"inaccurate";
                break;
            case 4:
                motive = @"other";
                break;
        }
        
        [AFSnapbyAPIClient reportSnapby:snapby.identifier withFlaggerId:[SessionUtilities getCurrentUser].identifier withMotive:motive AndExecute:nil Failure:^{
            [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"fail_report_snapby", @"Strings", @"comment") withTitle:nil];
        }];
        
        [GeneralUtilities showMessage:NSLocalizedStringFromTable (@"flag_thanks_alert", @"Strings", @"comment") withTitle:nil];
    }
}

@end
