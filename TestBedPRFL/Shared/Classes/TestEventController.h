//
//  TestEventController.h
//  TestBed
//
//  Created by Apple User on 11/27/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetServiceController.h"
#import "ResponseContext.h"


// TestEvent is an input alphabet of the testing finite-state machine 
typedef enum {
    te_Unknown = -1,
    te_ApplicationLaunched = 0,
    te_ConnectedToServer,
    te_DisconnectedFromServer,
    te_SentRequest,
    te_ReceivedResponse,
    te_StartedUnitTest,
    te_CompletedUnitTest,
    te_FinishedTesting,
    te_count
} TestEvent;

// TestProcessState is a set of states of the testing finite-state machine
typedef enum {
    ts_first = -5,
    ts_AnalyzeCmd = -4,
    ts_Exit = -3,
    ts_Unexpected = -2,
    ts_Unknown = -1,
    ts_Start = 0,
    ts_WaitForServer,
    ts_SendHello,
    ts_WaitHello,
    ts_SendGetNextCmd,
    ts_WaitNextCmd,
    ts_DoManual,
    ts_DoAutomatic,
    ts_DoExit,
    ts_DoRunAll,
    ts_DoRunSelected,
    ts_DoGetTestList,
    ts_DoGetStatus,
    ts_Stop,
    ts_PrepareNextTest,
    ts_TestExecuting,
    ts_SendTestList,
    ts_SendStatus,
    ts_WaitConfirmation,
    ts_GUIControlled,
    ts_count
} TestProcessState;

@class DetailViewController;

///////////////////////////////////////////////////////////////////////////////
// TestEventController
//
// This class defines an object that controlls test events in manual and 
// automatic mode. It based on a finite-state machine (a finite automata)
//
@interface TestEventController : NSObject {
    DetailViewController *_detailViewController;
    NetServiceController *_netServiceController;
    TestProcessState _currentState; // current state of the finite-state machine
    TestProcessState _previousState; // previous state of the finite-state machine
    ResponseContext *_responseContext; // receives response from TestBoss
    NSString *deviceUniqueId;   // need this ID to identifier itself in the test service
    BOOL runOnlyAutomatic; // if the flag is YES, TestEventControllers runs in the automatic mode
    NSString *_deviceName; // device name to identify itself in the network
@private    
    MessageBuffer _requestMessage;
    BOOL _discoveryMode;
    int _serviceIndex;
}

- (id) initWithDetailViewController:(DetailViewController *)detailViewController NetService:(NetServiceController *)controller;
- (void) dispatchTestEvent: (TestEvent)testEvent;
- (void) sendReportMessage:(NSString *)reportBody withReportType:(ReportType)reportType;
- (void) sendHelloMessage:(NSString *)helloBody;
- (BOOL) connectedToNetService;

// NetServiceControllerDelegateMethods
- (BOOL) doesNeedToDiscover;
- (void) setDiscoveryMode:(BOOL)mode;
- (void) discoverNextNetServiceFromList:(NSArray *)serviceList usingController:(NetServiceController *)netServiceController;

@property (nonatomic, retain) ResponseContext *responseContext;
@property (assign) BOOL runOnlyAutomatic;
@property (nonatomic, readonly) NSString *deviceName;

@end
