//
//  SolutionTests.m
//  TestBed
//
//  Created by Apple User on 12/1/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#import "ProvisionController.h"
#import "SolutionTests.h"
#import "DetailViewController.h"
#import "ActiveCloakMediaPlayer.h"
#import "ActiveCloakAgent.h"
#import "RootViewController.h"
#import "objc/message.h"

#import <CFNetwork/CFNetwork.h>
#import <netinet/in.h>
#import <netdb.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <net/ethernet.h>
#import <net/if_dl.h>

//#define PRE_VIDEO_JB_DETECTION 

// currently selected test URL
static const char *g_pCurrentTestUrl = NULL;

// currently selected URL type
static unsigned int g_CurrentUrlType = 0;

// currently selected license acquisition URL override (or NULL if you need to use the one in the content)
static const char *g_pCurrentUrlOverride = NULL;

static const char *g_CurrentCustomData = NULL;


static char g_downloadManagerURL[1000] = {0};

#ifdef MARKETING_DEMO
void changeBitRateBar(uint32_t bitRate);
#endif

// macro that defines a new test function for a choice of 
// parameters. Use this macro to add new test URLs as they become available.
#define TESTURLCHOICE(index, desc, url, laurl, urltype) TESTURLCHOICENAME(index, desc, "Play URL " #index, url, laurl, urltype)

#define TESTURLCHOICENAME(index, desc, name, url, laurl, urltype) \
MANUAL_TEST_START_EXT(SetTestUrl##index, name, desc, -1, TestFlag_Empty, "More URLs", "Content.png") \
{ \
    TestLog("\"%s\"\n", desc);\
    if (laurl)\
    {\
        TestLog("Overriding default License Acquisition URL: %s\n", laurl);\
    }\
    g_pCurrentUrlOverride = laurl;\
    /* set the URL type option based on the type of URL this is */ \
    g_CurrentUrlType = urltype; \
    TestLog("Selecting test URL %s for subsequent tests\n", url);\
    g_pCurrentTestUrl = url;\
    [self playCurrentlySelectedVideoInView:view];\
} \
TEST_END


// Override URL for license server
#define LICENSEURLOVERRIDE	NULL

// The next two function is used for testing ActiveCloak abuse detection.
// The 'CountZeros' functions is a placeholder for a "hack injection".
// The 'CountOnes' functions is needed to calculate size of the abuse.
int CountOnes(const unsigned long number);

int CountZeros(const unsigned long number)
{
    return sizeof(unsigned long)*8 - CountOnes(number);
}

int CountOnes(const unsigned long number)
{
    int count = 0;
    unsigned long int nmb = number;
    while (nmb != 0) {
        nmb &= nmb^(~nmb + 1);
        count++;
    }
    return count;
}

void dumpMemoryToLog(void *memory, long size)
{
#define BUFFER_SIZE 4096
    char dump[BUFFER_SIZE + 1];
    char *buffer = dump;
    int length = BUFFER_SIZE;
    int printed = 0;
    void *pointer = memory;
    long counter = size;
    unsigned char byte = 0;
    
    while (counter > 0 && length > 0) {
        byte = *(unsigned char *)pointer;
        printed = snprintf(buffer, length, "%02x ", byte);
        buffer += printed;
        length -= printed;
        counter--;
        pointer++;
    }
    
    TestLog(dump);
}

static char CharForCurrentThread(void)
// Returns 'M' if we're running on the main thread, or 'S' otherwies.
{
    return [NSThread isMainThread] ? 'M' : 'S';
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
const char *getUrlTypeName(NSUInteger urlType)
{
    return urlType == ACURLTypeHLS ? "ACURLTypeHLS" 
    : urlType == ACURLTypeIIS ? "ACURLTypeIIS" 
    : urlType == ACURLTypeEnvelope ? "ACURLTypeEnvelope" 
    : urlType == ACURLTypePassThrough ? "ACURLTypePassThrough" 
    : "ACURLType_UNKNOWN";
}

@interface SolutionTests ()

-(void)removeMediaPlayerObservers;
-(void)setMediaPlayerNotificationObservers:(id)anObject;
-(void)setContentManagerNotificationObservers:(id)anObject;
-(id)runPlayVideoUnitTestWithId:(NSString *)testId
                 usingOperation:(OperationId)operation
                      underView:(DetailViewController*)view
                    withEntryId:(NSString *)entryId
                      inSection:(NSString *)parentSectionName;
-(id)runPlayLocalVideoUnitTestWithId:(NSString *)testId
                      usingOperation:(OperationId)operation
                           underView:(DetailViewController*)view
                         withEntryId:(NSString *)entryId
                           inSection:(NSString *)parentSectionName;
-(id)runDeleteLocalVideoUnitTestWithId:(NSString *)testId
                        usingOperation:(OperationId)operation
                             underView:(DetailViewController*)view
                           withEntryId:(NSString *)entryId
                             inSection:(NSString *)parentSectionName;
-(id)runDownloadVideoUnitTestWithId:(NSString *)testId
                     usingOperation:(OperationId)operation
                          underView:(DetailViewController*)view
                        withEntryId:(NSString *)entryId
                          inSection:(NSString *)parentSectionName;
-(id)runDownloadVideoUsingContentManagerUnitTestWithId:(NSString *)testId
                     usingOperation:(OperationId)operation
                          underView:(DetailViewController*)view
                        withEntryId:(NSString *)entryId
                          inSection:(NSString *)parentSectionName;
@end


///////////////////////////////////////////////////////////////////////////////
// SolutionTests class implementation
@implementation SolutionTests

@synthesize testViewController = __testViewController;
@synthesize attackHasBeenAlreadyDetected = __attackHasBeenAlreadyDetected;
@synthesize jailbreakHasBeenAlreadyDetected = __jailbreakHasBeenAlreadyDetected;
@synthesize webview = __webview;
@synthesize downloadLocation = __downloadLocation;
@synthesize customDownloadBitrate = __customDownloadBitrate;
@synthesize atomFeedsDataCollection = __atomFeedsDataCollection;
@synthesize jailbreakIcon = __jailbreakIcon;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id)initWithLogger:(id<TestLog>)testLogger andParentTestGroup:(TestGroup *)testGroup {
    [super initWithLogger:testLogger andParentTestGroup:testGroup];
    self.attackHasBeenAlreadyDetected = NO;
    self.jailbreakHasBeenAlreadyDetected = NO;
    self.customDownloadBitrate = ACBitrate_Max; /* Highest available bitrate, by default */
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)dealloc {
    self.testViewController = nil;
    self.webview = nil;
    self.downloadLocation = nil;
    self.atomFeedsDataCollection = nil;
    self.jailbreakIcon = nil;
    
    
    [super dealloc];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) forceStop
{

    [self.testViewController.activeCloakMediaPlayer pause];
    [self.testViewController.activeCloakMediaPlayer stop];
        
    [self.testViewController.activeCloakMediaPlayer.view removeFromSuperview];
    [self.testViewController.activeCloakMediaPlayer autorelease];

}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) handleSecurityAbuseDetection {
    
    self.attackHasBeenAlreadyDetected = YES;
    
    // stop the video if it is active
    if (self.testViewController != nil && self.testViewController.activeCloakMediaPlayer != nil) {
        [self forceStop];
        
        // post the playback finished notification so that the stream can be closed from Tests.m
        [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerPlaybackDidFinishNotification object:self.testViewController.activeCloakMediaPlayer];
        TestLog("Turn Off video because the attack was detectded.\n");
    }
    TestLog("Show a dialog about abuse detection.\n");
    [self showSecurityAlertDialog];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) handleSecurityJailbreakDetection {
    
    self.jailbreakHasBeenAlreadyDetected = YES;
    
    // stop the video if it is active
    if (self.testViewController != nil && self.testViewController.activeCloakMediaPlayer != nil) {
        [self forceStop];
        
        // post the playback finished notification so that the stream can be closed from Tests.m
        [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerPlaybackDidFinishNotification object:self.testViewController.activeCloakMediaPlayer];
        TestLog("Turn Off video because jailbreak was detectded.\n");
    }
    TestLog("Show a dialog about jailbreak detection.\n");
    [self showSecurityAlertDialog];
}

/*-----------------------------------------------------------------------------
 
  ----------------------------------------------------------------------------*/
 
- (void) showJailbreakIcon {

    if (self.testViewController != nil) {
        if (self.jailbreakIcon == nil) {
            self.jailbreakIcon = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
            UIImage *jb_image = [[UIImage imageNamed:@"Attack.png"] stretchableImageWithLeftCapWidth:12.0f topCapHeight:0.0f];
            [self.jailbreakIcon setBackgroundImage:jb_image forState:UIControlStateNormal];
            [self.jailbreakIcon setBackgroundImage:jb_image forState:UIControlStateHighlighted];
            self.jailbreakIcon.frame = CGRectMake(625.0, 50.0, 75.0, 75.0);
            [self.jailbreakIcon addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
        }

        [self.testViewController.view addSubview:self.jailbreakIcon];
    }
}

- (void) buttonAction
{
    //handle jailbreak icon click
}

- (void) hideJailbreakIcon {
    
    if (self.testViewController != nil) {
        [self.jailbreakIcon removeFromSuperview];
        [self.jailbreakIcon release];
        self.jailbreakIcon = nil;
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)showSecurityAlertDialog {
    NSString *message = @"ActiveCloak\u2122 Media Agent has detected a security breach within the media player application. The media player function has been disabled.\nContact your content provider for more information.";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Security Alert" message:message
                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];	
    [alert release];
}

/*-----------------------------------------------------------------------------
    Called when a button is clicked. The view will be automatically dismissed
    after this call returns
 ----------------------------------------------------------------------------*/
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
}

/*-----------------------------------------------------------------------------
    Called when we cancel a view (eg. the user clicks the Home button). 
    This is not called when the user clicks the cancel button.
    If not defined in the delegate, we simulate a click in the cancel button
 ----------------------------------------------------------------------------*/
- (void)alertViewCancel:(UIAlertView *)alertView {
}


