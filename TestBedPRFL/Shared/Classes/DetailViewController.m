//
//  DetailViewController.m
//  TestBed
//
//  Created by Apple User on 11/15/10.
//  Copyright 2011 Irdeto. All rights reserved.
//

#import "DetailViewController.h"
#import "RootViewController.h"
#import "Tests.h"

@interface DetailViewController ()

- (void) configureView;
- (void) showHideRootView:(BOOL)showFlag;

@end


@implementation ACURLParams

@synthesize customData;
@synthesize urlType;
@synthesize url;

@end

@implementation DownloadProgressBarParameters

@synthesize testId=_testId;
@synthesize targetClass=_targetClass;
@synthesize progressValue=_progressValue;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)initWithTestId:(NSString *)testId targetClass:(Class)targetClass andProgress:(float)progressValue {
    
    [super init];
    
    self->_progressValue = progressValue;
    self->_targetClass = targetClass;
    self->_testId = testId;
    
    return self;
}

@end

static char CharForCurrentThread(void)
// Returns 'M' if we're running on the main thread, or 'S' otherwies.
{
    return [NSThread isMainThread] ? 'M' : 'S';
}

@implementation DetailViewController

@synthesize detailItem = __detailItem;
@synthesize detailDescriptionLabel = __detailDescriptionLabel;
@synthesize toolbar = __toolbar;
@synthesize outputTextView = __outputTextView;
@synthesize popoverController = __popoverController;
@synthesize popoverButtonItem = __popoverButtonItem;
@synthesize netServiceController = __netServiceController;
@synthesize testEventController = __testEventController;
@synthesize splitViewController = __splitViewController;
@synthesize navigationController = __navigationController;
@synthesize window = __window;
@synthesize rootViewController = __rootViewController;
@synthesize showContentPopover = __showContentPopover;
@synthesize lastPosition = __lastPosition;

