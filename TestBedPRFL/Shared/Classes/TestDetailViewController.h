//
//  TestDetailViewController.h
//  ActiveCloak
//
//  Created by Apple User on 2/26/11.
//  Copyright 2011 Irdeto. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActiveCloakMediaPlayer.h"
#import "NetServiceController.h"
#import "TestEventController.h"
#import "DetailViewController.h"


@interface TestDetailViewController : DetailViewController
{
    IBOutlet UILabel *netServiceLabel;
    
#ifdef MARKETING_DEMO
    DetailViewController *demoDetailViewController;  // reference to DemoDetailViewController
#endif
@private
    NSInteger _switchDemoModeMenuIndex;
    UIActionSheet *_menuPopup;
}

- (id) init;

- (IBAction) showHideMediaPlayerSegmentAction:(id)sender;
- (IBAction) showAboutDialog:(id)sender;
- (IBAction) showMenu:(id)sender;
- (void) onMediaPlayerActivated:(BOOL)activated;

@property (nonatomic, retain) IBOutlet UIToolbar *bottomToolbar;
@property (nonatomic, retain) IBOutlet UISegmentedControl *showHideMediaPlayerItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *menuItem;
#ifdef MARKETING_DEMO
@property (nonatomic, retain) DetailViewController *demoDetailViewController;
#endif

@end