/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)ensureActiveCloakAgent:(DetailViewController *)view {
    // if we are already in the main thread, do the work
    if ([NSThread isMainThread])
    {
        if (self.testViewController == nil)
        {
            self.testViewController = view;
        }
        if (self.testViewController.activeCloakAgent == nil)
        {
            self.testViewController.activeCloakAgent = [ActiveCloakAgent getAgent:self];
        }
    }
    // otherwise, invoke ourselves but in the main thread
    else
    {
        [self performSelectorOnMainThread:@selector(ensureActiveCloakAgent:) withObject:view waitUntilDone:YES];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)ensureActiveCloakMediaPlayer:(DetailViewController *)view
{
    // if we are already in the main thread, do the work
    if ([NSThread isMainThread])
    {
        // make sure we have an agent 
        [self ensureActiveCloakAgent:view]; 
        
        if (self.testViewController.activeCloakMediaPlayer == nil) 
        {
            // allocate and init the player
            self.testViewController.activeCloakMediaPlayer = [[[ActiveCloakMediaPlayer alloc] initWithActiveCloakAgent:self.testViewController.activeCloakAgent] autorelease]; 
            
            // set the delegate to ourself, for callback methods like sendUrlRequest, etc.
            self.testViewController.activeCloakMediaPlayer.delegate = self;
            
            // set the accessibility information for automation purposes
            self.testViewController.activeCloakMediaPlayer.isAccessibilityElement = YES;
			self.testViewController.activeCloakMediaPlayer.accessibilityLabel = @"MediaPlayer";
            
            // set the control style so it shows up in the right place in all versions of IOS
            self.testViewController.activeCloakMediaPlayer.controlStyle = MPMovieControlStyleEmbedded;
		}
        
    }    
    // otherwise, invoke ourselves but in the main thread
    else
    {
        [self  performSelectorOnMainThread:@selector(ensureActiveCloakMediaPlayer:) withObject:view waitUntilDone:YES];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)ensureActiveCloakContentManager:(DetailViewController *)view 
{
    // if we are already in the main thread, do the work
    if ([NSThread isMainThread])
    {
        // make sure we have an agent 
        [self ensureActiveCloakAgent:view]; 
        
        if (self.testViewController.activeCloakContentManager == nil) 
        {
            // allocate and init the content manager
            self.testViewController.activeCloakContentManager = [[ActiveCloakContentManager alloc] initWithActiveCloakAgent:self.testViewController.activeCloakAgent]; 
            
            // set observer up for event notifications from this object            
            [self setContentManagerNotificationObservers:self.testViewController.activeCloakContentManager];
            
            // set the delegate to ourself, for callback methods like sendUrlRequest, etc.
            self.testViewController.activeCloakContentManager.delegate = self;

            // start the 'downloader', which should resume any pending downloads
            [self.testViewController.activeCloakContentManager startDownloader:[self getDownloadStorageLocation]];
            
            // log what we are doing to the screen
            [self Log:[NSString stringWithFormat:@"Content manager created, pointed at %@\n", [self getDownloadStorageLocation]]];

        } 
    }    
    // otherwise, invoke ourselves but in the main thread
    else
    {
        [self  performSelectorOnMainThread:@selector(ensureActiveCloakContentManager:) withObject:view waitUntilDone:YES];
    }
}


// TODO: Add comments
- (void) sendUrlRequest:(NSString *)url contentType:(NSString *)contentType data:(NSData *)data  
{
    TestLog("Passing along send URL request\n");

    if (g_pCurrentUrlOverride)
    {
        url = [NSString stringWithCString: g_pCurrentUrlOverride 
                                 encoding:NSUTF8StringEncoding];
    }
    TestLog("Have URL: %s\n", [url cStringUsingEncoding:NSUTF8StringEncoding]);
    [self.testViewController.activeCloakAgent defaultSendUrlRequest:url contentType:contentType data:data];
}

- (void) deviceIDChanged:(NSString*)newDeviceID withPreviousDeviceID:(NSString*)previousDeviceID
{
    [self Log:[NSString stringWithFormat:@"Device ID change detected.\nNew Device ID: %@\nPrevious Device ID: %@\n", newDeviceID, previousDeviceID]];
    
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
//  Notification called when various events occur, for ActiveCloakMediaPlayer
- (void) handleMoviePlayerNotification:(NSNotification*)notification
{
    fprintf(stderr, "handleMoviePlayerNotification: notification.name = %s\n",
            [[notification name] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if ([[notification name] isEqualToString:MPMoviePlayerScalingModeDidChangeNotification]) {
    }
    else if ([[notification name] isEqualToString:MPMoviePlayerPlaybackDidFinishNotification]) {
        [self playerEndedCallback:notification];
    }
    else if ([[notification name] isEqualToString:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey]) {
        [self playerEndedCallback:notification];
    }
    else if ([[notification name] isEqualToString:MPMoviePlayerPlaybackStateDidChangeNotification]) {
    }
    else if ([[notification name] isEqualToString:MPMoviePlayerLoadStateDidChangeNotification]) {
    }
    else if ([[notification name] isEqualToString:MPMoviePlayerNowPlayingMovieDidChangeNotification]) {
    }
    else if ([[notification name] isEqualToString:MPMoviePlayerWillEnterFullscreenNotification]) {
    }
    else if ([[notification name] isEqualToString:MPMoviePlayerDidEnterFullscreenNotification]) {
    }
    else if ([[notification name] isEqualToString:MPMoviePlayerWillExitFullscreenNotification]) {
    }
    else if ([[notification name] isEqualToString:MPMoviePlayerDidExitFullscreenNotification]) {
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPAbuseDetected]) {
        TestLog("Notification: NOTIF_ACMPAbuseDetected\n");
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPBitrateChanged]) {
        TestLog("Notification: NOTIF_ACMPBitrateChanged\n");
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPDRMStateChanged]) {
        TestLog("Notification: NOTIF_ACMPDRMStateChanged\n");
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPInternalError]) {
       NSNumber *num = [[notification userInfo] objectForKey:@"Error"];
        NSNumber *result1 = [[notification userInfo] objectForKey:@"Result1"];
        NSNumber *result2 = [[notification userInfo] objectForKey:@"Result2"];
        NSNumber *result3 = [[notification userInfo] objectForKey:@"Result3"];
        NSString *str = [[notification userInfo] objectForKey:@"String"];
        TestLog("Notification: NOTIF_ACMPInternalError 0x%08X 0x%08X 0x%08X 0x%08X %s\n", 
                (int)([num intValue]),
                (int)([result1 intValue]),
                (int)([result2 intValue]),
                (int)([result3 intValue]),
                (char *)([str UTF8String])
                
                );
            
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPJailbreakDetected]) {
        TestLog("Notification: NOTIF_ACMPJailbreakDetected\n");
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPlaybackRestricted]) {
        TestLog("Notification: NOTIF_ACMPlaybackRestricted\n");
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPLicenseUpdated]) {
        TestLog("Notification: NOTIF_ACMPLicenseUpdated\n");
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPSecureclockUpdated]) {
        TestLog("Notification: NOTIF_ACMPSecureclockUpdated\n");
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPProvisioningRequired]) {
		ProvisionController *pCtrl = [ProvisionController getProvisionController: self.testViewController.activeCloakAgent];
		[pCtrl provision];
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPNetworkUnavailable]) {
        TestLog("Notification: NOTIF_ACMPNetworkUnavailable\n");
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPLicenseExpired]) {
        TestLog("Notification: NOTIF_ACMPLicenseExpired\n");
    }
    else {
        // unknown notification
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
//  Notification called when various events occur, for ActiveCloakContentManager
- (void) handleContentManagerNotification:(NSNotification*)notification
{
    fprintf(stderr, "handleContentManagerNotification: notification.name = %s\n",
            [[notification name] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if ([[notification name] isEqualToString:NOTIF_ACMPAbuseDetected]) {
        TestLog("Notification: NOTIF_ACMPAbuseDetected\n");
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPBitrateChanged]) {
        TestLog("Notification: NOTIF_ACMPBitrateChanged\n");
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPDRMStateChanged]) {
        TestLog("Notification: NOTIF_ACMPDRMStateChanged\n");
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPInternalError]) {
       NSNumber *num = [[notification userInfo] objectForKey:@"Error"];
        NSNumber *result1 = [[notification userInfo] objectForKey:@"Result1"];
        NSNumber *result2 = [[notification userInfo] objectForKey:@"Result2"];
        NSNumber *result3 = [[notification userInfo] objectForKey:@"Result3"];
        NSString *str = [[notification userInfo] objectForKey:@"String"];
        TestLog("Notification: NOTIF_ACMPInternalError 0x%08X 0x%08X 0x%08X 0x%08X %s\n", 
                (int)([num intValue]),
                (int)([result1 intValue]),
                (int)([result2 intValue]),
                (int)([result3 intValue]),
                (char *)([str UTF8String])
                
                );
            
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPJailbreakDetected]) {
        TestLog("Notification: NOTIF_ACMPJailbreakDetected\n");
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPLicenseUpdated]) {
        TestLog("Notification: NOTIF_ACMPLicenseUpdated\n");
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPSecureclockUpdated]) {
        TestLog("Notification: NOTIF_ACMPSecureclockUpdated\n");
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPProvisioningRequired]) {
        // If provisioning is required, we invoke the ActiveCloak provisioning process, outside
        // the scope of the API. 
		ProvisionController *pCtrl = [ProvisionController getProvisionController: self.testViewController.activeCloakAgent];
		[pCtrl provision];
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPNetworkUnavailable]) {
        TestLog("Notification: NOTIF_ACMPNetworkUnavailable\n");
    }
    else if ([[notification name] isEqualToString:NOTIF_ACMPLicenseExpired]) {
        TestLog("Notification: NOTIF_ACMPLicenseExpired\n");
    }
    else {
        // unknown notification
    }
}


// these are all the notifications we care about on the ActiveCloakMediaPlayer object
-(NSArray*)getAllMediaPlayerNotifications
{
    return [NSArray arrayWithObjects:
              MPMoviePlayerScalingModeDidChangeNotification,
              MPMoviePlayerPlaybackDidFinishNotification,
              MPMoviePlayerPlaybackDidFinishReasonUserInfoKey,
              MPMoviePlayerPlaybackStateDidChangeNotification,
              MPMoviePlayerLoadStateDidChangeNotification,
              MPMoviePlayerNowPlayingMovieDidChangeNotification,
              MPMoviePlayerWillEnterFullscreenNotification,
              MPMoviePlayerDidEnterFullscreenNotification,
              MPMoviePlayerWillExitFullscreenNotification,
              MPMoviePlayerDidExitFullscreenNotification,
              NOTIF_ACMPAbuseDetected,
              NOTIF_ACMPBitrateChanged,
              NOTIF_ACMPDRMStateChanged,
              NOTIF_ACMPInternalError,
              NOTIF_ACMPJailbreakDetected,
              NOTIF_ACMPlaybackRestricted,
              NOTIF_ACMPLicenseUpdated,
              NOTIF_ACMPSecureclockUpdated,
              NOTIF_ACMPProvisioningRequired,
              NOTIF_ACMPNetworkUnavailable,
              NOTIF_ACMPLicenseExpired,
              nil];
}

// these are all the notifications that can be raised on the ActiveCloakContentManager object. 
-(NSArray*)getAllContentManagerNotifications
{
    return [NSArray arrayWithObjects:
              NOTIF_ACMPAbuseDetected,
              NOTIF_ACMPBitrateChanged,
              NOTIF_ACMPDRMStateChanged,
              NOTIF_ACMPInternalError,
              NOTIF_ACMPJailbreakDetected,
              NOTIF_ACMPLicenseUpdated,
              NOTIF_ACMPSecureclockUpdated,
              NOTIF_ACMPProvisioningRequired,
              NOTIF_ACMPNetworkUnavailable,
              NOTIF_ACMPLicenseExpired,
              nil];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(void) setContentManagerNotificationObservers:(id)anObject {
    // Register to receive a notification when the movie scaling mode has changed. 
    
    fprintf(stderr, "setContentManagerNotificationObservers:\n");
    
    for (NSString * notif in [self getAllContentManagerNotifications])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(handleContentManagerNotification:) 
                                                     name:notif 
                                                   object:anObject];
    }
}



/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(void) setMediaPlayerNotificationObservers:(id)anObject {
    // Register to receive a notification when the movie scaling mode has changed. 
    
    fprintf(stderr, "setMediaPlayerNotificationObservers:\n");
    
    for (NSString * notif in [self getAllMediaPlayerNotifications])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(handleMoviePlayerNotification:) 
                                                     name:notif 
                                                   object:anObject];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(void)removeMediaPlayerObservers {
    fprintf(stderr, "removeMediaPlayerObservers:\n");

    for (NSString * notif in [self getAllMediaPlayerNotifications])
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:notif
                                                      object:self.testViewController.activeCloakMediaPlayer];
    }
}


/*-----------------------------------------------------------------------------
    playMovieInWebView   
    
    This is a helper functions to test UIWebView player.
    This functions should be called only in the Main Thread because 
    it shows UI.
 ----------------------------------------------------------------------------*/
