//
//  SolutionTests.h
//  TestBed
//
//  Created by Apple User on 12/1/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tests.h"
#import "ActiveCloakMediaPlayer.h"
#import "AtomFeedsData.h"
#import "DataDownloadController.h"
#import "ActiveCloakContentManager.h"

typedef struct _AtomTargetSection
{
    NSString *targetSectionTitle;
    NSString *targetSectionClass;
    NSString *targetMethodName;
} AtomTargetSection;

typedef struct _AtomSyndicationLink
{
    const char* atomUrl;
    AtomTargetSection *listOfTargetSections;
    NSInteger numberOfSections;
} AtomSyndicationLink;

typedef struct _AtomSyndicationCollection
{
    AtomSyndicationLink *listOfLinks;
    NSInteger numberOfLinks;
} AtomSyndicationCollection;

@interface SolutionTests : Tests <UIAlertViewDelegate, ActiveCloakMediaPlayerDelegate> 
{
}

- (id)initWithLogger:(id<TestLog>)testLogger andParentTestGroup:(TestGroup *)testGroup;
- (void)ensureActiveCloakAgent:(DetailViewController *)view;
- (void)ensureActiveCloakMediaPlayer:(DetailViewController *)view;
- (void)ensureActiveCloakContentManager:(DetailViewController *)view;
- (void)handleSecurityAbuseDetection;
- (void)handleSecurityJailbreakDetection;
- (void)showSecurityAlertDialog;
// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
// Called when we cancel a view (eg. the user clicks the Home button). This is not called when the user clicks the cancel button.
// If not defined in the delegate, we simulate a click in the cancel button
- (void)alertViewCancel:(UIAlertView *)alertView;
- (NSObject*)playerEndedCallback:(NSNotification*)notification;
- (BOOL)playCurrentlySelectedVideoInView:(DetailViewController*)view;
- (BOOL)registerSyndicationCollection:(AtomSyndicationCollection *)linkCollection
                               inView:(DetailViewController *)view
                          returnError:(NSError **)errorReference;
- (id)performTestOperation:(OperationId)operation
                withTestId:(NSString *)testId
                  testName:(NSString *)testName
        againstEntryWithId:(NSString *)entryId
              selectedFrom:(NSDictionary *)atomFeedsDataList
        withMethodSelector:(SEL)functionSelector
            andSectionName:(NSString *)parentSectionName     
                    inView:(DetailViewController*)view;
-(NSString*)getDownloadStorageLocation;


// ProgressiveDownloadPlayback protocol
-(id)onReadyToPlay:(EntryRecord *)entryRecord withEntryId:(NSString *)entryId underTestId:(NSString *)testId inView:(DetailViewController *)view;
-(void)onContentLengthReceived:(NSUInteger)contentLength inView:(DetailViewController *)view;

// bunch of scalars -- don't need anything but assign semantics
@property (nonatomic, assign) BOOL attackHasBeenAlreadyDetected;
@property (nonatomic, assign) BOOL jailbreakHasBeenAlreadyDetected;
@property (nonatomic, assign) NSInteger customDownloadBitrate;

// bunch of properties that are owned by our object
@property (nonatomic, retain) DetailViewController *testViewController;
@property (nonatomic, retain) UIWebView *webview;
@property (nonatomic, retain) NSString* downloadLocation;
@property (nonatomic, retain) NSMutableDictionary *atomFeedsDataCollection;
@property (nonatomic, retain) UIButton *jailbreakIcon;


@end

@interface VideoTests : SolutionTests {
}

// This method returns a list of sections in iOS UITableView
// for this particular test group. It's needed to define the order.
- (NSArray *) getSectionOrder;

@end

@interface DownloadAndGoTests : SolutionTests
{
    
}

@property (nonatomic, retain) NSURL* canceledUrl;
@property (nonatomic, assign) BOOL needCancelConfirmation;

@end

@interface Envelope_DownloadAndGo : DownloadAndGoTests {
    
}
@end

#ifndef NOIISSSCLIENT

@interface IISSS_DownloadAndGo : DownloadAndGoTests <UIAlertViewDelegate> {
    }

// The following varaibles are related to Bitrate Setting Dialog unit test:
@property (nonatomic, assign) BOOL bitrateRequestDialogSucceeded;        // if flag is YES, the Bitrate Dialog completed successfully. 
// It means, either it was canceled or the correct value was entered.
// Otherwise, an incorrect value was entered or something bed happend
// during the dialog interaction.
@property (nonatomic, assign) BOOL bitrateRequestDialogCanceled;         // if flag is YES, the dialog was canceled

@property (nonatomic, retain) UITextField *bitrateTextField;             // A placeholder for bitrate UITextField object. If it is not nil, the dialog is active.
@property (nonatomic, retain) UISegmentedControl *bitrateSetupType;      // A placeholder for butrate setup type UISegmentControl object
@property (nonatomic, retain) UILabel	*segmentLabel;                     // A placeholder for segment description label
@property (nonatomic, assign) NSInteger downloadBitrate;                 // A temporary download bitrate value



@end

#endif

