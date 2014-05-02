//
//  NavigationAppDelegate.m
//  snapby-ios
//
//  Created by Bastien Beurier on 7/16/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "NavigationAppDelegate.h"
#import "Constants.h"
#import "UAirship.h"
#import "UAConfig.h"
#import "UAPush.h"
#import "TestFlight.h"
#import "Constants.h"
#import "Snapby.h"
#import "ApiUtilities.h"
#import "Mixpanel.h"
#import "TrackingUtilities.h"
#import "SessionUtilities.h"
#import "WelcomeViewController.h"
#import "GeneralUtilities.h"
#import "MBProgressHUD.h"
#import "SigninViewController.h"
#import "SignupViewController.h"
#import "ForgotPasswordViewController.h"
#import "AFNetworkActivityIndicatorManager.h"
#import <GoogleMaps/GoogleMaps.h>
#import "UVConfig.h"
#import "UserVoice.h"
#import "SessionUtilities.h"
#import "ImageUtilities.h"

@interface NavigationAppDelegate()

@property (strong, nonatomic) UIAlertView *obsoleteAPIAlertView;

@end

@implementation NavigationAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // !!!: Use setDeviceIdentifier (removing deprecated warning with clang pragmas)
#ifdef TESTING
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#pragma clang diagnostic pop
#endif
    
    // Populate AirshipConfig.plist with your app's info from https://go.urbanairship.com
    // or set runtime properties here.
    UAConfig *config = [UAConfig defaultConfig];
    
    if (PRODUCTION) {
        [TestFlight takeOff:kProdTestFlightAppToken];
        [Mixpanel sharedInstanceWithToken:kProdMixPanelToken];
        config.inProduction = YES;
    } else {
        [TestFlight takeOff:kDevTestFlightAppToken];
        [Mixpanel sharedInstanceWithToken:kDevMixPanelToken];
        config.inProduction = NO;
    }
    
    //UserVoice
    // Set this up once when your application launches
    UVConfig *configUV = [UVConfig configWithSite:@"snapby.uservoice.com"];
    configUV.showKnowledgeBase = NO;
    configUV.forumId = 250217;
    
    if ([SessionUtilities isSignedIn]) {
        User* user = [SessionUtilities getCurrentUser];
        
        [configUV identifyUserWithEmail:user.email name:user.username guid:[NSString stringWithFormat:@"%lu",user.identifier]];
    }
    //
    [UserVoice initialize:configUV];
    [UVStyleSheet instance].tintColor = [ImageUtilities getSnapbyPink];
    
    [GMSServices provideAPIKey:kGoogleMapKey];
    
    // Urban airship config
    [UAirship takeOff:config];
    
    // Manage the network activity indicator
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    // Handle the case were the user is still signed in
    if ([SessionUtilities isSignedIn]) {
        
        // Check if he logged in with facebook
        if([SessionUtilities isFBConnected]) {
            
            // In this case, there should be facebook token
            if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
                // If there's one, just open the session silently, without showing the user the login UI
                // It will automatically skip the welcome controller
                [FBSession openActiveSessionWithReadPermissions:@[@"basic_info",@"email"]
                                                   allowLoginUI:NO
                                              completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                                  // Handler for session state changes
                                                  [self sessionStateChanged:session state:state error:error];
                                              }];
            } else {
                // If there's no cached session, we delete everything and go normally to welcome
                [SessionUtilities wipeOffCredentials];
            }
        } else {
            [self skipWelcomeController];
        }
    }
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString* deviceTokenString = [[[[deviceToken description]
                                stringByReplacingOccurrencesOfString: @"<" withString: @""]
                               stringByReplacingOccurrencesOfString: @">" withString: @""]
                              stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    if (PRODUCTION) {
        [[NSUserDefaults standardUserDefaults] setObject:deviceTokenString forKey:UA_DEVICE_TOKEN_PROD_PREF];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:deviceTokenString forKey:UA_DEVICE_TOKEN_DEV_PREF];
    }
    
    // Updates the device token and registers the token with UA. This won't occur until
    // push is enabled if the outlined process is followed. This call is required.
    [[UAPush shared] registerDeviceToken:deviceToken];
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
    [navController popToViewController:navController.childViewControllers[1] animated:NO];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [TrackingUtilities trackAppOpened];
    
    // Handle the user leaving the app while the Facebook login dialog is being shown
    [FBAppCall handleDidBecomeActive];
    
    // Check if API obsolete
    [ApiUtilities checkAPIVersion:kApiVersion IsObsolete:^{
        [self createObsoleteAPIAlertView];
    }];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Close the FB session before quitting
    [FBSession.activeSession close];
}


// ---------------
// Notification
// ---------------

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)notification
{
    //Notification received when app is opened
    [self application:application handlePushNotification:notification];
}

- (void)application:(UIApplication *)application handlePushNotification:(NSDictionary *)notification
{
    
}


