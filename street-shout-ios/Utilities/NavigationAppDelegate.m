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
        config.inProduction = YES;
    } else {
        [TestFlight takeOff:kDevTestFlightAppToken];
        config.inProduction = NO;
    }
    
    // Call takeOff (which creates the UAirship singleton)	
    [UAirship takeOff:config];
    
    NSDictionary *remoteNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    
    if(remoteNotif && [remoteNotif objectForKey:@"extra"])
    {
        NSDictionary *extra = [remoteNotif objectForKey:@"extra"];
        NSUInteger shoutId = [[extra objectForKey:@"shout_id"] integerValue];
        
        UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
        NavigationViewController *navigationViewController = (NavigationViewController *) [navController topViewController];
        
        [AFStreetShoutAPIClient getShoutInfo:shoutId AndExecute:^(Shout *shout) {
            [navigationViewController onShoutNotificationPressed:shout];
        }];
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
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)notification
{
    if([notification objectForKey:@"extra"])
    {
        NSDictionary *extra = [notification objectForKey:@"extra"];
        NSUInteger shoutId = [[extra objectForKey:@"shout_id"] integerValue];
        
        UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
        
        if ([[navController topViewController] isKindOfClass:[NavigationViewController class]]) {
            NavigationViewController *navigationViewController = (NavigationViewController *) [navController topViewController];
            
            [AFStreetShoutAPIClient getShoutInfo:shoutId AndExecute:^(Shout *shout) {
                [navigationViewController onShoutNotificationPressed:shout];
            }];
        }
    }
}

@end
