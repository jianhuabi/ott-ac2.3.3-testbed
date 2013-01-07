//
//  DetailViewController.h
//  TestBed
//
//  Created by Apple User on 11/15/10.
//  Copyright 2011 Irdeto. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActiveCloakMediaPlayer.h"
#import "ActiveCloakAgent.h"
#import "ActiveCloakContentManager.h"
#import "NetServiceController.h"
#import "TestEventController.h"
#import "Tests.h"

@class RootViewController;

@protocol TestBedEngineAPI

-(BOOL)registerDynamicUnitTestWithId:(NSString *)testId
                   fromTestsInstance:(Tests *)testsInstance
                           withClass:(Class)testClass
                 usingMethodSelector:(SEL)methodSelector
                         withEntryId:(NSString*)entryId
                           inSection:(NSString*)sectionName;
-(BOOL)removeTestSectionByName:(NSString *)sectionName inClass:(Class)testsClass;

@end


@interface ACURLParams : NSObject
{
}

/**
 * Minimum OPL for compressed digital video (e.g. H.264)
 */
@property (nonatomic, retain) NSString *customData;
@property (nonatomic) ACURLType urlType;
@property (nonatomic, copy) NSURL *url; 

@end

@interface DownloadProgressBarParameters : NSObject
{
}

-(id)initWithTestId:(NSString *)testId targetClass:(Class)targetClass andProgress:(float)progressValue;

@property (nonatomic, readonly) NSString* testId;
@property (nonatomic, readonly) Class targetClass;
@property (nonatomic, readonly) float progressValue;

@end

@interface DetailViewController : UIViewController <UIPopoverControllerDelegate, UISplitViewControllerDelegate, NetServiceView, UIActionSheetDelegate, TestBedEngineAPI> 
{
}

@property (nonatomic, retain) IBOutlet UILabel *detailDescriptionLabel;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UITextView *outputTextView;
@property (nonatomic, retain) id detailItem;
@property (nonatomic) NSTimeInterval lastPosition;

@property (nonatomic, retain) NetServiceController *netServiceController;
@property (nonatomic, retain) TestEventController *testEventController;
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain) UIBarButtonItem *popoverButtonItem;
@property (nonatomic, assign) UISplitViewController *splitViewController;
@property (nonatomic, assign) UINavigationController *navigationController;
@property (nonatomic, assign) UIWindow *window;
@property (nonatomic, assign) RootViewController *rootViewController;
@property (assign) BOOL showContentPopover;

@property (nonatomic, retain) ActiveCloakMediaPlayer * activeCloakMediaPlayer;
@property (nonatomic, retain) ActiveCloakAgent * activeCloakAgent;
@property (nonatomic, retain) ActiveCloakContentManager * activeCloakContentManager;

- (id) init;

- (void) onMediaPlayerActivated:(BOOL)activated;
- (void) showRootView;
- (void) hideRootView;

// implementation of TestBedEngineAPI
-(BOOL)registerDynamicUnitTestWithId:(NSString *)testId
                   fromTestsInstance:(Tests *)testsInstance
                           withClass:(Class)testClass
                 usingMethodSelector:(SEL)methodSelector
                         withEntryId:(NSString*)entryId
                           inSection:(NSString*)sectionName;
-(BOOL)removeTestSectionByName:(NSString *)sectionName inClass:(Class)testsClass;

-(void)enableProgressBar:(BOOL)enable forTestId:(NSString *)testId inTargetClass:(Class)targetClass;
-(void)updateProgressBarForTestId:(NSString *)testId inTargetClass:(Class)targetClass withProgress:(float)progressValue;

-(void)enableProgressBar:(DownloadProgressBarParameters*)parameters;
-(void)disableProgressBar:(DownloadProgressBarParameters*)parameters;
-(void)updateProgressBar:(DownloadProgressBarParameters*)parameters;

@end

