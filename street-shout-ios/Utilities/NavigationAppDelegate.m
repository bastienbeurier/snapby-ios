//
//  NavigationAppDelegate.m
//  street-shout-ios
//
//  Created by Bastien Beurier on 7/16/13.
//  Copyright (c) 2013 Street Shout. All rights reserved.
//

#import "NavigationAppDelegate.h"
#import "Constants.h"
#import "UAirship.h"
#import "UAConfig.h"
#import "UAPush.h"
#import "TestFlight.h"
#import "Constants.h"
#import "NavigationViewController.h"
#import "Shout.h"
#import "AFStreetShoutAPIClient.h"
#import "Mixpanel.h"
#import "TrackingUtilities.h"
#import "SessionUtilities.h"
#import "WelcomeViewController.h"
#import "GeneralUtilities.h"
#import "MBProgressHUD.h"
#import "SigninViewController.h"
#import "SignupViewController.h"
#import "ForgotPasswordViewController.h"
#import "LikesViewController.h"
#import "AFNetworkActivityIndicatorManager.h"

@implementation NavigationAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
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
    
    // Manage the network activity indicator
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    // Urban airship config
    [UAirship takeOff:config];
    
    NSDictionary *remoteNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    
    //Notification received when app closed
    if(remoteNotif) {
        [self setRedirectionToNotificationShout:remoteNotif];
    }
    
    // Check if the user has not been logged out
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
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [TrackingUtilities trackAppOpened];
    
    // Handle the user leaving the app while the Facebook login dialog is being shown
    [FBAppCall handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    // Close the FB session before quitting
    [FBSession.activeSession close];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)notification
{
    //Notification received when app is opened
    [self application:application handlePushNotification:notification];
}

- (void)application:(UIApplication *)application handlePushNotification:(NSDictionary *)notification
{
    if (application.applicationState != UIApplicationStateActive && [notification objectForKey:@"extra"]) {
        UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
        
        if ([[navController topViewController] isKindOfClass:[NavigationViewController class]]) {
            NavigationViewController *navigationViewController = (NavigationViewController *) [navController topViewController];
            
            NSDictionary *extra = [notification objectForKey:@"extra"];
            NSUInteger shoutId = [[extra objectForKey:@"shout_id"] integerValue];
            
            [AFStreetShoutAPIClient getShoutInfo:shoutId AndExecuteSuccess:^(Shout *shout){
                [navigationViewController onShoutNotificationPressedWhileAppInNavigationVC:shout];
            } failure:nil];
        } else if ([[navController topViewController] isKindOfClass:[ShoutViewController class]] ||
            [[navController topViewController] isKindOfClass:[SettingsViewController class]] ||
            [[navController topViewController] isKindOfClass:[CreateShoutViewController class]]) {
            
            [self setRedirectionToNotificationShout:notification];
            [navController popViewControllerAnimated:NO];
            
        } else if ([[navController topViewController] isKindOfClass:[CommentsViewController class]] ||
                   [[navController topViewController] isKindOfClass:[LikesViewController class]] ||
                   [[navController topViewController] isKindOfClass:[RefineShoutLocationViewController class]]) {
            
            [self setRedirectionToNotificationShout:notification];
            [navController popViewControllerAnimated:NO];
            [navController popViewControllerAnimated:NO];
            
        } else if ([[navController topViewController] isKindOfClass:[SigninViewController class]] ||
                   [[navController topViewController] isKindOfClass:[SignupViewController class]] ||
                   [[navController topViewController] isKindOfClass:[WelcomeViewController class]] ||
                   [[navController topViewController] isKindOfClass:[ForgotPasswordViewController class]]) {
            
            [self setRedirectionToNotificationShout:notification];
        }

    }
}

- (void)setRedirectionToNotificationShout:(NSDictionary *)notification
{
    NSDictionary *extra = [notification objectForKey:@"extra"];
    NSUInteger shoutId = [[extra objectForKey:@"shout_id"] integerValue];

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    [prefs setObject:[NSNumber numberWithInt:shoutId] forKey:NOTIFICATION_SHOUT_ID_PREF];
    [prefs synchronize];
}


// Jump directly to Navigation View Controller
-(void)skipWelcomeController
{
    //Mixpanel identification
    [TrackingUtilities identifyWithMixpanel:[SessionUtilities getCurrentUser] isSigningUp:NO];
    
    WelcomeViewController* welcomeViewController = (WelcomeViewController *)  self.window.rootViewController.childViewControllers[0];
    [welcomeViewController performSegueWithIdentifier:@"Navigation Push Segue From Welcome" sender:nil];
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
                    [self sendSignInOrUpRequestWithFacebookParameters: result];
                    
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
                NSLog(@"User cancelled login");
                
                // Handle session closures that happen outside of the app
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
// Override application:openURL:sourceApplication:annotation to call the FBsession object that handles the incoming URL
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    return [FBSession.activeSession handleOpenURL:url];
}


// Prepare failure and success block for the signInOrUpWithFacebookWithParameters request
- (void)sendSignInOrUpRequestWithFacebookParameters: (id)params
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
        [AFStreetShoutAPIClient signInOrUpWithFacebookWithParameters:params success:successBlock failure:failureBlock];
    });
}

@end
