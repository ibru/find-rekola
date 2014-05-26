//
//  AppDelegate.m
//  Rekola
//
//  Created by Jiri Urbasek on 25/05/14.
//  Copyright (c) 2014 Jiri Urbasek. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    UIColor *pinkColor = [UIColor colorWithRed:251.0/255.0 green:12.0/255.0 blue:135.0/255.0 alpha:1];
    UIColor *greenColor = [UIColor colorWithRed:89.0/255.0 green:125.0/255.0 blue:27.0/255.0 alpha:1];
    UIColor *whiteColor = [UIColor whiteColor];
    
    [UINavigationBar appearance].tintColor = whiteColor;
    [UINavigationBar appearance].barTintColor = pinkColor;
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : whiteColor}];

    [UIButton appearance].tintColor = greenColor;
    
    [UITableView appearance].separatorColor = greenColor;
    
    [UITableViewCell appearance].tintColor = greenColor;
    
    return YES;
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
    
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
