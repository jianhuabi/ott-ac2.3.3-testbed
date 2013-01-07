//
//  AppDelegate_iPhone.h
//  TestBed
//
//  Created by Apple User on 11/12/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;
@class TestDetailViewController;
#ifdef MARKETING_DEMO
@class DemoDetailViewController;
#endif

@interface TestBedAppDelegate_iPhone : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    
    UITabBarController *testTabBarController;
    RootViewController *testRootViewController;
    TestDetailViewController *testDetailViewController;
#ifdef MARKETING_DEMO
    UITabBarController *demoTabBarController;
    RootViewController *demoRootViewController;
    DemoDetailViewController *demoDetailViewController;
#endif
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) UITabBarController *testTabBarController;
@property (nonatomic, retain) RootViewController *testRootViewController;
@property (nonatomic, retain) TestDetailViewController *testDetailViewController;

#ifdef MARKETING_DEMO
@property (nonatomic, retain) UITabBarController *demoTabBarController;
@property (nonatomic, retain) RootViewController *demoRootViewController;
@property (nonatomic, retain) DemoDetailViewController *demoDetailViewController;
#endif


@end