// Jump directly to Navigation View Controller
-(void)skipWelcomeController
{
    //Mixpanel identification
    [TrackingUtilities identifyWithMixpanel:[SessionUtilities getCurrentUser] isSigningUp:NO];
    
    WelcomeViewController* welcomeViewController = (WelcomeViewController *)  self.window.rootViewController.childViewControllers[0];
    [welcomeViewController performSegueWithIdentifier:@"Multiple From Welcome Push Segue" sender:nil];
}

// This method will handle ALL the session state changes in the app
- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
    
    __block NSString *alertText, *alertTitle;
    
    // If the session was opened successfully
    if (!error && state == FBSessionStateOpen) {
        
        // In case there is no server token yet
        if(![SessionUtilities isSignedIn]) {
            
            // Request information about the user
            [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    
                    // Get the user and token from the database
                    // If the user does not exist, it is created
                    [self sendConnectFacebookRequestWithParameters: result];
                    
                    // Set in the phone our connection preference
                    [SessionUtilities setFBConnectedPref:true];
            
                } else {
                    [MBProgressHUD hideHUDForView:self.window animated:YES];
                    alertTitle = NSLocalizedStringFromTable (@"fb_sign_in_error_title", @"Strings", @"comment");
                    alertText = NSLocalizedStringFromTable (@"Try_again_message", @"Strings", @"comment");
                    [GeneralUtilities showMessage:alertText withTitle:alertTitle];
                }
            }];
        } else {
            [self skipWelcomeController];
        }
        return;
    }
    if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed) {
        // If the session is closed
        NSLog(@"Session closed");
    }
    
    // Handle errors
    // see https://developers.facebook.com/docs/ios/errors for improvement

    if (error) {
        NSLog(@"Error");
        // If the error requires people using an app to make an action outside of the app in order to recover
        if ([FBErrorUtility shouldNotifyUserForError:error] == YES) {
            alertTitle = @"Something went wrong";
            alertText = [FBErrorUtility userMessageForError:error];
            [GeneralUtilities showMessage:alertText withTitle:alertTitle];
        } else {
            
            // If the user cancelled login, do nothing
            if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
                //The user refused to log in into your app, either ignore or...
                alertTitle = @"Login cancelled";
                alertText = @"You need to login to access this part of the app";
                [GeneralUtilities showMessage:alertText withTitle:alertTitle];
                
            } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
                alertTitle = @"Session Error";
                alertText = @"Your current session is no longer valid. Please log in again.";
                [GeneralUtilities showMessage:alertText withTitle:alertTitle];

            } else {
                //Get more error information from the error
                NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
                
                // Show the user an error message
                alertTitle = @"Something went wrong";
                alertText = [NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", [errorInformation objectForKey:@"message"]];
                [GeneralUtilities showMessage:alertText withTitle:alertTitle];
            }
            
            // Clear tokens
            [SessionUtilities redirectToSignIn];
        }
    }
}

// After facebook authentication, the app is called back with the session information.
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    return [FBSession.activeSession handleOpenURL:url];
}


// Prepare failure and success block for the signInOrUpWithFacebookWithParameters request
- (void)sendConnectFacebookRequestWithParameters: (id)params
{
    
    typedef void (^SuccessBlock)(User *, NSString *, BOOL);
    SuccessBlock successBlock = ^(User *user, NSString *authToken, BOOL isSignup) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.window animated:YES];
            [SessionUtilities updateCurrentUserInfoInPhone:user];
            [SessionUtilities securelySaveCurrentUserToken:authToken];
            
            //Mixpanel tracking
            if (isSignup) {
                [TrackingUtilities identifyWithMixpanel:user isSigningUp:YES];
                [TrackingUtilities trackSignUpWithSource:@"Facebook"];
            } else {
                [TrackingUtilities identifyWithMixpanel:user isSigningUp:NO];
            }

            [self skipWelcomeController];
        });
    };

    typedef void (^FailureBlock)(NSDictionary *);
    FailureBlock failureBlock = ^(NSDictionary * errors) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.window animated:YES];
            
            NSString *title = NSLocalizedStringFromTable (@"fb_sign_in_error_title", @"Strings", @"comment");
            NSString *message = NSLocalizedStringFromTable (@"Try_again_message", @"Strings", @"comment");
            
            [GeneralUtilities showMessage:message withTitle:title];
            [SessionUtilities redirectToSignIn];
        });
    };

    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [ApiUtilities connectFacebookWithParameters:params success:successBlock failure:failureBlock];
    });
}

// Check that API is not obsolete
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == self.obsoleteAPIAlertView) {
        [GeneralUtilities redirectToAppStore];
        [self createObsoleteAPIAlertView];
    }
}

- (void)createObsoleteAPIAlertView
{
    self.obsoleteAPIAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable (@"obsolete_api_error_title", @"Strings", @"comment")
                                                           message:NSLocalizedStringFromTable (@"obsolete_api_error_message", @"Strings", @"comment")
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
    [self.obsoleteAPIAlertView show];
}



@end