- (void) playMovieInWebView:(NSString*)urlString {
    NSURL * url = [NSURL URLWithString:urlString];
    
    self.webview = [[[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webview loadRequest:request];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSObject*) playerEndedCallback:(NSNotification*)notification
{
    if (notification != nil)
    {
        [RootViewController addLog:@"Player finished "];
        DetailViewController *view = [RootViewController currentView:nil].detailViewController;
        NSNumber *code = [notification.userInfo valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
        if ([code intValue] == MPMovieFinishReasonPlaybackError) 
        {
            [RootViewController addLog:@"with error.\n"];
        }
        else
        {
            [RootViewController addLog:[NSString stringWithFormat:@"normally. code = %08x\n", [code intValue]]];
        }
        
        if (view != nil && self.testViewController.activeCloakMediaPlayer != nil) 
        {
            NSTimeInterval duration =self.testViewController.activeCloakMediaPlayer.duration;
            NSTimeInterval curTime =self.testViewController.activeCloakMediaPlayer.currentPlaybackTime;
            if (curTime >= 2.0)
            {
                view.lastPosition = curTime;
            }
            
            if ([code intValue] != MPMovieFinishReasonUserExited // don't reconnect if we exited
                && (isnan(duration) // reconnect if we are a live stream
                    || duration == 0 // reconnect if we otherwise don't know the duration
                    || (duration > 5.0 && view.lastPosition < duration - 5.0) // don't reconnect if we are within 5 seconds of the end of the stream
                    )
                )
            {
                // the player might give us this event even though it isn't done, because it detected a
                // lapse in network connectivity. To work around it, we force the player to reconnect to
                // the local URL. 
                // need to tell the CWS handle not to block players by saying 'force reconnect'
                [self.testViewController.activeCloakMediaPlayer forceReconnect:view.lastPosition]; 
            }
            else
            {
                // every other case is a request to close the media player: video actually finished, or user clicked 'Done'
                [self removeMediaPlayerObservers];
               self.testViewController.activeCloakMediaPlayer = nil;
                view.lastPosition = 0;
            }
        }
        
    }
    return nil;
}



/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) playVideoInView:(DetailViewController*)view withUrl:(NSURL *)url ofType:(ACURLType)urlType withCustomData:(NSString *)customData
{
    BOOL success = YES;

    // make sure our view controller is current
    self.testViewController = view; 
    
    // remove any observers we have so we don't get ghost notifications while we are shutting down
    [self removeMediaPlayerObservers];
    
    // stop the player on the main thread first        
    if (self.testViewController.activeCloakMediaPlayer != nil) 
    {
        [self.testViewController.activeCloakMediaPlayer performSelectorOnMainThread:@selector(stop) withObject:nil waitUntilDone:YES];
    }
    
    // ensure player exists
    [self ensureActiveCloakMediaPlayer:view]; 
    
    // add observers to the player for events
    [self setMediaPlayerNotificationObservers:self.testViewController.activeCloakMediaPlayer]; 

    // open the url in the player        
    [self.testViewController.activeCloakMediaPlayer openURL:url ofType:urlType withCustomData:customData];
    
    return success;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) playCurrentlySelectedVideoInView:(DetailViewController*)view {
    BOOL success = YES;

    if (g_pCurrentTestUrl == nil)
    {
        TestLog("No URL has been selected!\n");
        success = NO;
    }
    else
    {
        [self playVideoInView:view
            withUrl:[NSURL URLWithString:[NSString stringWithCString:g_pCurrentTestUrl encoding:NSUTF8StringEncoding]]
            ofType:g_CurrentUrlType
               withCustomData:g_CurrentCustomData ? [NSString stringWithCString:g_CurrentCustomData encoding:NSUTF8StringEncoding] : nil];
    }

    return success;
}

/*-----------------------------------------------------------------------------
    performTestOperation:againstEntryWithId:selectedFrom:withMethodSelector:andSectionName:inView:
 
    This is body of a dynamic test case that plays video with Media Player
    using URL from an atom syndication file downloaded from a server.
    It selects an entry from Atom Feeds Data Collection using the testId 
    passed as a parameter and performs a test operation according to the 
    operation code 'operation' passed as a parameter.
    If 'opid_runTest' operation code sent, the function will play a video 
    in the view using CWSMoviePlayerController.
 ----------------------------------------------------------------------------*/
-(id)performTestOperation:(OperationId)operation
               withTestId:(NSString *)testId
                 testName:(NSString *)testName
       againstEntryWithId:(NSString *)entryId
             selectedFrom:(NSDictionary *)atomFeedsDataList
       withMethodSelector:(SEL)functionSelector
           andSectionName:(NSString *)parentSectionName     
                   inView:(DetailViewController*)view {
    id __result = nil; 
    TestFlags __testFlags = TestFlag_DemoTest; 
    
    NSDictionary *entries = nil;
    EntryRecord *entryRecord = nil;
    AtomFeedsData *atomFeedsData = nil;
    NSEnumerator *atomFeedsEnumerator = [atomFeedsDataList objectEnumerator];
    
    while ((atomFeedsData = (AtomFeedsData *)[atomFeedsEnumerator nextObject])) {
        entries = atomFeedsData.entryRecordList;
        
        if (entries != nil) {
            entryRecord = [entries objectForKey:entryId];
        }
        
        if (entryRecord != nil) {
            break;
        }
    }
    
    if (entryRecord == nil) {
        operation = opid_None;
    }
    
    switch (operation) {
        default:
        case opid_None:
            __result = [NSNumber numberWithBool:NO]; 
            break; 
        case opid_getName: 
            __result = testName != nil ? testName : entryRecord.title;
            break;
        case opid_getDescription:
            __result = entryRecord.summary;
            break;
        case opid_getTestType:
            __result = [NSNumber numberWithShort:TestType_Manual];
            break;
        case opid_getTestFlags:
            if (entryRecord.imageUrl != nil) {
                __testFlags |= TestFlag_IconNeedsToBeDownloaded;
            }
            __result = [NSNumber numberWithUnsignedLong:__testFlags];
            break;
        case opid_getSerialNumber:
            __result = [NSNumber numberWithInteger:entryRecord.serialNumber];
            break;
        case opid_getTestSection:
            __result = parentSectionName;
            break;
        case opid_getTestIcon:
            __result = entryRecord.imageUrl;
            break;
        case opid_runTest:
            __result = objc_msgSend(self, functionSelector, entryRecord, entryId, testId, view); 
            break; 
    }
    
    return __result;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)runPlayVideoUnitTestWithId:(NSString *)testId
                 usingOperation:(OperationId)operation
                      underView:(DetailViewController*)view
                    withEntryId:(NSString *)entryId
                      inSection:(NSString *)parentSectionName { 
    
    return [self performTestOperation:operation
                           withTestId:testId
                             testName:nil
                   againstEntryWithId:entryId
                         selectedFrom:self.atomFeedsDataCollection
                   withMethodSelector:@selector(playVideoForEntry:withEntryId:andTestId:inView:)
                       andSectionName:parentSectionName     
                               inView:view];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)runPlayLocalVideoUnitTestWithId:(NSString *)testId
                      usingOperation:(OperationId)operation
                           underView:(DetailViewController*)view
                         withEntryId:(NSString *)entryId
                           inSection:(NSString *)parentSectionName { 
    
    return [self performTestOperation:operation
                           withTestId:testId
                             testName:nil
                   againstEntryWithId:entryId
                         selectedFrom:self.atomFeedsDataCollection
                   withMethodSelector:@selector(playLocalVideoForEntry:withEntryId:andTestId:inView:)
                       andSectionName:parentSectionName     
                               inView:view];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)runDeleteLocalVideoUnitTestWithId:(NSString *)testId
                        usingOperation:(OperationId)operation
                             underView:(DetailViewController*)view
                           withEntryId:(NSString *)entryId
                             inSection:(NSString *)parentSectionName { 
    
    return [self performTestOperation:operation
                           withTestId:testId
                             testName:nil
                   againstEntryWithId:entryId
                         selectedFrom:self.atomFeedsDataCollection
                   withMethodSelector:@selector(deleteLocalVideoForEntry:withEntryId:andTestId:inView:)
                       andSectionName:parentSectionName     
                               inView:view];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)runDownloadVideoUnitTestWithId:(NSString *)testId
                 usingOperation:(OperationId)operation
                      underView:(DetailViewController*)view
                    withEntryId:(NSString *)entryId
                      inSection:(NSString *)parentSectionName { 
    
    return [self performTestOperation:operation
                           withTestId:testId
                             testName:nil
                   againstEntryWithId:entryId
                         selectedFrom:self.atomFeedsDataCollection
                   withMethodSelector:@selector(downloadVideoForEntry:withEntryId:andTestId:inView:)
                       andSectionName:parentSectionName     
                               inView:view];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)runProgressiveDownloadVideoUnitTestWithId:(NSString *)testId
                                usingOperation:(OperationId)operation
                                     underView:(DetailViewController*)view
                                   withEntryId:(NSString *)entryId
                                     inSection:(NSString *)parentSectionName { 
    
    return [self performTestOperation:operation
                           withTestId:testId
                             testName:nil
                   againstEntryWithId:entryId
                         selectedFrom:self.atomFeedsDataCollection
                   withMethodSelector:@selector(downloadAndProgressivelyPlayVideoForEntry:withEntryId:andTestId:inView:)
                       andSectionName:parentSectionName     
                               inView:view];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)playVideoForEntry:(EntryRecord *)entryRecord withEntryId:(NSString *)entryId andTestId:(NSString *)testId inView:(DetailViewController *)view {
    
    BOOL success = YES;
    
    TestLog("Started test for id %s\n", [entryId cStringUsingEncoding:NSUTF8StringEncoding]);
    TestLog("Using URL = %s\n", [entryRecord.link cStringUsingEncoding:NSUTF8StringEncoding]);
    TestLog("URL type = %s\n", getUrlTypeName(entryRecord.urltype));
    TestLog("\"%s\"\n", entryRecord.summary == nil ? "No summary" : [entryRecord.summary cStringUsingEncoding:NSUTF8StringEncoding]);

    if (entryRecord.licenseAcquisitionUrl != nil)
    {
        g_pCurrentUrlOverride = [entryRecord.licenseAcquisitionUrl cStringUsingEncoding:NSUTF8StringEncoding];
        TestLog("Overriding default License Acquisition URL: %s\n", g_pCurrentUrlOverride);
    }
    
    /* set the URL type option based on the type of URL this is */ 
    g_CurrentUrlType = entryRecord.urltype;
    g_pCurrentTestUrl = [entryRecord.link cStringUsingEncoding:NSUTF8StringEncoding];
    TestLog("Selecting test URL %s for subsequent tests\n", g_pCurrentTestUrl);
    
    success = [self playCurrentlySelectedVideoInView:view];
    
    return [NSNumber numberWithBool:success]; 
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)playLocalVideoForEntry:(EntryRecord *)entryRecord withEntryId:(NSString *)entryId andTestId:(NSString *)testId inView:(DetailViewController *)view {
    
    BOOL success = YES;
    
    NSArray *writablePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [writablePaths lastObject];
    NSString *localFile = [documentsPath stringByAppendingPathComponent:entryRecord.downloadToFile];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:localFile]) {
        NSString *fileProtocol = @"file://";
        NSString *localFileUrl = [fileProtocol stringByAppendingString:localFile];
        TestLog("Started test for id %s\n", [entryId cStringUsingEncoding:NSUTF8StringEncoding]);
        TestLog("Using URL = %s\n", [localFileUrl cStringUsingEncoding:NSUTF8StringEncoding]);
        TestLog("URL type = %s\n", getUrlTypeName(entryRecord.urltype));
        TestLog("\"%s\"\n", entryRecord.summary == nil ? "No summary" : [entryRecord.summary cStringUsingEncoding:NSUTF8StringEncoding]);
        
        if (entryRecord.licenseAcquisitionUrl != nil)
        {
            g_pCurrentUrlOverride = [entryRecord.licenseAcquisitionUrl cStringUsingEncoding:NSUTF8StringEncoding];
            TestLog("Overriding default License Acquisition URL: %s\n", g_pCurrentUrlOverride);
        }
        
        /* set the URL type option based on the type of URL this is */ 
        g_CurrentUrlType = entryRecord.urltype;
        g_pCurrentTestUrl = [localFileUrl cStringUsingEncoding:NSUTF8StringEncoding];
        TestLog("Selecting test URL %s for subsequent tests\n", g_pCurrentTestUrl);
        
        success = [self playCurrentlySelectedVideoInView:view];
    }
    else {
        TestLog("The %s file does not exist. Abort the test.\n", [localFile cStringUsingEncoding:NSUTF8StringEncoding]);
        success = NO;
    }

    
    return [NSNumber numberWithBool:success]; 
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)deleteLocalVideoForEntry:(EntryRecord *)entryRecord withEntryId:(NSString *)entryId andTestId:(NSString *)testId inView:(DetailViewController *)view {
    
    BOOL success = YES;
    
    NSString *documentsPath = [self getDownloadStorageLocation];
    NSString *localFile = [documentsPath stringByAppendingPathComponent:entryRecord.downloadToFile];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:localFile]) {
        NSError *errorHandle = nil;
        if ([[NSFileManager defaultManager] removeItemAtPath:localFile error:&errorHandle] != YES) {
            TestLog("ERROR: failed to delete file %s, error = %s\n",
                    [localFile cStringUsingEncoding:NSUTF8StringEncoding],
                    [[errorHandle localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        else {
            TestLog("The %s file was successfully deleted.\n", [localFile cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        
    }
    else {
        TestLog("The %s file does not exist. No need to delete it.\n", [localFile cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    
    
    return [NSNumber numberWithBool:success]; 
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)runDownloadVideoUsingContentManagerUnitTestWithId:(NSString *)testId
                                        usingOperation:(OperationId)operation
                                             underView:(DetailViewController*)view
                                           withEntryId:(NSString *)entryId
                                             inSection:(NSString *)parentSectionName { 
    
    self.testViewController = view;

    return [self performTestOperation:operation
                           withTestId:testId
                             testName:@"1. Download"
                   againstEntryWithId:entryId
                         selectedFrom:self.atomFeedsDataCollection
                   withMethodSelector:@selector(downloadVideoUsingContentManagerForEntry:withEntryId:andTestId:inView:)
                       andSectionName:parentSectionName     
                               inView:view];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(NSString*)getDownloadStorageLocation {

    if (self.downloadLocation == nil) {
        NSArray *writablePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.downloadLocation = [writablePaths lastObject];
    }
    
    return self.downloadLocation;
}


/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)downloadVideoUsingContentManagerForEntry:(EntryRecord *)entryRecord withEntryId:(NSString *)entryId andTestId:(NSString *)testId inView:(DetailViewController *)view {
    
    BOOL success = YES;
    
    TestLog("Started download an entry with id %s using ContentManager\n", [entryId cStringUsingEncoding:NSUTF8StringEncoding]);
    TestLog("Download frm URL = %s\n", [entryRecord.link cStringUsingEncoding:NSUTF8StringEncoding]);
    TestLog("URL type = %s\n", getUrlTypeName(entryRecord.urltype));
    if (entryRecord.urltype == ACURLTypeIIS) {
        TestLog("Download Bitrate type = %s (value = %d)\n", 
                self.customDownloadBitrate == ACBitrate_All ? "ACBitrate_All" :
                self.customDownloadBitrate == ACBitrate_Max ? "ACBitrate_Max" :
                self.customDownloadBitrate == ACBitrate_Min ? "ACBitrate_Min" : "Custom", self.customDownloadBitrate);
    }
    TestLog("Test ID = %s\n", [testId cStringUsingEncoding:NSUTF8StringEncoding]);
    TestLog("\"%s\"\n", entryRecord.summary == nil ? "No summary" : [entryRecord.summary cStringUsingEncoding:NSUTF8StringEncoding]);
    
    [self ensureActiveCloakContentManager:view];
    
    if (success && self.testViewController.activeCloakContentManager)
    {
        BOOL alreadyInQueue = NO;
        [self Log:@"Begining download queue\n"];
        
        const char* currentClassName = class_getName(self.class);
        NSString * cookie = [NSString stringWithFormat:@"%s,%@", currentClassName, testId];
        
        alreadyInQueue = ![self.testViewController.activeCloakContentManager queueDownload:[NSURL URLWithString:entryRecord.link]
                               ofType:entryRecord.urltype
                     withDestFilename:entryRecord.downloadToFile
                            ofBitrate:self.customDownloadBitrate
                           withCookie:cookie];
        
        if (alreadyInQueue) {
            
            NSString *documentsPath = [self getDownloadStorageLocation];
            NSString *localFile = [documentsPath stringByAppendingPathComponent:entryRecord.downloadToFile];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:localFile]) {
                [self Log:[NSString stringWithFormat:@"File %@ was not added to the download queue by ActiveCloakContentManager because it was already downloaded.\n", entryRecord.downloadToFile]];
            } else {
                [self Log:[NSString stringWithFormat:@"File %@ was not added to the download queue by ActiveCloakContentManager because the manager found the same file has been already added to the downloading queue.\n", entryRecord.downloadToFile]];
            }
        } else {
            [self Log:[NSString stringWithFormat:@"Downloading file %@, download will continue after test run.\n", entryRecord.link]];
        }
    }
    else 
    {
        [self Log:@"ACCM is not open!\n"];
    }
    
    return [NSNumber numberWithBool:success]; 
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)runPlayLocalVideoUsingContentManagerUnitTestWithId:(NSString *)testId
                                         usingOperation:(OperationId)operation
                                              underView:(DetailViewController*)view
                                            withEntryId:(NSString *)entryId
                                              inSection:(NSString *)parentSectionName { 
    
    self.testViewController = view;

    return [self performTestOperation:operation
                           withTestId:testId
                             testName:@"7. Play"
                   againstEntryWithId:entryId
                         selectedFrom:self.atomFeedsDataCollection
                   withMethodSelector:@selector(playLocalVideoUsingContentManagerForEntry:withEntryId:andTestId:inView:)
                       andSectionName:parentSectionName     
                               inView:view];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)playLocalVideoUsingContentManagerForEntry:(EntryRecord *)entryRecord withEntryId:(NSString *)entryId andTestId:(NSString *)testId inView:(DetailViewController *)view {
    
    return [self playLocalVideoForEntry:entryRecord withEntryId:entryId andTestId:testId inView:view];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)runPauseVideoDownloadUsingContentManagerUnitTestWithId:(NSString *)testId
                                         usingOperation:(OperationId)operation
                                              underView:(DetailViewController*)view
                                            withEntryId:(NSString *)entryId
                                              inSection:(NSString *)parentSectionName { 
    
    self.testViewController = view;

    return [self performTestOperation:operation
                           withTestId:testId
                             testName:@"2. Pause"
                   againstEntryWithId:entryId
                         selectedFrom:self.atomFeedsDataCollection
                   withMethodSelector:@selector(pauseVideoDownloadUsingContentManagerForEntry:withEntryId:andTestId:inView:)
                       andSectionName:parentSectionName     
                               inView:view];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)pauseVideoDownloadUsingContentManagerForEntry:(EntryRecord *)entryRecord withEntryId:(NSString *)entryId andTestId:(NSString *)testId inView:(DetailViewController *)view {
    
    BOOL success = YES;
    
    [self ensureActiveCloakContentManager:view];
    
    if (success && self.testViewController.activeCloakContentManager)
    {
        [self Log:[NSString stringWithFormat:@"Pause downloaded file \"%@\" in the queue\n", entryRecord.link]];
        
        [self.testViewController.activeCloakContentManager pauseDownload:[NSURL URLWithString:entryRecord.link]];
    }
    else 
    {
        [self Log:@"Error: ContentManager was not created!\n"];
    }
    
    return [NSNumber numberWithBool:success]; 
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)runResumeVideoDownloadUsingContentManagerUnitTestWithId:(NSString *)testId
                                                usingOperation:(OperationId)operation
                                                     underView:(DetailViewController*)view
                                                   withEntryId:(NSString *)entryId
                                                     inSection:(NSString *)parentSectionName { 
    
    self.testViewController = view;

    return [self performTestOperation:operation
                           withTestId:testId
                             testName:@"3. Resume"
                   againstEntryWithId:entryId
                         selectedFrom:self.atomFeedsDataCollection
                   withMethodSelector:@selector(resumeVideoDownloadUsingContentManagerForEntry:withEntryId:andTestId:inView:)
                       andSectionName:parentSectionName     
                               inView:view];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)resumeVideoDownloadUsingContentManagerForEntry:(EntryRecord *)entryRecord withEntryId:(NSString *)entryId andTestId:(NSString *)testId inView:(DetailViewController *)view {
    
    BOOL success = YES;
    
    [self ensureActiveCloakContentManager:view];
    
    if (success && self.testViewController.activeCloakContentManager)
    {
        [self Log:[NSString stringWithFormat:@"Resume downloaded file \"%@\" in the queue\n", entryRecord.link]];
        
        [self.testViewController.activeCloakContentManager resumeDownload:[NSURL URLWithString:entryRecord.link]];
    }
    else 
    {
        [self Log:@"Error: ContentManager was not created!\n"];
    }
    
    return [NSNumber numberWithBool:success]; 
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)runCancelVideoDownloadUsingContentManagerUnitTestWithId:(NSString *)testId
                                              usingOperation:(OperationId)operation
                                                   underView:(DetailViewController*)view
                                                 withEntryId:(NSString *)entryId
                                                   inSection:(NSString *)parentSectionName { 
    
    self.testViewController = view;

    return [self performTestOperation:operation
                           withTestId:testId
                             testName:@"4. Cancel"
                   againstEntryWithId:entryId
                         selectedFrom:self.atomFeedsDataCollection
                   withMethodSelector:@selector(cancelVideoDownloadUsingContentManagerForEntry:withEntryId:andTestId:inView:)
                       andSectionName:parentSectionName     
                               inView:view];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)cancelVideoDownloadUsingContentManagerForEntry:(EntryRecord *)entryRecord withEntryId:(NSString *)entryId andTestId:(NSString *)testId inView:(DetailViewController *)view {
    
    BOOL success = YES;
    
    [self ensureActiveCloakContentManager:view];
    
    if (success && self.testViewController.activeCloakContentManager)
    {
        [self Log:[NSString stringWithFormat:@"Cancel downloaded file \"%@\" in the queue\n", entryRecord.link]];
        
        [self.testViewController.activeCloakContentManager cancelDownload:[NSURL URLWithString:entryRecord.link]];
    }
    else 
    {
        [self Log:@"Error: ContentManager was not created!\n"];
    }
    
    return [NSNumber numberWithBool:success]; 
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)runDeleteDownloadedVideoUsingContentManagerUnitTestWithId:(NSString *)testId
                                                 usingOperation:(OperationId)operation
                                                      underView:(DetailViewController*)view
                                                    withEntryId:(NSString *)entryId
                                                      inSection:(NSString *)parentSectionName { 
    
    self.testViewController = view;

    return [self performTestOperation:operation
                           withTestId:testId
                             testName:@"5. Delete"
                   againstEntryWithId:entryId
                         selectedFrom:self.atomFeedsDataCollection
                   withMethodSelector:@selector(deleteDownloadedVideoUsingContentManagerForEntry:withEntryId:andTestId:inView:)
                       andSectionName:parentSectionName     
                               inView:view];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)deleteDownloadedVideoUsingContentManagerForEntry:(EntryRecord *)entryRecord withEntryId:(NSString *)entryId andTestId:(NSString *)testId inView:(DetailViewController *)view {
    
    return [self deleteLocalVideoForEntry:entryRecord withEntryId:entryId andTestId:testId inView:view];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)runAcquireLicenseForVideoUsingContentManagerUnitTestWithId:(NSString *)testId
                                                usingOperation:(OperationId)operation
                                                     underView:(DetailViewController*)view
                                                   withEntryId:(NSString *)entryId
                                                     inSection:(NSString *)parentSectionName { 
    
    self.testViewController = view;
    
    return [self performTestOperation:operation
                           withTestId:testId
                             testName:@"6. Acquire License"
                   againstEntryWithId:entryId
                         selectedFrom:self.atomFeedsDataCollection
                   withMethodSelector:@selector(acquireLicenseForVideoUsingContentManagerForEntry:withEntryId:andTestId:inView:)
                       andSectionName:parentSectionName     
                               inView:view];
}

/*-----------------------------------------------------------------------------
  
 ----------------------------------------------------------------------------*/
-(id)acquireLicenseForVideoUsingContentManagerForEntry:(EntryRecord *)entryRecord withEntryId:(NSString *)entryId andTestId:(NSString *)testId inView:(DetailViewController *)view {
    
    BOOL success = YES;

    self.testViewController = view; 
    
    /* Close the player first. A license cannot be acquired while content is playing */
    
    [self removeMediaPlayerObservers];
    if (self.testViewController.activeCloakMediaPlayer != nil) 
    {
        [self.testViewController.activeCloakMediaPlayer performSelectorOnMainThread:@selector(close) withObject:nil waitUntilDone:YES];
        self.testViewController.activeCloakMediaPlayer = nil;
    }

    [self ensureActiveCloakContentManager:view];
    
    if (success && self.testViewController.activeCloakContentManager)
    {
        
        [self Log:[NSString stringWithFormat:@"Acquiring a license for the downloaded file \"%@\"\n", entryRecord.downloadToFile]];
        
        NSURL* localUrl = [self.testViewController.activeCloakContentManager getLocalUrl:entryRecord.downloadToFile];

        if ([[NSFileManager defaultManager] fileExistsAtPath:[localUrl path]]) {
            NSString* contentHeader = [self.testViewController.activeCloakContentManager getContentHeader:localUrl ofType:entryRecord.urltype];
            if (contentHeader != nil) {
                [self.testViewController.activeCloakContentManager acquireLicense:contentHeader withCustomData:nil];
            } else {
                [self Log:[NSString stringWithFormat:@"Error: Could not obtain content header for the local file in order to acquire a license for the file %@.\n", entryRecord.downloadToFile]];
                success = NO;
            }
        } else {
            [self Log:[NSString stringWithFormat:@"Error: Could not acquire a license. Local file %@ does not exist.\n", entryRecord.downloadToFile]];
            success = NO;
        }
    }
    else 
    {
        [self Log:@"Error: ContentManager was not created!\n"];
    }
    
    return [NSNumber numberWithBool:success]; 
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)runDownloadAndProgressivelyPlayVideoUsingContentManagerUnitTestWithId:(NSString *)testId
                                                usingOperation:(OperationId)operation
                                                     underView:(DetailViewController*)view
                                                   withEntryId:(NSString *)entryId
                                                     inSection:(NSString *)parentSectionName { 
    
    self.testViewController = view;

    return [self performTestOperation:operation
                           withTestId:testId
                             testName:@"8. Download and Play"
                   againstEntryWithId:entryId
                         selectedFrom:self.atomFeedsDataCollection
                   withMethodSelector:@selector(downloadAndProgressivelyPlayVideoUsingContentManagerForEntry:withEntryId:andTestId:inView:)
                       andSectionName:parentSectionName     
                               inView:view];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(BOOL)resumePausedDownloads:(NSArray*)listOfPausedDownloads {
    BOOL success = YES;
    
    if (listOfPausedDownloads != nil) {
        [self ensureActiveCloakContentManager:self.testViewController];
        if (success && self.testViewController.activeCloakContentManager) {
            for (NSURL* pausedUrl in listOfPausedDownloads) {
                NSLog(@"resumePausedDownloads: pausedUrl = %@\n", [pausedUrl path]);
                [self.testViewController.activeCloakContentManager resumeDownload:pausedUrl];
            }
        }
    }
    return success;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(BOOL)pauseAllQueuedDownloadsAndReturnListOfPaused:(NSArray**)list {

    [self Log:@"Start pausing all downloads in the download queue.\n"];
    
    BOOL success = YES;
    
    [self ensureActiveCloakContentManager:self.testViewController];
    
    NSMutableArray *listOfPausedDownloads = nil;
    
    if (success && self.testViewController.activeCloakContentManager)
    {
        NSLog(@"    Obtaining a list of active downloads\n");
        NSArray* downloadInfoList = [self.testViewController.activeCloakContentManager getActiveDownloads];
        NSInteger index = 0;
        NSLog(@"    Got a list of active downloads\n");
        
        if (downloadInfoList.count > 0) {
            for (ActiveCloakContentInfo* downloadInfo in downloadInfoList) {
                
                if (downloadInfo.downloadState != ACState_DownloadPaused) {
                    NSLog(@"    Pausing download [%d] = %@\n", index, [downloadInfo.url path]);
                    [self.testViewController.activeCloakContentManager pauseDownload:downloadInfo.url];
                    if (listOfPausedDownloads == nil) {
                        listOfPausedDownloads = [[NSMutableArray alloc] initWithCapacity:1];
                    }
                    [listOfPausedDownloads addObject:downloadInfo.url];
                    [self Log:[NSString stringWithFormat:@"   Paused download  [%d] = %@\n", 
                               index,
                               [downloadInfo.url path]]];
                } else {
                    [self Log:[NSString stringWithFormat:@"   Skipped to pause [%d] = %@\n", 
                               index,
                               [downloadInfo.url path]]];
                }
                
                index++;
            }
            
        } else {
            [self Log:@"The queue is empty. Nothing to pause.\n"];
        }
    }
    
    if (list != nil) {
        *list = listOfPausedDownloads;
    }
    
    return success;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)downloadAndProgressivelyPlayVideoUsingContentManagerForEntry:(EntryRecord *)entryRecord withEntryId:(NSString *)entryId andTestId:(NSString *)testId inView:(DetailViewController *)view {
    
    BOOL success = YES;

    NSNumber* result = NULL;
    NSArray* listOfPausedDownloads = nil;
    
    success = [self pauseAllQueuedDownloadsAndReturnListOfPaused:&listOfPausedDownloads];
    
    if (success) {

        result = [self downloadVideoUsingContentManagerForEntry:entryRecord withEntryId:entryId andTestId:testId inView:view];

        if (result == NULL || !result.boolValue) {
            success = NO;
        } else {
            
            NSString *documentsPath = [self getDownloadStorageLocation];
            NSString *localFile = [documentsPath stringByAppendingPathComponent:entryRecord.downloadToFile];
            
            while (YES) {
                
                //
                if ([[NSFileManager defaultManager] fileExistsAtPath:localFile]) {
                    NSError *attributesError = nil;
                    
                    while (YES) {
                        
                        [NSThread sleepForTimeInterval:1];
                        
                        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:localFile error:&attributesError];
                        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
                        long long fileSize = [fileSizeNumber longLongValue];
                        if (fileSize > 0) {
                            result = [self playLocalVideoForEntry:entryRecord withEntryId:entryId andTestId:testId inView:view];
                            
                            if (result == NULL || !result.boolValue) {
                                success = NO;
                            }
                            
                            break;
                        }
                    }
                    
                    break;
                }
                
                [NSThread sleepForTimeInterval:0.001];
            }        
        }
        
        [self resumePausedDownloads:listOfPausedDownloads];
    }
    
    
    return [NSNumber numberWithBool:success]; 
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)onReadyToPlay:(EntryRecord *)entryRecord withEntryId:(NSString *)entryId underTestId:(NSString *)testId inView:(DetailViewController *)view {
    return [self playLocalVideoForEntry:entryRecord withEntryId:entryId andTestId:testId inView:view];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(void)onContentLengthReceived:(NSUInteger)contentLength inView:(DetailViewController *)view {
    [ActiveCloakMediaPlayer setTotalContentLength:contentLength];
}

/*-----------------------------------------------------------------------------
    registerSyndicationBody:fromLink:inView:
 
 ----------------------------------------------------------------------------*/
-(BOOL) registerSyndicationBody:(MessageBuffer*)syndicationBody fromLink:(AtomSyndicationLink *)syndicationLink inView:(DetailViewController *)view {

    BOOL success = YES;
    // Using Atom Syndication format
    AtomFeedsData *atomFeedsData = [[AtomFeedsData alloc] init];
    [atomFeedsData parseAtomFeeds:syndicationBody];
    
    
    // add the atomFeedsData to collection right away
    // because it will be used during the following registration
    // we do not need to remove the previous version of atomFeedsData for
    // the key. It will be replaced with the new one.
    [self.atomFeedsDataCollection setObject:atomFeedsData forKey:atomFeedsData.feedId];
    
    // iterate through all target sections
    for (NSInteger targetCount = 0; targetCount < syndicationLink->numberOfSections; targetCount++) {
        AtomTargetSection *targetSection = &(syndicationLink->listOfTargetSections[targetCount]);
        NSString *targetSectionName = targetSection->targetSectionTitle;
        
        NSDictionary *entries = atomFeedsData.entryRecordList;
        TestLog("entries: count = %d\n", entries.count);
        
        NSEnumerator *entryIds = [entries keyEnumerator];
        NSString* entryId;
        Class targetClass =  NSClassFromString(targetSection->targetSectionClass);
        SEL targetTestFunction = NSSelectorFromString(targetSection->targetMethodName);
        
        // clean up the target section in the test group defined by the class
        [view removeTestSectionByName:targetSectionName inClass:targetClass];
        
        while ((entryId = (NSString *)[entryIds nextObject]) && success) {
            /* code that uses the returned key */
            NSString *testId = [targetSectionName stringByAppendingFormat:@"/%@", entryId];
            //TestLog("test id = %s\n", [testId cStringUsingEncoding:NSUTF8StringEncoding]);
            //TestLog("test id = %s\n", [entryId cStringUsingEncoding:NSUTF8StringEncoding]);
            //EntryRecord *entryRecord = [entries objectForKey:entryId];
            //TestLog("  link = %s\n", [entryRecord.link cStringUsingEncoding:NSUTF8StringEncoding]);
            //TestLog("  imageUrl = %s\n", [entryRecord.imageUrl cStringUsingEncoding:NSUTF8StringEncoding]);
            //TestLog("  imageHeight = %d\n", entryRecord.imageHeight);
            //TestLog("  imageWidth = %d\n", entryRecord.imageHeight);
            
            success = [view registerDynamicUnitTestWithId:testId
                                        fromTestsInstance:self
                                                withClass:targetClass
                                      usingMethodSelector:targetTestFunction
                                              withEntryId:entryId
                                                inSection:targetSectionName];
        }
    }

    return success;
}

/*-----------------------------------------------------------------------------
    registerSyndicationCollection:inView:returnError:
    
    This method performs registration of all syndication links from the
    Syndication Link Collection in the view against all target section 
    described in the list of target sections for a particular syndication
    link.
 ----------------------------------------------------------------------------*/
-(BOOL)registerSyndicationCollection:(AtomSyndicationCollection *)linkCollection inView:(DetailViewController *)view returnError:(NSError **)errorReference {
    BOOL success = YES;
    DataDownloadController *dataController = [[DataDownloadController alloc] initWithTestHost:self];
    
    if (linkCollection != nil && linkCollection->numberOfLinks > 0) {
        if (self.atomFeedsDataCollection == nil) {    
            self.atomFeedsDataCollection = [[NSMutableDictionary alloc] initWithCapacity:linkCollection->numberOfLinks];
        }
        
        for (NSInteger index = 0; linkCollection != nil && index < linkCollection->numberOfLinks && success; index++) {
            AtomSyndicationLink *syndicationLink = &(linkCollection->listOfLinks[index]);
            
            NSData *atomFeeds = [dataController downloadDataFromUrl:[NSString stringWithCString:syndicationLink->atomUrl encoding:NSUTF8StringEncoding]];
            
            if (atomFeeds != nil && dataController.errorInfo == nil) {
                MessageBuffer messageBuffer;
                initMessageBuffer(&messageBuffer);
                appendMessageBuffer(&messageBuffer, (const unsigned char*)atomFeeds.bytes, atomFeeds.length);
                
                success = [self registerSyndicationBody:&messageBuffer fromLink:syndicationLink inView:view];
                
                // free the message buffer because 
                // we do not need it anymore
                freeMessageBuffer(&messageBuffer);
            }
            else {
                // data download controller was able to obtain data for some reason
                // check for the error info and return failure
                if (errorReference != nil && dataController.errorInfo != nil) {
                    *errorReference = dataController.errorInfo;
                    [dataController.errorInfo retain];
                }
                success = NO;
            }
        }
    }
    else {
        success = NO;
    }
    
    return success;
}

/*-----------------------------------------------------------------------------
 registerSyndicationBodyForDownloadAndGo:inView:
 
 ----------------------------------------------------------------------------*/
-(BOOL) registerSyndicationBodyForDownloadAndGo:(MessageBuffer*)syndicationBody inView:(DetailViewController *)view {
    
    BOOL success = YES;
    // Using Atom Syndication format
    AtomFeedsData *atomFeedsData = [[AtomFeedsData alloc] init];
    [atomFeedsData parseAtomFeeds:syndicationBody];
    
    
    // add the atomFeedsData to collection right away
    // because it will be used during the following registration
    // we do not need to remove the previous version of atomFeedsData for
    // the key. It will be replaced with the new one.
    [self.atomFeedsDataCollection setObject:atomFeedsData forKey:atomFeedsData.feedId];

    NSDictionary *entries = atomFeedsData.entryRecordList;
    TestLog("entries: count = %d\n", entries.count);
    
    NSEnumerator *entryIds = [entries keyEnumerator];
    NSString* entryId;
    
    Class targetClass =  [self class];
   
    // clean up the target section in the test group defined by the class
    
    while ((entryId = (NSString *)[entryIds nextObject]) && success) {
        
        EntryRecord *entryRecord = [entries objectForKey:entryId];
        NSString *targetSectionName = entryRecord.title;
        [view removeTestSectionByName:targetSectionName inClass:targetClass];
        /* code that uses the returned key */
        //TestLog("test id = %s\n", [testId cStringUsingEncoding:NSUTF8StringEncoding]);
        //TestLog("test id = %s\n", [entryId cStringUsingEncoding:NSUTF8StringEncoding]);
        //EntryRecord *entryRecord = [entries objectForKey:entryId];
        //TestLog("  link = %s\n", [entryRecord.link cStringUsingEncoding:NSUTF8StringEncoding]);
        //TestLog("  imageUrl = %s\n", [entryRecord.imageUrl cStringUsingEncoding:NSUTF8StringEncoding]);
        //TestLog("  imageHeight = %d\n", entryRecord.imageHeight);
        //TestLog("  imageWidth = %d\n", entryRecord.imageHeight);

        if (success) {
            success = [view registerDynamicUnitTestWithId:[NSString stringWithFormat:@"download/%@", entryId]
                                        fromTestsInstance:self
                                                withClass:targetClass
                                      usingMethodSelector:@selector(runDownloadVideoUsingContentManagerUnitTestWithId:usingOperation:underView:withEntryId:inSection:)
                                              withEntryId:entryId
                                                inSection:targetSectionName];
        }
        if (success) {
            success = [view registerDynamicUnitTestWithId:[NSString stringWithFormat:@"pause/%@", entryId]
                                        fromTestsInstance:self
                                                withClass:targetClass
                                      usingMethodSelector:@selector(runPauseVideoDownloadUsingContentManagerUnitTestWithId:usingOperation:underView:withEntryId:inSection:)
                                              withEntryId:entryId
                                                inSection:targetSectionName];
        }
        if (success) {
            success = [view registerDynamicUnitTestWithId:[NSString stringWithFormat:@"resume/%@", entryId]
                                        fromTestsInstance:self
                                                withClass:targetClass
                                      usingMethodSelector:@selector(runResumeVideoDownloadUsingContentManagerUnitTestWithId:usingOperation:underView:withEntryId:inSection:)
                                              withEntryId:entryId
                                                inSection:targetSectionName];
        }
        if (success) {
            success = [view registerDynamicUnitTestWithId:[NSString stringWithFormat:@"cancel/%@", entryId]
                                        fromTestsInstance:self
                                                withClass:targetClass
                                      usingMethodSelector:@selector(runCancelVideoDownloadUsingContentManagerUnitTestWithId:usingOperation:underView:withEntryId:inSection:)
                                              withEntryId:entryId
                                                inSection:targetSectionName];
        }
        if (success) {
            success = [view registerDynamicUnitTestWithId:[NSString stringWithFormat:@"delete/%@", entryId]
                                        fromTestsInstance:self
                                                withClass:targetClass
                                      usingMethodSelector:@selector(runDeleteDownloadedVideoUsingContentManagerUnitTestWithId:usingOperation:underView:withEntryId:inSection:)
                                              withEntryId:entryId
                                                inSection:targetSectionName];
        }
        if (success) {
            success = [view registerDynamicUnitTestWithId:[NSString stringWithFormat:@"acquire/%@", entryId]
                                        fromTestsInstance:self
                                                withClass:targetClass
                                      usingMethodSelector:@selector(runAcquireLicenseForVideoUsingContentManagerUnitTestWithId:usingOperation:underView:withEntryId:inSection:)
                                              withEntryId:entryId
                                                inSection:targetSectionName];
        }
        if (success) {
            success = [view registerDynamicUnitTestWithId:[NSString stringWithFormat:@"play/%@", entryId]
                                        fromTestsInstance:self
                                                withClass:targetClass
                                      usingMethodSelector:@selector(runPlayLocalVideoUsingContentManagerUnitTestWithId:usingOperation:underView:withEntryId:inSection:)
                                              withEntryId:entryId
                                                inSection:targetSectionName];
        }
        if (success) {
            success = [view registerDynamicUnitTestWithId:[NSString stringWithFormat:@"progressive-download/%@", entryId]
                                        fromTestsInstance:self
                                                withClass:targetClass
                                      usingMethodSelector:@selector(runDownloadAndProgressivelyPlayVideoUsingContentManagerUnitTestWithId:usingOperation:underView:withEntryId:inSection:)
                                              withEntryId:entryId
                                                inSection:targetSectionName];
        }
    }
    
    return success;
}

/*-----------------------------------------------------------------------------
 registerSyndicationCollectionForDownloadAndGo:inView:returnError:
 
 This method performs registration of all syndication links from the
 Syndication Link Collection in the view against all target section 
 described in the list of target sections for a particular syndication
 link.
 ----------------------------------------------------------------------------*/
-(BOOL)registerSyndicationCollectionForDownloadAndGo:(AtomSyndicationCollection *)linkCollection inView:(DetailViewController *)view returnError:(NSError **)errorReference {
    BOOL success = YES;
    DataDownloadController *dataController = [[DataDownloadController alloc] initWithTestHost:self];
    
    if (linkCollection != nil && linkCollection->numberOfLinks > 0) {
        
        if (self.atomFeedsDataCollection == nil) {    
            self.atomFeedsDataCollection = [[NSMutableDictionary alloc] initWithCapacity:linkCollection->numberOfLinks];
        }
        
        for (NSInteger index = 0; linkCollection != nil && index < linkCollection->numberOfLinks && success; index++) {
            AtomSyndicationLink *syndicationLink = &(linkCollection->listOfLinks[index]);
            
            NSData *atomFeeds = [dataController downloadDataFromUrl:[NSString stringWithCString:syndicationLink->atomUrl encoding:NSUTF8StringEncoding]];
            
            if (atomFeeds != nil && dataController.errorInfo == nil) {
                MessageBuffer messageBuffer;
                initMessageBuffer(&messageBuffer);
                appendMessageBuffer(&messageBuffer, (const unsigned char*)atomFeeds.bytes, atomFeeds.length);
                
                success = [self registerSyndicationBodyForDownloadAndGo:&messageBuffer inView:view];
                
                // free the message buffer because 
                // we do not need it anymore
                freeMessageBuffer(&messageBuffer);
            }
            else {
                // data download controller was able to obtain data for some reason
                // check for the error info and return failure
                if (errorReference != nil && dataController.errorInfo != nil) {
                    *errorReference = dataController.errorInfo;
                    [dataController.errorInfo retain];
                }
                success = NO;
            }
        }
    }
    else {
        success = NO;
    }
    
    return success;
}

@end



@implementation VideoTests

/*-----------------------------------------------------------------------------
    This method returns a list of sections in iOS UITableView
    for this particular test group. It's needed to define the order.
 ----------------------------------------------------------------------------*/
- (NSArray *) getSectionOrder {
    NSArray *sectionOrder = [[[NSArray alloc] initWithObjects:@"Tests", @"IISSS URLs", @"HLS URLs", @"Downloads", @"More URLs", nil] autorelease];
    return sectionOrder;
}

AtomTargetSection _listOfIBBISSTargetSections[] =
{
    {@"IBB ISS Tests", @"VideoTests", @"runPlayVideoUnitTestWithId:usingOperation:underView:withEntryId:inSection:"}
};

AtomTargetSection _listOfIBBHLSTargetSections[] =
{
    {@"IBB HLS Tests", @"VideoTests", @"runPlayVideoUnitTestWithId:usingOperation:underView:withEntryId:inSection:"}
};

AtomTargetSection _listOfDemoTargetSections[] =
{
    {@"Demo HLS/IIS Tests", @"VideoTests", @"runPlayVideoUnitTestWithId:usingOperation:underView:withEntryId:inSection:"}
};

AtomSyndicationLink _listOfSyndicationLinks[] = 
{
    {"http://demo.irdeto.com/ibb-iis-content.atom", _listOfIBBISSTargetSections, ARRAYSIZE(_listOfIBBISSTargetSections)},
    {"http://demo.irdeto.com/ibb-content.atom", _listOfIBBHLSTargetSections, ARRAYSIZE(_listOfIBBHLSTargetSections)},
    {"http://demo.irdeto.com/content.atom", _listOfDemoTargetSections, ARRAYSIZE(_listOfDemoTargetSections)},
};

AtomSyndicationCollection _complexSyndicationCollection = {_listOfSyndicationLinks, ARRAYSIZE(_listOfSyndicationLinks)};


MANUAL_TEST_START_EXT(GetWiFiMAC, "Get the device's MAC address", "Get the device's MAC address", 7, TestFlag_Empty, "Tests", nil) 
{
   
    // Here's some sample code to get the device ID's MAC addresses for the various adapters on it.
    // in practice, Wifi always seems to appear first. This can be used for uniquely identifying a device, and is a component of the device ID 
    // returned fromself.testViewController.activeCloakAgent.deviceID
    NSMutableString * systemID = [[[NSMutableString alloc] init] autorelease];
    
    BOOL success;
    struct ifaddrs * addrs;
    const struct ifaddrs * cursor;
    const struct sockaddr_dl * dlAddr;
    const uint8_t * base;
    int i;
    
    success = getifaddrs(&addrs) == 0;
    if (success) 
    {
        cursor = addrs;
        while (cursor != NULL) 
        {
            if ( (cursor->ifa_addr->sa_family == AF_LINK)
                && (((const struct sockaddr_dl *) cursor->ifa_addr)->sdl_type == 0x6 /* IFT_ETHER */) ) 
            {
                dlAddr = (const struct sockaddr_dl *) cursor->ifa_addr;
                base = (const uint8_t *) &dlAddr->sdl_data[dlAddr->sdl_nlen];
                for (i = 0; i < dlAddr->sdl_alen; i++) 
                {
                    [systemID appendFormat:@"%02x", base[i]];
                }
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }     
    
	TestLog("The SystemID is %s\n", [systemID UTF8String]);
    
}
TEST_END

MANUAL_TEST_START(CWS_GetVersionStringTest, "Version String", " Testing ActiveCloakMediaPlayer's versionString property")
{
    [self Log:[NSString stringWithFormat:@"Version string: %@\n", [ActiveCloakMediaPlayer versionString]]]; 
    [self Log:@"Test Passed!\n"];
}
TEST_END

MANUAL_TEST_START(HLS20fixedkeyAcquireLicense, "Acquire license for HLS 2.0 fixed key", "Acquire license for fixed key")
{		
    
    BOOL success = YES;
    self.testViewController = view; 
    
    [self removeMediaPlayerObservers];
    if (self.testViewController.activeCloakMediaPlayer != nil) 
    {
        [self.testViewController.activeCloakMediaPlayer performSelectorOnMainThread:@selector(close) withObject:nil waitUntilDone:YES];
    }
    
    [self ensureActiveCloakContentManager:view];
	
	NSString *contentHeader =  @"bAMAAAEAAQBiAzwAVwBSAE0ASABFAEEARABFAFIAIAB4AG0AbABuAHMAPQAiAGgAdAB0"
							   "AHAAOgAvAC8AcwBjAGgAZQBtAGEAcwAuAG0AaQBjAHIAbwBzAG8AZgB0AC4AYwBvAG0A"
							   "LwBEAFIATQAvADIAMAAwADcALwAwADMALwBQAGwAYQB5AFIAZQBhAGQAeQBIAGUAYQBk"
					 		   "AGUAcgAiACAAdgBlAHIAcwBpAG8AbgA9ACIANAAuADAALgAwAC4AMAAiAD4APABEAEEA"
							   "VABBAD4APABQAFIATwBUAEUAQwBUAEkATgBGAE8APgA8AEsARQBZAEwARQBOAD4AMQA2"
                               "ADwALwBLAEUAWQBMAEUATgA+ADwAQQBMAEcASQBEAD4AQQBFAFMAQwBUAFIAPAAvAEEA"
							   "TABHAEkARAA+ADwALwBQAFIATwBUAEUAQwBUAEkATgBGAE8APgA8AEsASQBEAD4AbwBv"
							   "AHcAMQAyAEMAdwBiAG8AMAAyAEQAVQBpAGwAbQBmAGEAMwBRAGIAZwA9AD0APAAvAEsA"
							   "SQBEAD4APABDAEgARQBDAEsAUwBVAE0APgB4AGkAeABqAFYARQB4AFQAaQBqAGMAPQA8"
							   "AC8AQwBIAEUAQwBLAFMAVQBNAD4APABMAEEAXwBVAFIATAA+AGgAdAB0AHAAOgAvAC8A"
							   "bQBhAG4ALgBsAGgAcgAyAC4AZQBuAHQAcgBpAHEALgBuAGUAdAAvAHAAbABhAHkAcgBl"
							   "AGEAZAB5AC8AcgBpAGcAaAB0AHMAbQBhAG4AYQBnAGUAcgAuAGEAcwBtAHgAPwBDAHIA"
							   "bQBJAGQAPQBlAG4AdAByAGkAcQBkAGUAbQBvACYAYQBtAHAAOwBBAGMAYwBvAHUAbgB0"
							   "AEkAZAA9AGUAbgB0AHIAaQBxAGQAZQBtAG8AJgBhAG0AcAA7AEMAbwBuAHQAZQBuAHQA"
							   "SQBkAD0AVABoAGUARQB4AHAAZQBuAGQAYQBiAGwAZQBzAFQAcgBhAGkAbABlAHIASABE"
							   "ACYAYQBtAHAAOwBTAHUAYgBDAG8AbgB0AGUAbgB0AFQAeQBwAGUAPQBEAGUAZgBhAHUA"
							   "bAB0ADwALwBMAEEAXwBVAFIATAA+ADwALwBEAEEAVABBAD4APAAvAFcAUgBNAEgARQBB"
							   "AEQARQBSAD4A";
	
    
	if (contentHeader != nil) {
                [self.testViewController.activeCloakContentManager acquireLicense:contentHeader withCustomData:nil];
        } else {
        [self Log:[NSString stringWithFormat:@"Error: Could not obtain content header for the local file in order to acquire a license for the file .\n"]];
        success = NO;
    }
    
}
TEST_END

MANUAL_TEST_START_EXT(HlsIisTestsGenerator, "HLS/IIS Video Tests", "Create test cases from Demo.cloakware.com", 7, TestFlag_DemoTest | TestFlag_TestProducer, "Tests", nil)
{		
    [self Log:@"Start creating test cases\n"];
    
    BOOL success = YES;
    NSError *errorInfo = nil;
    
    success = [self registerSyndicationCollection:&_complexSyndicationCollection inView:view returnError:&errorInfo];
    
    if (!success) {
        [self Log:[NSString stringWithFormat:@"Error during registration of the '%@' syndication collection: error message = %@, error code = 0x%0.8x\n",
                   @"HLS/IIS Video Tests",
                   errorInfo != nil ? errorInfo.localizedDescription : @"<empty>", 
                   errorInfo != nil ? errorInfo.code : 0]];
    }
    [errorInfo release];
    
    __ret = success;
}
TEST_END

MANUAL_TEST_START_EXT(SampleHLSToPlay, "Play Apple's Sample Video", "Test playing some Apple's video", 7, TestFlag_Empty, "Tests", nil)
{
    
    NSURL * url = [NSURL URLWithString:@"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"];

    [self playVideoInView:self.testViewController withUrl:url ofType:ACURLTypeHLS withCustomData:nil];
    
}
TEST_END

MANUAL_TEST_START_EXT(InstallCertificate, "Install D&G CA Certificate", "Launch Safari to install the download and go certificate.", 8, TestFlag_Empty, "Tests", nil)
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://demo.irdeto.com/cert/cacert2.der"]];

    __ret = YES;
}        
TEST_END	

// Include video media URLs here, which can be varying depending on packaging flavors
#import "mediaurls.h"

static ACURLType ToACURLType(int val)
{
    ACURLType acUrlType = ACURLTypeIIS;
    switch(val)
    {
        case 0:
            acUrlType = ACURLTypeHLS;
            break;
        case 1:
            acUrlType = ACURLTypeIIS;
            break;
        case 2:
            acUrlType = ACURLTypeEnvelope;
            break;
    }
    
    return acUrlType;
}

MANUAL_TEST_START(MaxBitrate1Test, "Set max bitrate to 1", "Set max bitrate to 1")
{    	
    TestLog("Bitrate set to 1\n");
    [ActiveCloakMediaPlayer setMaxBitRate:1];
}
TEST_END

MANUAL_TEST_START(MaxBitrate500Test, "Set max bitrate to 500", "Set max bitrate to 500")
{    	
    TestLog("Bitrate set to 500\n");
    [ActiveCloakMediaPlayer setMaxBitRate:500];
}
TEST_END

MANUAL_TEST_START(MaxBitrate40000Test, "Set max bitrate to 40000", "Set max bitrate to 40000")
{    	
    TestLog("Bitrate set to 40000\n");
    [ActiveCloakMediaPlayer setMaxBitRate:40000];
}
TEST_END

MANUAL_TEST_START(MinBitrate1Test, "Set min bitrate to 1", "Set min bitrate to 1")
{    	
    TestLog("Bitrate set to 1\n");
    [ActiveCloakMediaPlayer setMinBitRate:1];
}
TEST_END

MANUAL_TEST_START(MinBitrate500Test, "Set minbitrate to 500", "Set min bitrate to 500")
{    	
    TestLog("Bitrate set to 500\n");
    [ActiveCloakMediaPlayer setMinBitRate:500];
}
TEST_END

MANUAL_TEST_START(MinBitrate40000Test, "Set min bitrate to 40000", "Set min bitrate to 40000")
{    	
    TestLog("Bitrate set to 40000\n");
    [ActiveCloakMediaPlayer setMinBitRate:40000];
}
TEST_END

MANUAL_TEST_START(DeviceID, "Display Device ID", "Display Device ID")
{    	
    // call the helper to ensure we have an active cloak agent instance
    [self ensureActiveCloakAgent:view];

    // log the device ID to the screen
    [self Log:[NSString stringWithFormat:@"Device ID: %@\n",self.testViewController.activeCloakAgent.deviceID]];
}
TEST_END

MANUAL_TEST_START(ProvisioningData, "Display Provisioning Data", "Display Provisioning Data")
{    	
    NSString *tmpStr = [NSString stringWithString: [ActiveCloakAgent getProvisioningData]];
	[self Log:[NSString stringWithFormat:@"Device Provisioned: %@\n", tmpStr]];
}
TEST_END

MANUAL_TEST_START(DeviceProvisioned, "Is Device Provisioned", "Is Device Provisioned")
{    	
	[self Log:[NSString stringWithFormat:@"Device Provisioned: %@\n", [ActiveCloakAgent isProvisioned] ? @"YES" : @"NO"]];
}
TEST_END

MANUAL_TEST_START(ProvisionDevice, "Provision via Proxy", "Provision via Proxy")
{    	
    [self ensureActiveCloakAgent:view];
    
    if ([ActiveCloakAgent isProvisioned])
    {
        [self Log:[NSString stringWithFormat:@"This device has already been provsioned.\n"]];
    }
    else 
    {
        ProvisionController *pCtrl = [ProvisionController getProvisionController: self.testViewController.activeCloakAgent];
		[pCtrl provision];
    }
	
}
TEST_END

MANUAL_TEST_START(CustomDataTest1, "Set CustomData to nil", "Set CustomData to nil")
{    	
    TestLog("Setting Custom Data to nil\n");
    g_CurrentCustomData = nil;
}
TEST_END

MANUAL_TEST_START(CustomDataTest2, "Set CustomData to non-nil", "Set CustomData to non-nil")
{    	
    TestLog("Setting Custom Data to non-nil\n");
    g_CurrentCustomData = "TestCustomData";
}
TEST_END

MANUAL_TEST_START(DeleteLicenseStoreTest, "Delete License Store", "Delete License Store")
{    	
    TestLog("Deleting license store...\n");
    [ActiveCloakMediaPlayer deleteLicenseStore];
}
TEST_END

MANUAL_TEST_START(RevokeDevice, "provision - Revoke", "Test provision - Revoke API function")
{
    [self Log:[NSString stringWithFormat:@"Revoking Device (\"deviceStore.hds and irss.dat\")\n"]];

    
    // call the specialized API
    [ActiveCloakAgent provision: nil];
}
TEST_END

MANUAL_TEST_START(ProvisionUsingCreatedPluginIrss, "provision - with Created", "Test provision - API function with created plugin SS")
{
	// Setting this block with 0 length and 0 allocsize to indicate to the
	// Provision API, we want to delete the irss.dat and restore from the bundles
	
	[self Log:[NSString stringWithFormat:@"Provisioning Device (\" using created_dv.dat\")\n"]];
	
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test/created_dv" ofType:@"dat"];  
	NSData *myData = [NSData dataWithContentsOfFile:filePath];  
	if (myData) {  	// call the specialized API
            [ActiveCloakAgent provision: myData];
	}
	else {
		[self Log:[NSString stringWithFormat:@"Error occurred provisioning using precreated Secure Store.\n"]];
	}
        [self Log:[NSString stringWithFormat:@"Provisioning using precreated Secure Store Completed.\n"]];
}
TEST_END

MANUAL_TEST_START(ProvisionUsingRegeneratedPluginIrss, "provision - With Regenerated", "Test provision - API function with regenerated SS")
{
	// Setting this block with 0 length and 0 allocsize to indicate to the
	// Provision API, we want to delete the irss.dat and restore from the bundles
	
	[self Log:[NSString stringWithFormat:@"Provisioning Device (\" using regenerated_dv.dat\")\n"]];
	
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test/regenerated_dv" ofType:@"dat"];  
	NSData *myData = [NSData dataWithContentsOfFile:filePath];  
	if (myData) {  	// call the specialized API
            [ActiveCloakAgent provision: myData];
	}
	else {
		[self Log:[NSString stringWithFormat:@"Error occurred provisioning using regenerated Secure Store.\n"]];
	}
}
TEST_END


MANUAL_TEST_START(RestoreDevice, "provision - Restore", "Test provision - Restore API function")
{
    // Setting this block with 0 length and 0 allocsize to indicate to the
    // Provision API, we want to delete the irss.dat and restore from the bundles
    
    [self Log:[NSString stringWithFormat:@"Restoring Device (\"irss.dat\")\n"]];
    
    // call the specialized API
    [ActiveCloakAgent provision: [[NSData alloc] init]];
}
TEST_END


MANUAL_TEST_START(ForceReconnectionLogic, "Force Reconnection Logic", "Test reconnect logic by simulating a premature 'player ended' callback")
{
    
    [self Log:[NSString stringWithFormat:@"Simulating a premature playerEndedCallback"]];
    DetailViewController *view = [RootViewController currentView:nil].detailViewController;
    
    if (view != nil && self.testViewController.activeCloakMediaPlayer != nil) 
    {
        NSTimeInterval duration =self.testViewController.activeCloakMediaPlayer.duration;
        NSTimeInterval curTime =self.testViewController.activeCloakMediaPlayer.currentPlaybackTime;
        if (curTime >= 2.0)
        {
            view.lastPosition = curTime;
        }
        
        if (isnan(duration) // reconnect if we are a live stream
                || duration == 0 // reconnect if we otherwise don't know the duration
                || (duration > 5.0 && view.lastPosition < duration - 5.0) // don't reconnect if we are within 5 seconds of the end of the stream
                )
            
        {
            // the player might give us this event even though it isn't done, because it detected a
            // lapse in network connectivity. To work around it, we force the player to reconnect to
            // the local URL. 
            // need to tell the CWS handle not to block players by saying 'force reconnect'
            [self.testViewController.activeCloakMediaPlayer forceReconnect:view.lastPosition]; 
        }
        else
        {
            // every other case is a request to close the media player: video actually finished, or user clicked 'Done'
            [self removeMediaPlayerObservers];
           self.testViewController.activeCloakMediaPlayer = nil;
            view.lastPosition = 0;
        }
    }

}
TEST_END



MANUAL_TEST_START(ClosePlayer, "Close Player", "Close currently playing stream")
{
    // Setting this block with 0 length and 0 allocsize to indicate to the
    // Provision API, we want to delete the irss.dat and restore from the bundles
    
    [self Log:[NSString stringWithFormat:@"Closing stream\n"]];
    
    [self removeMediaPlayerObservers];
    if (self.testViewController.activeCloakMediaPlayer != nil) 
    {
        [self.testViewController.activeCloakMediaPlayer performSelectorOnMainThread:@selector(close) withObject:nil waitUntilDone:YES];
    }
}
TEST_END

@end

///////////////////////////////////////////////////////////////////////////////
// DownloadAndGoTests class implementation
@implementation DownloadAndGoTests

@synthesize needCancelConfirmation = __needCancelConfirmation;
@synthesize canceledUrl = __canceledUrl;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id)initWithLogger:(id<TestLog>)testLogger andParentTestGroup:(TestGroup *)testGroup {
    [super initWithLogger:testLogger andParentTestGroup:testGroup];
    
    self.needCancelConfirmation = NO;
    self.canceledUrl = nil;
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)dealloc {
    self.canceledUrl = nil;;
    [super dealloc];
}


-(void)downloadProgress:(ActiveCloakContentInfo*)downloadInfo
{
    DetailViewController* view = [RootViewController currentView:nil].detailViewController;
    NSCharacterSet * comma = [NSCharacterSet characterSetWithCharactersInString:@","];
    NSArray *plist = [downloadInfo.cookie componentsSeparatedByCharactersInSet:comma];
    NSString *className = [plist objectAtIndex:0];
    NSString *testId = [plist objectAtIndex:1];
    Class parentClass = NSClassFromString(className);
    NSString *state = @"<unknown>";
    float progressValue =  downloadInfo.percentComplete; // downloadInfo.totalSize == 0 ? 0.0 : (float)downloadInfo.bytesDownloaded/(float)downloadInfo.totalSize;
    DownloadProgressBarParameters* parameters = [[DownloadProgressBarParameters alloc] initWithTestId:testId targetClass:parentClass andProgress:progressValue];
    
    switch (downloadInfo.downloadState)
    {
        case ACState_DownloadCancelled:
            state = @"Cancelled";
            NSLog(@"downloadProgress: CANCELED, parentClassName = %@, testId = %@\n", className, testId);
            if (view != nil && testId != nil)
            {    
                [(NSObject *)view  performSelectorOnMainThread:@selector(disableProgressBar:) withObject:parameters waitUntilDone:YES];
            }
            if (self.needCancelConfirmation) {
                self.canceledUrl = downloadInfo.url;
                self.needCancelConfirmation = NO;
            }
            break;
        case ACState_DownloadCompleted:
            state = @"Completed";
            NSLog(@"downloadProgress: COMPLETED at %@, parentClassName = %@, testId = %@, localFile = %@\n", [[NSDate date] description], className, testId, downloadInfo.localFile);
            if (view != nil && testId != nil)
            {    
                [(NSObject *)view  performSelectorOnMainThread:@selector(updateProgressBar:) withObject:parameters waitUntilDone:YES];
                [(NSObject *)view  performSelectorOnMainThread:@selector(disableProgressBar:) withObject:parameters waitUntilDone:YES];
            }
            break;
        case ACState_DownloadError:
            state = @"Error";
        	[self Log:[NSString stringWithFormat:@"\nDownload FAILED: URL = %@, internal code = 0x%0.8x, HTTP code = %d\n", 
                   		[downloadInfo.url absoluteString],
                   		downloadInfo.errorCode, 
                   		downloadInfo.httpStatusCode]];
			[self Log:[NSString stringWithFormat:@"Download manager put this download process into PAUSE state.\nYou can manually Resume or Cancel it.\n\n"]];
			// We do not cancel the downloading because of the failure. We paused it instead, to give an opportunity
			// for the downloader manager to try to download it once more time.
			// If you need to cancel the download, uncomment the following two lines:
        	//[self Log:[NSString stringWithFormat:@"Canceled download of %@\n", [downloadInfo.url absoluteURL]]];
        	//[self.testViewController.activeCloakContentManager cancelDownload:downloadInfo.url];
            break;
        case ACState_Downloading:
            state = @"Downloading";
            if (view != nil && testId != nil)
            {    
                [(NSObject *)view  performSelectorOnMainThread:@selector(enableProgressBar:) withObject:parameters waitUntilDone:YES];
                [(NSObject *)view  performSelectorOnMainThread:@selector(updateProgressBar:) withObject:parameters waitUntilDone:YES];
            }
            
            break;
        case ACState_DownloadPaused:
            state = @"Paused";
            NSLog(@"downloadProgress: PAUSED, parentClassName = %@, testId = %@, localFile = %@\n", className, testId, downloadInfo.localFile);
            break;
        case ACState_DownloadQueued:
            state = @"Queued";
            NSLog(@"downloadProgress: QUEUED, parentClassName = %@, testId = %@, localFile = %@\n", className, testId, downloadInfo.localFile);
            break;
        case ACState_DownloadResumed:
            state = @"Resumed";
            NSLog(@"downloadProgress: RESUMED, parentClassName = %@, testId = %@, localFile = %@\n", className, testId, downloadInfo.localFile);
            if (view != nil && testId != nil)
            {    
                [(NSObject *)view  performSelectorOnMainThread:@selector(enableProgressBar:) withObject:parameters waitUntilDone:YES];
                [(NSObject *)view  performSelectorOnMainThread:@selector(updateProgressBar:) withObject:parameters waitUntilDone:YES];
            }
            break;
        case ACState_DownloadStarted:
            state = @"Started";
            NSLog(@"downloadProgress: STARTED at %@, parentClassName = %@, testId = %@, localFile = %@\n", [[NSDate date] description], className, testId, downloadInfo.localFile);
            if (view != nil && testId != nil)
            {    
                [(NSObject *)view  performSelectorOnMainThread:@selector(enableProgressBar:) withObject:parameters waitUntilDone:YES];
            }
            break;
    }

    [parameters release];

    /*
    [self Log:[NSString stringWithFormat:@"DL: %@, %@, %@ - %1.2f, %1.2f, %d, %d\n", 
               state,
               downloadInfo.localFile, 
               downloadInfo.cookie,
               downloadInfo.percentComplete,
               progressValue,
               downloadInfo.bytesDownloaded, 
               downloadInfo.totalSize]];
     */
}

const char* getDownloadStateName(ACState downloadState)
{
    const char* stateName = nil;
    if (downloadState == ACState_DownloadCancelled) {
        stateName = "Cancelled";
    } else if (downloadState == ACState_DownloadCompleted) {
        stateName = "Completed";
    } else if (downloadState == ACState_DownloadError) {
        stateName = "Error";
    } else if (downloadState == ACState_Downloading) {
        stateName = "Downloading";
    } else if (downloadState == ACState_DownloadPaused) {
        stateName = "Paused";
    } else if (downloadState == ACState_DownloadQueued) {
        stateName = "Queued";
    } else if (downloadState == ACState_DownloadResumed) {
        stateName = "Resumed";
    } else if (downloadState == ACState_DownloadStarted) {
        stateName = "Started";
    } else {
        stateName = "Unknown";
    }
    
    return stateName;
}

MANUAL_TEST_START_EXT(DLGLogActiveDownloads, "Log Active Downloads", "Dump information about the current status of the download queue into the log.", 1, TestFlag_DemoTest, "Tests", nil)
{		
    [self Log:@"Start logging information about the current status of the downlod queue.\n"];
    
    BOOL success = YES;

    [self ensureActiveCloakContentManager:view];
    
    if (success && self.testViewController.activeCloakContentManager)
    {
        NSArray* downloadInfoList = [self.testViewController.activeCloakContentManager getActiveDownloads];
        NSInteger index = 0;

        if (downloadInfoList.count > 0) {
            for (ActiveCloakContentInfo* downloadInfo in downloadInfoList) {
                [self Log:[NSString stringWithFormat:@"Queue[%d] = %s, %@, %@, %2.2f, %lld, %lld\n", 
                           index,
                           getDownloadStateName(downloadInfo.downloadState),
                           downloadInfo.localFile,
                           downloadInfo.cookie,
                           downloadInfo.percentComplete,
                           downloadInfo.bytesDownloaded, 
                           downloadInfo.totalSize]];
                index++;
            }
        } else {
            [self Log:@"The queue is empty. Nothing to dump into the log.\n"];
        }
    }    
    
    __ret = success;
}
TEST_END

MANUAL_TEST_START_EXT(DLGCancelAllDownloads, "Cancel All Downloads", "Cancel all pending or active downloads in the download queue", 2, TestFlag_DemoTest, "Tests", nil)
{		
    [self Log:@"Start canceling all downloads in the download queue.\n"];
    
    BOOL success = YES;
    
    [self ensureActiveCloakContentManager:view];
    
    if (success && self.testViewController.activeCloakContentManager)
    {
        NSArray* downloadInfoList = [self.testViewController.activeCloakContentManager getActiveDownloads];
        NSInteger index = 0;
        
        if (downloadInfoList.count > 0) {
            for (ActiveCloakContentInfo* downloadInfo in downloadInfoList) {
                self.needCancelConfirmation = YES;
                self.canceledUrl = nil;
                NSURL* urlToCancel = downloadInfo.url;
                [self.testViewController.activeCloakContentManager cancelDownload:downloadInfo.url];
                [self Log:[NSString stringWithFormat:@"   Canceled Queue[%d] = %@\n", 
                           index,
                           [downloadInfo.url path]]];
                while (self.canceledUrl == nil) {
                    [NSThread sleepForTimeInterval:0.0001];
                }
                if ([[urlToCancel path] isEqualToString:[self.canceledUrl path]]) {
                    self.canceledUrl = nil;
                } else {
                    [self Log:[NSString stringWithFormat:@"Error: Requested and canceled URLs are not equal.\n   Requested URL = %@\n   Canceled URL = %@\n", [urlToCancel path], [self.canceledUrl path]]];
                }
                index++;
            }
            
            downloadInfoList = [self.testViewController.activeCloakContentManager getActiveDownloads];
            
            if (downloadInfoList.count > 0) {
                [self Log:[NSString stringWithFormat:@"Error: The download queue is still not empty after canceling all pending and active download requests in the queue.\n   downloadInfoList.count = %d\n", downloadInfoList.count]];
                success = NO;
            } else {
                [self Log:@"All downloads were successfully canceled.\n"];
            }
        } else {
            [self Log:@"The queue is empty. Nothing to cancel.\n"];
        }
    }    
    
    __ret = success;
}
TEST_END

MANUAL_TEST_START_EXT(DLGListAllLocalFiles, "List Local Files", "List all local files in the log window", 3, TestFlag_DemoTest, "Tests", nil)
{		
    [self Log:@"Start logging information about local files.\n"];
    
    BOOL success = YES;
    
    NSString* localStorage = [self getDownloadStorageLocation];
    
    // Create a local file manager instance
    NSFileManager *localFileManager=[NSFileManager  defaultManager];
    
    NSArray *listOfLocalFiles = [localFileManager contentsOfDirectoryAtPath:localStorage error:nil];

    for (NSString* localFilePath in listOfLocalFiles) {
        
        [self Log:[NSString stringWithFormat:@"   %@\n", localFilePath]];
    }

    __ret = success;
}
TEST_END

@end

///////////////////////////////////////////////////////////////////////////////
// Envelope_DownloadAndGo class implementation
@implementation Envelope_DownloadAndGo

AtomSyndicationLink _listOfEnvelopeVideoToPlay[] = 
{
    {"http://demo.irdeto.com/download-and-go-content.atom", nil, 0},
};

AtomSyndicationCollection _envelopeDownloadAndGoCollectionToPlay = {_listOfEnvelopeVideoToPlay, ARRAYSIZE(_listOfEnvelopeVideoToPlay)};


MANUAL_TEST_START_EXT(DlgTestsGenerator, "Create Envelope Video Tests", "Create test cases for Envelope Download And Go feature testing", 1, TestFlag_DemoTest | TestFlag_TestProducer, "Tests", nil)
{		
    [self Log:@"Start creating test cases\n"];
    
    BOOL success = YES;
    NSError *errorInfo = nil;
    
    success = [self registerSyndicationCollectionForDownloadAndGo:&_envelopeDownloadAndGoCollectionToPlay inView:view returnError:&errorInfo];
    
    if (!success) {
        [self Log:[NSString stringWithFormat:@"Error during registration of the '%@' sydication collection: error message = %@, error code = 0x%0.8x\n",
                   @"D&G Video Tests with CM",
                   errorInfo != nil ? errorInfo.localizedDescription : @"<empty>", 
                   errorInfo != nil ? errorInfo.code : 0]];
    }
    [errorInfo release];
    
    __ret = success;
}
TEST_END




@end

#ifndef NOIISSSCLIENT

///////////////////////////////////////////////////////////////////////////////
// IISSS_DownloadAndGo class implementation
@implementation IISSS_DownloadAndGo

@synthesize bitrateRequestDialogSucceeded = __bitrateRequestDialogSucceeded;
@synthesize bitrateRequestDialogCanceled = __bitrateRequestDialogCanceled;
@synthesize bitrateTextField = __bitrateTextField;
@synthesize bitrateSetupType = __bitrateSetupType;
@synthesize segmentLabel = __segmentLabel;
@synthesize downloadBitrate = __downloadBitrate;   

AtomSyndicationLink _listOfIISSSVideoToPlay[] = 
{
    {"http://demo.irdeto.com/ibb-iis-content.atom", nil, 0},
};

AtomSyndicationCollection _iisssDownloadAndGoCollectionToPlay = {_listOfIISSSVideoToPlay, ARRAYSIZE(_listOfIISSSVideoToPlay)};


MANUAL_TEST_START_EXT(DlgTestsGenerator, "Create IISS Video Tests", "Create test cases for IISSS Download And Go feature testing", 1, TestFlag_DemoTest | TestFlag_TestProducer, "Tests", nil)
{		
    [self Log:@"Start creating test cases\n"];
    
    BOOL success = YES;
    NSError *errorInfo = nil;
    
    success = [self registerSyndicationCollectionForDownloadAndGo:&_iisssDownloadAndGoCollectionToPlay inView:view returnError:&errorInfo];
    
    if (!success) {
        [self Log:[NSString stringWithFormat:@"Error during registration of the '%@' sydication collection: error message = %@, error code = 0x%0.8x\n",
                   @"D&G Video Tests with CM",
                   errorInfo != nil ? errorInfo.localizedDescription : @"<empty>", 
                   errorInfo != nil ? errorInfo.code : 0]];
    }
    [errorInfo release];
    
    __ret = success;
}
TEST_END

#define ALL_BITRATE @"All Available Bitrates"
#define MAX_BITRATE @"The highest available bitrate"
#define MIN_BITRATE @"The lowest available bitrate"
#define USR_BITRATE @"Custom value (kilobits/sec)"

#define ALL_BITRATE_INDEX 0
#define MAX_BITRATE_INDEX 1
#define MIN_BITRATE_INDEX 2
#define USR_BITRATE_INDEX 3

MANUAL_TEST_START(CWS_SetMaxBitrateFromDialog, "Set Download Bitrate", "Set download bitreate for IISSS downloads")
{
    TestLog("Set Bitrate From Dialog: started\n");
    
    self.downloadBitrate = self.customDownloadBitrate;
    
    [self performSelectorOnMainThread:@selector(showBitrateDialog) withObject:nil waitUntilDone:YES];
    
    while (self.bitrateTextField != nil) {
        [NSThread sleepForTimeInterval:(NSTimeInterval)1.0]; 
    }
    
    if (self.bitrateRequestDialogSucceeded && !self.bitrateRequestDialogCanceled) {
        //NSInteger result = CWS_RESULT_SUCCESS;
        TestLog("Set Download Bitrate From Dialog: bitrate type = %s (value = %d)\n", 
                self.downloadBitrate == ACBitrate_All ? "ACBitrate_All" :
                self.downloadBitrate == ACBitrate_Max ? "ACBitrate_Max" :
                self.downloadBitrate == ACBitrate_Min ? "ACBitrate_Min" : "Custom", self.downloadBitrate);
        
        // set the bitrate at the maximum or minimum with the custom value
        //result = CWS_SetOptionInt(self.maxBitrate ? CWS_OPTION_MAXIMUM_BITRATE : CWS_OPTION_MINIMUM_BITRATE, self.customBitrate);
        self.customDownloadBitrate = self.downloadBitrate;
        
        __ret = YES;
    } else if (self.bitrateRequestDialogSucceeded) {
        TestLog("Set Download Bitrate From Dialog: Dialog was canceled.\n");
        __ret = YES;
    } else {
        TestLog("Set Download Bitrate From Dialog: Dialog was not succeeded. Probably because the value was not correct.\n");
        __ret = NO;
    }
    
    
    TestLog("Set Bitrate From Dialog: %s\n", __ret ? "SUCCEEDED" : "FAILED");
    
}
TEST_END


/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) showBitrateDialog {
    
    UIAlertView *prompt = [[UIAlertView alloc] initWithTitle:@"Download Bitrate Setting"
                                                     message:@"\n\n\n"
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Enter", nil];
    
    // create a label for segment description
    self.segmentLabel = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 50.0, 260.0, 20.0)];
    self.segmentLabel.backgroundColor = [UIColor clearColor];
    self.segmentLabel.textColor = [UIColor whiteColor];
    self.segmentLabel.textAlignment = UITextAlignmentCenter;
    [prompt addSubview:self.segmentLabel];
    
    // create UISegmentControl object to enter bitrate type ALL, MINIMUM, MAXIMUM, or Custom
    self.bitrateSetupType = [[UISegmentedControl alloc] initWithFrame:CGRectMake(12.0, 75.0, 260.0, 20.0)];
    [self.bitrateSetupType insertSegmentWithTitle:@"All" atIndex:ALL_BITRATE_INDEX animated:YES];
    [self.bitrateSetupType insertSegmentWithTitle:@"Max" atIndex:MAX_BITRATE_INDEX animated:YES];
    [self.bitrateSetupType insertSegmentWithTitle:@"Min" atIndex:MIN_BITRATE_INDEX animated:YES];
    [self.bitrateSetupType insertSegmentWithTitle:@" * " atIndex:USR_BITRATE_INDEX animated:YES];
    [self.bitrateSetupType setEnabled:YES forSegmentAtIndex:ALL_BITRATE_INDEX];
    [self.bitrateSetupType setEnabled:YES forSegmentAtIndex:MAX_BITRATE_INDEX];
    [self.bitrateSetupType setEnabled:YES forSegmentAtIndex:MIN_BITRATE_INDEX];
    [self.bitrateSetupType setEnabled:YES forSegmentAtIndex:USR_BITRATE_INDEX];
    [self.bitrateSetupType addTarget:self action:@selector(toggleBitrateTarget:) forControlEvents:UIControlEventValueChanged];
    [prompt addSubview:self.bitrateSetupType];
    
    // create UITextField object to enter bitrate value
    self.bitrateTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 100.0, 260.0, 20.0)];
    [self.bitrateTextField setBackgroundColor:[UIColor whiteColor]];
    [self.bitrateTextField setPlaceholder:@"bitrate"];
    [prompt addSubview:self.bitrateTextField];
    
    
    [prompt show];
    [prompt release];
    
    //[self.bitrateTextField becomeFirstResponder];
    if (self.downloadBitrate == ACBitrate_All) {
        self.bitrateSetupType.selectedSegmentIndex = ALL_BITRATE_INDEX;
        self.segmentLabel.text = ALL_BITRATE;
        self.bitrateTextField.enabled = NO;
        self.bitrateTextField.hidden = YES;
    } else if (self.downloadBitrate == ACBitrate_Max) {
        self.bitrateSetupType.selectedSegmentIndex = MAX_BITRATE_INDEX;
        self.segmentLabel.text = MAX_BITRATE;
        self.bitrateTextField.enabled = NO;
        self.bitrateTextField.hidden = YES;
    } else if (self.downloadBitrate == ACBitrate_Min) {
        self.bitrateSetupType.selectedSegmentIndex = MIN_BITRATE_INDEX;
        self.segmentLabel.text = MIN_BITRATE;
        self.bitrateTextField.enabled = NO;
        self.bitrateTextField.hidden = YES;
    } else {
        self.bitrateSetupType.selectedSegmentIndex = USR_BITRATE_INDEX;
        self.segmentLabel.text = USR_BITRATE;
        self.bitrateTextField.enabled = YES;
        self.bitrateTextField.hidden = NO;
        self.bitrateTextField.text = [NSString stringWithFormat:@"%d", self.downloadBitrate];
    }
    self.bitrateRequestDialogSucceeded = NO;
    self.bitrateRequestDialogCanceled = NO;
}

#pragma mark -
#pragma mark UIAlertViewDelegate protocol functions

#define CWS_UINT32_MAX 0xFFFFFFFF

/*-----------------------------------------------------------------------------
 Called when a button is clicked. 
 The view will be automatically dismissed after this call returns
 ----------------------------------------------------------------------------*/
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    TestLog("alertView:clickedButtonAtIndex: %d (%s)\n", buttonIndex, buttonIndex == 0 ? "Cancel" : "Enter");
    
    switch (buttonIndex)
    {
        case 0: // Cancel
        {
            // Leave default value
            self.bitrateRequestDialogCanceled = YES;
            self.bitrateRequestDialogSucceeded = YES;
            break;
        }
        case 1: // Enter
        {
            if ([self.bitrateSetupType selectedSegmentIndex] == USR_BITRATE_INDEX) {
                
                double value = 0.0;
                NSScanner *scanner = [[NSScanner alloc] initWithString:self.bitrateTextField.text];
                if ([scanner scanDouble:&value] && [scanner isAtEnd]) {
                    if ((double)0 <= value && value <= (double)CWS_UINT32_MAX) {
                        self.downloadBitrate = round(value);
                        self.bitrateRequestDialogSucceeded = YES;
                    } else if (value < (double)0) {
                        TestLog("Entered value for bitrate %.0f is less than 0.\n", value);
                    } else {
                        TestLog("Entered value for bitrate %.0f is greater than %u.\n", value, CWS_UINT32_MAX); 
                    }
                } else {
                    TestLog("Entered a non-numeric value - %s\n", [self.bitrateTextField.text cStringUsingEncoding:NSUTF8StringEncoding]);
                }
                [scanner release];
            } else {
                self.bitrateRequestDialogSucceeded = YES;
            }
            
            break;
        }
    }
    
    //[self.bitrateTextField resignFirstResponder];
    [self.bitrateTextField release];
    self.bitrateTextField = nil;
    [self.bitrateSetupType release];
    self.bitrateSetupType = nil;
    [self.segmentLabel release];
    self.segmentLabel = nil;
}

/*-----------------------------------------------------------------------------
 Called when we cancel a view (eg. the user clicks the Home button). 
 This is not called when the user clicks the cancel button.
 If not defined in the delegate, we simulate a click in the cancel button
 ----------------------------------------------------------------------------*/
- (void)alertViewCancel:(UIAlertView *)alertView {
}

/*-----------------------------------------------------------------------------
 before animation and showing view
 ----------------------------------------------------------------------------*/
- (void)willPresentAlertView:(UIAlertView *)alertView {
}

/*-----------------------------------------------------------------------------
 after animation
 ----------------------------------------------------------------------------*/
- (void)didPresentAlertView:(UIAlertView *)alertView {
}

/*-----------------------------------------------------------------------------
 before animation and hiding view
 ----------------------------------------------------------------------------*/
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
}

/*-----------------------------------------------------------------------------
 after animation
 ----------------------------------------------------------------------------*/
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex < 0) {
        // someone clicked outside of the dilaog to dismiss it.
        // remove dialog
        self.bitrateRequestDialogCanceled = YES;
        self.bitrateRequestDialogSucceeded = YES;
        [self.bitrateTextField resignFirstResponder];
        [self.bitrateTextField release];
        self.bitrateTextField = nil;
        [self.bitrateSetupType release];
        self.bitrateSetupType = nil;
        [self.segmentLabel release];
        self.segmentLabel = nil;
    }
}

- (IBAction)toggleBitrateTarget:(id)sender
{
    UISegmentedControl *segControl = sender;
    switch (segControl.selectedSegmentIndex)
    {
        case ALL_BITRATE_INDEX:	// All
        {
            NSLog(ALL_BITRATE);
            self.bitrateTextField.enabled = NO;
            self.bitrateTextField.hidden = YES;
            self.segmentLabel.text = ALL_BITRATE;
            self.downloadBitrate = ACBitrate_All;
            break;
        }
        case MAX_BITRATE_INDEX: // Max
        {	
            NSLog(MAX_BITRATE);
            self.bitrateTextField.enabled = NO;
            self.bitrateTextField.hidden = YES;
            self.segmentLabel.text = MAX_BITRATE;
            self.downloadBitrate = ACBitrate_Max;
            break;
        }
        case MIN_BITRATE_INDEX:	// Min
        {
            NSLog(MIN_BITRATE);
            self.bitrateTextField.enabled = NO;
            self.bitrateTextField.hidden = YES;
            self.segmentLabel.text = MIN_BITRATE;
            self.downloadBitrate = ACBitrate_Min;
            break;
        }
        case USR_BITRATE_INDEX:	// Variable
        {
            NSLog(USR_BITRATE);
            self.bitrateTextField.enabled = YES;
            self.bitrateTextField.hidden = NO;
            self.segmentLabel.text = USR_BITRATE;
            break;
        }
    }
    
}

@end

#endif

 