@synthesize activeCloakMediaPlayer = __activeCloakMediaPlayer;
@synthesize activeCloakAgent = __activeCloakAgent;
@synthesize activeCloakContentManager = __activeCloakContentManager;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id) init {
    [super init];
    
    
	if (IS_IPHONE)
	{
        // In the iPhone mode we should setup TabBarItem attributes like and image and title
        // to show it correctly in the GUI
        self.tabBarItem.image = [UIImage imageNamed:@"log-black.png"];
        self.title = @"Log Info";
    }
    self.showContentPopover = NO;
    
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)setActiveCloakMediaPlayer:(ActiveCloakMediaPlayer*)value
{
	if (__activeCloakMediaPlayer != nil)
	{
        //Replacing the existing player.
        [[NSNotificationCenter defaultCenter] removeObserver:[RootViewController currentView:nil].currentGroupView.currentTestGroup.testsObject
                                                        name:MPMoviePlayerPlaybackDidFinishNotification
                                                      object:__activeCloakMediaPlayer];
        [__activeCloakMediaPlayer stop];
		[__activeCloakMediaPlayer close];
        TestLog("%c MediaPlayer removed\n", CharForCurrentThread());
		[__activeCloakMediaPlayer.view removeFromSuperview];
        [__activeCloakMediaPlayer.view setHidden:YES];
        [__activeCloakMediaPlayer release];
        
        if ([self respondsToSelector:@selector(onMediaPlayerActivated:)]) {
            [self onMediaPlayerActivated:NO];
        }
	}
	
	if (value == nil)
	{
		__activeCloakMediaPlayer = nil;
	}
	else
	{		
		__activeCloakMediaPlayer = [value retain];
        if ([self respondsToSelector:@selector(onMediaPlayerActivated:)]) {
            [self onMediaPlayerActivated:YES];
        }
	}
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (UIView *)getCurrentView {
    return self.view;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (UIToolbar *)getCurrentToolbar {
    return self.toolbar;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)setDetailItem:(id)newDetailItem 
{
    if (self.detailItem != newDetailItem) 
	{
        self.detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
    
    if (self.popoverController != nil) 
	{
        [self.popoverController dismissPopoverAnimated:YES];
    }        
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)configureView 
{
    self.detailDescriptionLabel.text = [self.detailItem description];   
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc 
{
    barButtonItem.title = @"Tests";
    // fprintf(stderr, "splitViewController:svc=0x%08x willHideViewController: aViewControlle=0x%08x, withBarButtonItem: barButtonItem=0x%08x forPopoverController: pc=0x%08x\n",
    //       (NSUInteger)svc, (NSUInteger)aViewController, (NSUInteger)barButtonItem, (NSUInteger)pc);
    NSMutableArray *items = [[self.toolbar items] mutableCopy];
    [items insertObject:barButtonItem atIndex:0];
    [self.toolbar setItems:items animated:YES];
    [items release];
    self.popoverController = pc;
    self.popoverButtonItem = barButtonItem;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    NSMutableArray *items = [[self.toolbar items] mutableCopy];
    [items removeObjectAtIndex:0];
    [self.toolbar setItems:items animated:YES];
    [items release];
    self.popoverController = nil;
    self.popoverButtonItem = nil;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)dealloc
{
    self.popoverController = nil;
    self.popoverButtonItem = nil;
    
    self.detailItem = nil;
    self.detailDescriptionLabel = nil;
    self.netServiceController = nil;
    self.testEventController = nil;
    self.toolbar = nil;
    [super dealloc];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)viewDidLoad {
    self.netServiceController = [[NetServiceController alloc] initWithView:self];
    [self showNetServiceConnected:nil];
    self.testEventController = [[TestEventController alloc] initWithDetailViewController:self
                                                                         NetService:self.netServiceController];
    [self.netServiceController setDelegate:(id)self.testEventController];
    
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)viewDidUnload
{
    self.popoverController = nil;
    self.popoverButtonItem = nil;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)showNetServiceConnected:(NSString *)netServiceName {
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) showHideRootView:(BOOL)showFlag {
	if (IS_IPHONE)	{
        // In iPhone version of TestBed we need to switch to the RootViewController view
        // in order to start automatic testing. Therefore we are obtaining TabBarController,
        // verifing in which view we are in, and selecting the required RootViewController
        // view if the parameter 'show' is YES.
        // If the parameter is NO, the other tab bar is selecting hiding RootViewController
        UITabBarController *tabBarController = [[RootViewController currentView:nil] tabBarController];
        UIViewController *requiredView = [tabBarController.viewControllers objectAtIndex: showFlag ? 0 : 1];
        
        if (![requiredView isEqual:tabBarController.selectedViewController]) {
            tabBarController.selectedViewController = requiredView;
        }
    } else {
        // In the iPad version of TestBed, we need to popup the popoverController 
        // that contains the RootViewController view in order to start automatic testing.
        self.showContentPopover = showFlag;
        if (self.popoverController != nil && showFlag && !self.popoverController.popoverVisible) {
            [self.popoverController presentPopoverFromBarButtonItem:self.popoverButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
            self.showContentPopover = NO;
        } else if (self.popoverController != nil && !showFlag && self.popoverController.popoverVisible) {
            [self.popoverController dismissPopoverAnimated:NO];
        }
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) showRootView {
    [self showHideRootView:YES];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) hideRootView {
    [self showHideRootView:NO];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(BOOL)registerDynamicUnitTestWithId:(NSString *)testId
                   fromTestsInstance:(Tests *)testsInstance
                           withClass:(Class)testClass
                 usingMethodSelector:(SEL)methodSelector
                         withEntryId:(NSString*)entryId
                           inSection:(NSString*)sectionName {
    BOOL success = YES;
    Method testMethod = class_getInstanceMethod(testClass, methodSelector);
    success = [self.rootViewController.testRepository registerUnitTestWithId:testId
                                                      fromTestsInstance:testsInstance
                                                              withClass:testClass
                                                            usingMethod:testMethod
                                                            withEntryId:entryId
                                                              inSection:sectionName];
    return success;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(BOOL)removeTestSectionByName:(NSString *)sectionName inClass:(Class)testsClass {
    BOOL success = YES;
    success = [self.rootViewController.testRepository removeTestSectionByName:sectionName inClass:testsClass];
    return success;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(void)enableProgressBar:(BOOL)enable forTestId:(NSString *)testId inTargetClass:(Class)targetClass {

    TestGroup *parentTestGroup = [self.rootViewController.testRepository getTestGroupForClass:targetClass];
    NSIndexPath *indexPath = [parentTestGroup getTestIndexById:testId];
    if (indexPath != nil) {
        Test *test = (Test *)[parentTestGroup getTestObject:indexPath];
        test.showProgressBar = enable;
        test.progressValue = 0;
        GroupViewController *currentGroupView = [RootViewController currentView:nil].currentGroupView;
        if (currentGroupView.currentTestGroup == parentTestGroup) {
            [currentGroupView enableProgressBar:enable atIndexPath:indexPath withProgress:test.progressValue];
        }
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(void)updateProgressBarForTestId:(NSString *)testId inTargetClass:(Class)targetClass withProgress:(float)progressValue {
    
    TestGroup *parentTestGroup = [self.rootViewController.testRepository getTestGroupForClass:targetClass];
    NSIndexPath *indexPath = [parentTestGroup getTestIndexById:testId];
    if (indexPath != nil) {
        Test *test = (Test *)[parentTestGroup getTestObject:indexPath];
        test.progressValue = progressValue;
        GroupViewController *currentGroupView = [RootViewController currentView:nil].currentGroupView;
        if (currentGroupView.currentTestGroup == parentTestGroup) {
            [currentGroupView updateProgressBarAtIndexPath:indexPath withProgress:progressValue];
        }
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(void)enableProgressBar:(DownloadProgressBarParameters*)parameters {
    
    [self enableProgressBar:YES forTestId:parameters.testId inTargetClass:parameters.targetClass];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(void)disableProgressBar:(DownloadProgressBarParameters*)parameters {
    
    [self enableProgressBar:NO forTestId:parameters.testId inTargetClass:parameters.targetClass];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(void)updateProgressBar:(DownloadProgressBarParameters*)parameters {
    
    [self updateProgressBarForTestId:parameters.testId inTargetClass:parameters.targetClass withProgress:parameters.progressValue];
}

@end

