//
//  AppDelegate.m
//  imdNews
//
//  Created by wulg on 3/26/12.
//  Copyright (c) 2012 www.i-md.com. All rights reserved.
//

#import "AppDelegate.h"
#import "LocalSubstitutionCache.h"
#import "GANTracker.h"

#define USINGCACHE

// Dispatch period in seconds
static const NSInteger kGANDispatchPeriodSec = 10;
// **************************************************************************
// PLEASE REPLACE WITH YOUR ACCOUNT DETAILS.
// **************************************************************************
static NSString* const kAnalyticsAccountId = @"UA-31042333-1";


@implementation AppDelegate

@synthesize window = _window;
@synthesize myRootController;

- (void)dealloc
{
    
    [myRootController release];
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    [[GANTracker sharedTracker] startTrackerWithAccountID:kAnalyticsAccountId
                                           dispatchPeriod:kGANDispatchPeriodSec
                                                 delegate:nil];

    
    
#ifdef USINGCACHE    
    LocalSubstitutionCache *cache = [[[LocalSubstitutionCache alloc] init] autorelease];
	[NSURLCache setSharedURLCache:cache];
    
#endif    
    
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    myRootController =[[rootViewController alloc] init];
    //[self.window addSubview:myRootController.view];
    
    //for 6.0
    NSString *reqSysVer = @"6.0";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    
    if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
    {
        [self.window setRootViewController:myRootController]; //iOS 6
    } else {
        [self.window addSubview: myRootController.view]; //iOS 5 or less
    }
    
    [self.window makeKeyAndVisible];
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



@end
