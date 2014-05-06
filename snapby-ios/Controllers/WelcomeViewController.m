//
//  WelcomeViewController.m
//  snapby-ios
//
//  Created by Bastien Beurier on 1/10/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import "WelcomeViewController.h"
#import "SessionUtilities.h"
#import "ImageUtilities.h"
#import <FacebookSDK/FacebookSDK.h>
#import "NavigationAppDelegate.h"
#import "GeneralUtilities.h"
#import "MBProgressHUD.h"
#import "TutorialViewController.h"


@interface WelcomeViewController ()

@property (weak, nonatomic) IBOutlet UIButton *facebookButtonView;
@property (weak, nonatomic) IBOutlet UIButton *signupButtonView;
@property (weak, nonatomic) IBOutlet UILabel *facebookFirstLabel;
@property (weak, nonatomic) IBOutlet UILabel *facebookSecondLabel;
@property (weak, nonatomic) IBOutlet UILabel *signupFirstLabel;
@property (weak, nonatomic) IBOutlet UILabel *signupSecondLabel;
@property (weak, nonatomic) IBOutlet UIButton *signinButton;
@property (weak, nonatomic) IBOutlet UILabel *signinLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *tutorialScrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@end

@implementation WelcomeViewController

- (void)viewDidLoad
{
    
//    self.backgroundImage.image = [UIImage imageNamed:filename];
    
    //Round corners
    self.facebookButtonView.layer.cornerRadius = 5.0f;
    self.signupButtonView.layer.cornerRadius = 5.0f;
}

- (void)viewWillAppear:(BOOL)animated
{
    //Nav bar
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    NSUInteger h = self.tutorialScrollView.frame.size.height;
    NSUInteger w = self.tutorialScrollView.frame.size.width;
    
    self.tutorialScrollView.contentSize = CGSizeMake(w * 4, h);
    self.tutorialScrollView.delegate = self;
    
    TutorialViewController *firstPage = [[TutorialViewController alloc] initWithPage:0];
    
    TutorialViewController *secondPage = [[TutorialViewController alloc] initWithPage:1];
    
    TutorialViewController *thirdPage = [[TutorialViewController alloc] initWithPage:2];
    
    TutorialViewController *fourthPage = [[TutorialViewController alloc] initWithPage:3];
    
    firstPage.view.frame = CGRectMake(0, 0, w, h);
    secondPage.view.frame = CGRectMake(w, 0, w, h);
    thirdPage.view.frame = CGRectMake(2 * w, 0, w, h);
    fourthPage.view.frame = CGRectMake(3 * w, 0, w, h);
    
    [self addChildViewController:firstPage];
    [self.tutorialScrollView addSubview:firstPage.view];
    [firstPage didMoveToParentViewController:self];
    
    [self addChildViewController:secondPage];
    [self.tutorialScrollView addSubview:secondPage.view];
    [secondPage didMoveToParentViewController:self];
    
    [self addChildViewController:thirdPage];
    [self.tutorialScrollView addSubview:thirdPage.view];
    [thirdPage didMoveToParentViewController:self];
    
    [self addChildViewController:fourthPage];
    [self.tutorialScrollView addSubview:fourthPage.view];
    [fourthPage didMoveToParentViewController:self];
    
    [self.tutorialScrollView setContentOffset: CGPointMake(self.tutorialScrollView.contentOffset.x, 0)];
    
    [super viewWillAppear:animated];
}

//Hack to prevent vertical scrolling
- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
    [self.tutorialScrollView setContentOffset: CGPointMake(self.tutorialScrollView.contentOffset.x, 0)];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = CGRectGetWidth(self.tutorialScrollView.frame);
    NSUInteger page = floor((self.tutorialScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
}

- (IBAction)facebookButtonClicked:(id)sender {
    // Prevent double clicking
    UIButton *facebookButton = (UIButton *) sender;
    facebookButton.enabled = NO;
    [UIView animateWithDuration:0.1 animations:^{
        [self setButtonsAndLabelsAlphaTo:0];}
     ];
    
    // We should not have any token or open session here
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded
        || FBSession.activeSession.state == FBSessionStateOpen
        || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        
        NSLog(@"%u",FBSession.activeSession.state);
        [SessionUtilities redirectToSignIn];
        
    } else {
        // Check connection
        if (![GeneralUtilities connected]) {
            [GeneralUtilities showMessage:nil withTitle:NSLocalizedStringFromTable (@"no_connection_error_title", @"Strings", @"comment")];
        } else {
            // Display loading
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
            // Open a session showing the user the login UI
            [FBSession openActiveSessionWithReadPermissions:@[@"basic_info",@"email"]
                                               allowLoginUI:YES
                                          completionHandler:
             ^(FBSession *session, FBSessionState state, NSError *error) {
                 
                 // Retrieve the app delegate
                 NavigationAppDelegate* navigationAppDelegate = [UIApplication sharedApplication].delegate;
                 [navigationAppDelegate sessionStateChanged:session state:state error:error];
             }];
            return;
        }
    }
    facebookButton.enabled = YES;
    [self setButtonsAndLabelsAlphaTo:1];
}

- (IBAction)signupButtonClicked:(id)sender {
    [self performSegueWithIdentifier:@"Signup Push Segue" sender:nil];
}


- (IBAction)signinButtonClicked:(id)sender {
    [self performSegueWithIdentifier:@"Signin Push Segue" sender:nil];
}

- (void)setButtonsAndLabelsAlphaTo:(float)alpha{
    if (alpha<0||alpha>1){
        return;
    }
    self.facebookButtonView.alpha = alpha;
    self.facebookFirstLabel.alpha = alpha;
    self.facebookSecondLabel.alpha = alpha;
    self.signupButtonView.alpha = alpha;
    self.signupFirstLabel.alpha = alpha;
    self.signupSecondLabel.alpha = alpha;
    self.signinButton.alpha = alpha;
    self.signinLabel.alpha = alpha;
}


@end