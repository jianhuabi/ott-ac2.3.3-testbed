//
//  AppDelegate_iPhone.m
//  TestBed
//
//  Created by Apple User on 11/12/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#import "TestBedAppDelegate_iPhone.h"
#import "RootViewController.h"
#import "DetailViewController.h"
#import "TestDetailViewController.h"
#ifdef MARKETING_DEMO
#import "DemoDetailViewController.h"
#endif

@implementation TestBedAppDelegate_iPhone

@synthesize window;
@synthesize testRootViewController;
@synthesize testDetailViewController;
@synthesize testTabBarController;
#ifdef MARKETING_DEMO
@synthesize demoRootViewController;
@synthesize demoDetailViewController;
@synthesize demoTabBarController;
#endif


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Now we need a UITabBarController to organize two views:
    // (1) view for test cases that insludes UINavigationController with RootViewController 
    //     and subsequent GroupViewControlles to show test case groups
    // (2) a view for DetailViewController with UITextView for logging and Media Player view
    testTabBarController = [[UITabBarController alloc] init];
    
    // Create RootViewController and include it into the UINavigatorController
    TestFilter *testFilter = [[[TestFilter alloc] initWithOptions:(TestOption_UseSections|TestOption_UseIcons|TestOption_UserDefinedOrder)
                                                   withGroupNames:nil
                                                 andWithTestFlags:TestFlag_Empty] autorelease];
	testRootViewController = [[RootViewController alloc] initWithStyle:UITableViewStyleGrouped testFilter:testFilter andTabBarController:testTabBarController];
    UINavigationController *testNavigationController = [[UINavigationController alloc] initWithRootViewController:testRootViewController];
    
    // Create DetailViewController from DetailView_iPhone.xib file
    testDetailViewController = [[TestDetailViewController alloc] init];
    [testDetailViewController initWithNibName:@"DetailView_iPhone" bundle:nil];
    testRootViewController.detailViewController = testDetailViewController;
    testDetailViewController.navigationController = testNavigationController;
    
    // Create an array of controllers to include into the prepeared UITabBarController
    NSArray *testControllers = [NSArray arrayWithObjects:testNavigationController, testDetailViewController, nil];
    testTabBarController.viewControllers = testControllers;
    testDetailViewController.rootViewController = testRootViewController;
    
#ifdef MARKETING_DEMO
    demoTabBarController = [[UITabBarController alloc] init];
    
	demoRootViewController = [[RootViewController alloc] initWithStyle:UITableViewStylePlain andTabBarController:demoTabBarController];
    UINavigationController *demoNavigationController = [[UINavigationController alloc] initWithRootViewController:demoRootViewController];
    
    // Create DetailViewController from DemoDetailView_iPad.xib file
    demoDetailViewController = [[DemoDetailViewController alloc] init];
    [demoDetailViewController initWithNibName:@"DemoDetailView_iPhone" bundle:nil];
    demoRootViewController.detailViewController = demoDetailViewController;
    demoDetailViewController.navigationController = demoNavigationController;

    // Create an array of controllers to include into the prepeared UITabBarController
    NSArray *demoControllers = [NSArray arrayWithObjects:demoNavigationController, demoDetailViewController, nil];
    demoTabBarController.viewControllers = demoControllers;
    demoDetailViewController.rootViewController = demoRootViewController;
    
    testDetailViewController.demoDetailViewController = demoDetailViewController;
    demoDetailViewController.testDetailViewController = testDetailViewController;
#endif
    
    // Add UITabBarController to the window
    [window setRootViewController: testTabBarController]; // use 'addSubview' for iOS versions < 4.0
    [window makeKeyAndVisible];
    
    return YES;
    
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    [testTabBarController release];
    [testRootViewController release];
    [testDetailViewController release];
#ifdef MARKETING_DEMO
    [demoTabBarController release];
    [demoRootViewController release];
    [demoDetailViewController release];
#endif
    [window release];
    [super dealloc];
}


@end
