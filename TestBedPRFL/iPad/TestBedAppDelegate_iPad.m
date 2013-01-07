//
//  AppDelegate_iPad.m
//  TestBed
//
//  Created by Apple User on 11/11/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#import "TestBedAppDelegate_iPad.h"
#import "RootViewController.h"
#import "DetailViewController.h"
#import "TestDetailViewController.h"

#ifdef MARKETING_DEMO
#import "DemoDetailViewController.h"
#endif

@implementation TestBedAppDelegate_iPad

@synthesize window;
@synthesize testSplitViewController;
@synthesize testRootViewController;
@synthesize testDetailViewController;
@synthesize testNavigationController;
#ifdef MARKETING_DEMO
@synthesize demoSplitViewController;
@synthesize demoRootViewController;
@synthesize demoDetailViewController;
@synthesize demoNavigationController;
#endif

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    

    // Override point for customization after app launch    
    
    // Add the split view controller's view to the window and display.
	
    testSplitViewController = [[UISplitViewController alloc] init];

    TestOptions testOptions = TestOption_UseSections|TestOption_UseIcons|TestOption_UserDefinedOrder;
    TestFilter *testFilter = [[[TestFilter alloc] initWithOptions:testOptions
                                                    withGroupNames:nil
                                                    andWithTestFlags:TestFlag_Empty] autorelease];
	
    testRootViewController = [[RootViewController alloc] initWithStyle:UITableViewStyleGrouped andTestFilter:testFilter];

    testNavigationController = [[UINavigationController alloc] initWithRootViewController:testRootViewController];
    
    // Create DetailViewController from DetailView_iPad.xib file
    testDetailViewController = [[TestDetailViewController alloc] init];
    [testDetailViewController initWithNibName:@"DetailView_iPad" bundle:nil];
    testRootViewController.detailViewController = testDetailViewController;
    testDetailViewController.navigationController = testNavigationController;
    
    testDetailViewController.splitViewController = testSplitViewController;
    testDetailViewController.window = window;
    testDetailViewController.rootViewController = testRootViewController;

    testSplitViewController.delegate = testDetailViewController;
    testSplitViewController.viewControllers = [NSArray arrayWithObjects:testNavigationController, testDetailViewController, nil];
	
#ifdef MARKETING_DEMO
    
    demoSplitViewController = [[UISplitViewController alloc] init];
    
    NSArray *groupNameList = [[[NSArray alloc] initWithObjects:@"VideoTests", @"DownloadAndGoTests", @"ProgressiveDownloadTests", nil] autorelease];
    TestOptions demoOptions = TestOption_UseSections|TestOption_UseIcons|TestOption_UserDefinedOrder|TestOption_HideTopRunButton|TestOption_ExecuteTestGenerators;
    TestFilter *demoTestFilter = [[[TestFilter alloc] initWithOptions:demoOptions
                                                       withGroupNames:groupNameList
                                                     andWithTestFlags:TestFlag_DemoTest] autorelease];
    
	demoRootViewController = [[RootViewController alloc] initWithStyle:UITableViewStyleGrouped andTestFilter:demoTestFilter];

    demoNavigationController = [[UINavigationController alloc] initWithRootViewController:demoRootViewController];
    
    // Create DetailViewController from DemoDetailView_iPad.xib file
    demoDetailViewController = [[DemoDetailViewController alloc] init];
    [demoDetailViewController initWithNibName:@"DemoDetailView_iPad" bundle:nil];
    demoRootViewController.detailViewController = demoDetailViewController;
    demoDetailViewController.navigationController = demoNavigationController;
    
    demoDetailViewController.splitViewController = demoSplitViewController;
    demoDetailViewController.window = window;
    demoDetailViewController.rootViewController = demoRootViewController;

    demoSplitViewController.delegate = demoDetailViewController;
    demoSplitViewController.viewControllers = [NSArray arrayWithObjects:demoNavigationController, demoDetailViewController, nil];
 
    testDetailViewController.demoDetailViewController = demoDetailViewController;
    demoDetailViewController.testDetailViewController = testDetailViewController;

#ifdef ACTIVECLOAKDEMO
    [window addSubview:demoSplitViewController.view];
    testSplitViewController.view.hidden = YES;
    [window addSubview:testSplitViewController.view];
    // the primary root view controller should setup after we added subviews
    // because the split view controller will setup its own root view controller
    // as a primary when its added to the window
	[RootViewController currentView:demoDetailViewController.rootViewController];
#else
    [window addSubview:testSplitViewController.view];
    demoSplitViewController.view.hidden = YES;
    [window addSubview:demoSplitViewController.view];
    // the primary root view controller should setup after we added subviews
    // because the split view controller will setup its own root view controller
    // as a primary when its added to the window
	[RootViewController currentView:testDetailViewController.rootViewController];
#endif

#else 
    [window setRootViewController: testSplitViewController]; // use 'addSubview' for iOS versions < 4.0
	[RootViewController currentView:testDetailViewController.rootViewController];
#endif
    
    [window makeKeyAndVisible];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
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
    [testSplitViewController release];
    [testRootViewController release];
    [testDetailViewController release];
    [testNavigationController release];
#ifdef MARKETING_DEMO
    [demoSplitViewController release];
    [demoRootViewController release];
    [demoDetailViewController release];
    [demoNavigationController release];
#endif
    [window release];
    [super dealloc];
}


@end
