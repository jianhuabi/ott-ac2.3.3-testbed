//
//  AppDelegate_iPad.h
//  TestBed
//
//  Created by Apple User on 11/14/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;
@class TestDetailViewController;
#ifdef MARKETING_DEMO
@class DemoDetailViewController;
#endif

@interface TestBedAppDelegate_iPad : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    
    UISplitViewController *testSplitViewController;
    RootViewController *testRootViewController;
    TestDetailViewController *testDetailViewController;
    UINavigationController *testNavigationController;
#ifdef MARKETING_DEMO
    UISplitViewController *demoSplitViewController;
    RootViewController *demoRootViewController;
    DemoDetailViewController *demoDetailViewController;
    UINavigationController *demoNavigationController;
#endif
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) UISplitViewController *testSplitViewController;
@property (nonatomic, retain) RootViewController *testRootViewController;
@property (nonatomic, retain) TestDetailViewController *testDetailViewController;
@property (nonatomic, retain) UINavigationController *testNavigationController;
#ifdef MARKETING_DEMO
@property (nonatomic, retain) UISplitViewController *demoSplitViewController;
@property (nonatomic, retain) RootViewController *demoRootViewController;
@property (nonatomic, retain) DemoDetailViewController *demoDetailViewController;
@property (nonatomic, retain) UINavigationController *demoNavigationController;
#endif

@end

