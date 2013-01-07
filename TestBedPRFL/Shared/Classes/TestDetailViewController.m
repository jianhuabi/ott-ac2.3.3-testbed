//
//  TestDetailViewController.m
//  ActiveCloak
//
//  Created by Apple User on 2/26/11.
//  Copyright 2011 Irdeto. All rights reserved.
//

#import "RootViewController.h"
#import "Tests.h"
#import "TestDetailViewController.h"



@interface TestDetailViewController ()

#ifdef MARKETING_DEMO
- (void) switchToDemoMode;
#endif

@end


@implementation TestDetailViewController

@synthesize bottomToolbar;
@synthesize showHideMediaPlayerItem;
@synthesize menuItem;

#ifdef MARKETING_DEMO
@synthesize demoDetailViewController;
#endif

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id) init {
    [super init];
    
    self->_switchDemoModeMenuIndex = -1;
    self->_menuPopup = nil;
    
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) onMediaPlayerActivated:(BOOL)activated {
    if (activated) {
        showHideMediaPlayerItem.selectedSegmentIndex = 1;
		[self.activeCloakMediaPlayer.view setFrame:self.outputTextView.frame];
		self.activeCloakMediaPlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.activeCloakMediaPlayer.view setBackgroundColor:[UIColor blackColor]];
        [self.view addSubview:self.activeCloakMediaPlayer.view];
    }
    else {
        showHideMediaPlayerItem.selectedSegmentIndex = 0;
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (IBAction) showHideMediaPlayerSegmentAction:(id)sender {
    if (showHideMediaPlayerItem.selectedSegmentIndex == 0) {
        if (self.activeCloakMediaPlayer != nil) {
            [self.activeCloakMediaPlayer.view setHidden:YES];
        }
        [self.outputTextView setHidden:NO];
    } else {
        // showHideMediaPlayerItem.selectedSegmentIndex == 1 
        if (self.activeCloakMediaPlayer != nil) {
            [self.activeCloakMediaPlayer.view setHidden:NO];
            [self.outputTextView setHidden:YES];
        } else {
            showHideMediaPlayerItem.selectedSegmentIndex = 0;
            [self.outputTextView setHidden:NO];
        }
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (IBAction)showAboutDialog:(id)sender {
	// open an alert with just an OK button
    NSString *message = [[NSString alloc] initWithFormat:@"Copyright (C) 2010, Irdeto Canada\nDevice Name: %@", self.testEventController.deviceName];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"TestBed" message:message
                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [message release];
	[alert show];	
	[alert release];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (IBAction) showMenu:(id)sender {
    if (self->_menuPopup == nil) {
        self->_menuPopup = [[UIActionSheet alloc] initWithTitle:@"Menu:"
                                                       delegate:self 
                                              cancelButtonTitle:(IS_IPHONE) ? @"Cancel" : nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Reset Log",
                            @"Exit Media Player",
                            @"Send Status Report",
                            @"Send List of Tests",
                            nil];
        self->_menuPopup.isAccessibilityElement = YES;
        self->_menuPopup.accessibilityLabel = @"testModePopupMenu";
        
#ifdef MARKETING_DEMO
        if (IS_IPAD && self.activeCloakMediaPlayer == nil) {
            self->_switchDemoModeMenuIndex = [self->_menuPopup addButtonWithTitle:@"Switch to Demo Mode"];
        }
        else {
            self->_switchDemoModeMenuIndex = -1;
        }
#endif
        // use the same style as the nav bar
        self->_menuPopup.actionSheetStyle = self.navigationController.navigationBar.barStyle;
        
        [self->_menuPopup showFromBarButtonItem:menuItem animated:YES];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)sendStatusReport {
    NSString *statusReport = [[RootViewController currentView:nil].testRepository getStatusReportString];
    if (self.testEventController != nil  && [self.testEventController connectedToNetService]) {
        [self.testEventController sendReportMessage:statusReport withReportType:reportType_Status];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)sendListReport {
    NSString *listReport = [[RootViewController currentView:nil].testRepository getListReportString];
    if (self.testEventController != nil  && [self.testEventController connectedToNetService]) {
        [self.testEventController sendReportMessage:listReport withReportType:reportType_List];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)actionSheet:(UIActionSheet *)menuBarView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Change the navigation bar style, also make the status bar match with it
	switch (buttonIndex)
	{
		case 0:
		{
            UITextView * tv = self.outputTextView;
            tv.text = @"Log has been Reset!\n";
            [tv setText:[tv text]];
			break;
		}
		case 1:
		{
            // Exit Media Player
            if (self.activeCloakMediaPlayer != nil)
            {
				self.activeCloakMediaPlayer = nil;
				self.lastPosition = 0;
            }
			break;
		}
		case 2:
		{
            [self sendStatusReport];
			break;
		}
		case 3:
		{
            [self sendListReport];
			break;
		}
        default:
        {
#ifdef MARKETING_DEMO
            if (self->_switchDemoModeMenuIndex >= 0 && buttonIndex == self->_switchDemoModeMenuIndex) {
                [self switchToDemoMode];
            }
#endif            
            break;
        }
	}
	[self->_menuPopup release];
    self->_menuPopup = nil;
}

#ifdef MARKETING_DEMO

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) switchToDemoMode {
    [self hideRootView];
    // Remove its own UISplitViewController from the window and add it again. It will swap 
    // the split view controllers in the window pushing the Demo split view controller on the 
    // first place. Unhide the Demo split view controller and hide its own Test split view.
    // This process makes the Demo split view controller as a primary controller and
    // the Test split view controller becomes the secondary one.
    // Set the Demo root view controller as the current root.
    [self.splitViewController.view removeFromSuperview];
    [self.window addSubview:self.splitViewController.view];
    self.splitViewController.view.hidden = YES;
    self.demoDetailViewController.splitViewController.view.hidden = NO;
	[RootViewController currentView:demoDetailViewController.rootViewController];
}

#endif

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)viewDidLoad {
    
    [super viewDidLoad];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)viewDidUnload
{
    [super viewDidUnload];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)dealloc
{
    [bottomToolbar release];
    
    [super dealloc];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)showNetServiceConnected:(NSString *)netServiceName {
    if (netServiceName != nil) {
        netServiceLabel.text = [NSString stringWithFormat:@"Connected to %@\n", netServiceName];
    }
    else {
        netServiceLabel.text = @"Not connected to any services";
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"TestDetailViewController::viewWillAppear");
    [super viewWillAppear:animated];
}


/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"TestDetailViewController::viewDidAppear");
    [super viewDidAppear:animated];

    if (self.showContentPopover && self.popoverController != nil && !self.popoverController.popoverVisible) {
        [self.popoverController presentPopoverFromBarButtonItem:self.popoverButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
        self.showContentPopover = NO;
    }
}

@end

